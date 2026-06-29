import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:smart_canvas/core/cache/cache_helper.dart';
import 'package:smart_canvas/core/di/dependancy_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'qr_scanner_state.dart';

class QrScannerCubit extends Cubit<QrScannerState> {
  QrScannerCubit() : super(QrScannerInitial());

  final supabase = getIt<SupabaseClient>();
  final _networkInfo = NetworkInfo();
  final _deviceInfo = DeviceInfoPlugin();

  Future<void> processScannedToken(String token) async {
    try {
      emit(QrScannerLoading());

      // 1. Network Check (Wi-Fi only + Optional SSID)
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
        throw "Please connect to University Wi-Fi to register attendance.";
      }
      
      // Verification: Check for specific University SSID
      final locationStatus = await Geolocator.checkPermission();
      if (locationStatus == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      var wifiName = await _networkInfo.getWifiName();
      wifiName = wifiName?.replaceAll('"', '');
      log("Detected WiFi SSID: $wifiName");
      
      final requiredSSID = dotenv.env['UNIVERSITY_WIFI_SSID'] ?? 'University';
      if (wifiName == null || !wifiName.contains(requiredSSID)) {
         throw "Security Error: You must be connected to the official University network ($requiredSSID).";
      }

      // 2. Device Fingerprint Check
      String? deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
      
      final user = getIt<CacheHelper>().getUserModel();
      if (user == null) throw "User not logged in";

      // Verify or Register Device ID
      final userData = await supabase.from('users').select('device_id').eq('id', user.id).single();
      final storedDeviceId = userData['device_id'];
      
      if (storedDeviceId == null) {
        // Register this device as the student's primary device
        await supabase.from('users').update({'device_id': deviceId}).eq('id', user.id);
      } else if (storedDeviceId != deviceId) {
        throw "Security Error: You can only record attendance from your registered device.";
      }

      // 3. Find Active Session by Token (Manual Join)
      String parsedToken = token;
      try {
        final decoded = jsonDecode(token);
        if (decoded is Map && decoded.containsKey('token')) {
          parsedToken = decoded['token'].toString();
        }
      } catch (e) {
        log("Scanned token is not JSON: $e");
      }

      final session = await supabase
          .from('attendance_sessions')
          .select('id, subject_id, pin_code, week_number')
          .eq('session_token', parsedToken)
          .eq('is_active', true)
          .maybeSingle();

      if (session == null) {
        throw "Invalid or expired QR code. Please scan the current code on professor's screen.";
      }

      // 4. Check if PIN verification is needed
      final requiredPin = session['pin_code'];
      if (requiredPin != null && requiredPin.toString().isNotEmpty) {
        emit(QrScannerAwaitingPIN(token: parsedToken, sessionId: session['id'], subjectId: session['subject_id']));
        return;
      }

      // 5. Success - Mark Attendance
      // Helper to fetch subject name manually since we can't join
      final subjectResponse = await supabase
          .from('subjects')
          .select('name')
          .eq('id', session['subject_id'])
          .single();
      final subjectName = subjectResponse['name'] ?? 'Unknown Subject';

      final weekNumber = session['week_number'] as int? ?? 0;
      await _markAttendance(session['id'], session['subject_id'], deviceId, subjectName, weekNumber);

    } catch (e) {
      emit(QrScannerError(message: e.toString()));
    }
  }

  Future<void> verifyPinAndMark(String pin, String sessionId, String subjectId) async {
    try {
      emit(QrScannerLoading());
      
      // 1. Fetch Session (Manual Join)
      final session = await supabase
          .from('attendance_sessions')
          .select('pin_code, week_number, subject_id')
          .eq('id', sessionId)
          .single();
      
      if (session['pin_code'] != pin) {
        throw "Incorrect PIN. Please check the code on doctor's screen.";
      }

      // 2. Fetch Subject Name manually
      final subjectResponse = await supabase
          .from('subjects')
          .select('name')
          .eq('id', subjectId)
          .single();
      final subjectName = subjectResponse['name'] ?? 'Unknown Subject';

      // 3. Get device ID check
      String? deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }

      final weekNumber = session['week_number'] as int? ?? 0;
      await _markAttendance(sessionId, subjectId, deviceId, subjectName, weekNumber);
    } catch (e) {
      emit(QrScannerError(message: e.toString()));
    }
  }

  Future<void> _markAttendance(String sessionId, String subjectId, String? deviceId, String subjectName, int weekNumber) async {
    final user = getIt<CacheHelper>().getUserModel()!;
    final now = DateTime.now();
    
    // Check duplicate for this session (same student)
    final existing = await supabase
        .from('attendance_records')
        .select()
        .eq('session_id', sessionId)
        .eq('student_id', user.id)
        .maybeSingle();

    if (existing != null) {
      emit(QrScannerSuccess(message: "Attendance already recorded for this session."));
      return;
    }

    // Security: Check if same device already recorded attendance for this subject in the same week (different account)
    if (deviceId != null) {
      final deviceDuplicate = await supabase
          .from('attendance_records')
          .select()
          .eq('subject_id', subjectId)
          .eq('week_number', weekNumber)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (deviceDuplicate != null && deviceDuplicate['student_id'] != user.id) {
        throw "Security Error: This device has already been used to record attendance for another student for this subject in Week $weekNumber.";
      }
    }

    // weekNumber comes from the professor's session

    await supabase.from('attendance_records').insert({
      'session_id': sessionId,
      'subject_id': subjectId,
      'student_id': user.id,
      'student_name': user.fullName,
      'college_id': user.collegeId,
      'device_id': deviceId,
      'week_number': weekNumber,
      'scanned_at': now.toIso8601String(),
    });

    // Format success message with subject name, date, and week number
    final dateFormatted = DateFormat('yyyy-MM-dd (EEEE)').format(now);

    emit(QrScannerSuccess(
      message: "Attendance recorded successfully! ✅\n"
          "📚 Subject: $subjectName\n"
          "📅 Date: $dateFormatted\n"
          "📆 Week: $weekNumber",
    ));
  }
}

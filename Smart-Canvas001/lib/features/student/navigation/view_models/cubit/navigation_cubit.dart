import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:meta/meta.dart';
import 'package:smart_canvas/core/services/navigation_service.dart';
import 'package:smart_canvas/core/services/text_to_speech_service.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  final NavigationService _navService;
  final TextToSpeechService _ttsService;
  StreamSubscription<Position>? _positionSub;
  GenerativeModel? _model;
  
  DateTime? _lastInstructionTime;
  bool _isNavigating = false;
  bool isMuted = false;
  bool _hasSpokenArrival = false;
  
  String _localeCode = 'en';
  
  // Configuration
  final String _systemPrompt = """
You are a Smart Campus Voice Navigation Assistant.
Your goal is to guide the user to their destination using short, clear, and calm voice commands.
Input provided: Language preference, User Location (Lat/Lng), Destination name, Distance, User Floor, and Destination Floor.

Rules:
1. Act as a precise campus GPS.
2. If Language is 'ar', you MUST output voice instructions ONLY in Arabic.
3. If Language is 'en', you MUST output voice instructions ONLY in English.
4. If the destination has a floor number (e.g. Destination Floor: 2) and user is close (< 20 meters), you MUST instruct the user to take the stairs or elevator to that specific floor in the requested language (e.g. in Arabic: "وصلت للمبنى، يرجى التوجه للدور الثاني" or in English: "Arrived at the building, please proceed to the 2nd floor").
5. Keep instructions under 10-15 words. Do not output anything other than the navigation instruction.
""";

  NavigationCubit({
    required NavigationService navService,
    required TextToSpeechService ttsService,
  })  : _navService = navService,
        _ttsService = ttsService,
        super(NavigationInitial()) {
    _initAI();
  }

  void _initAI() {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey != null) {
      _model = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );
    }
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      _ttsService.stop();
    }
    if (state is NavigationActive) {
      final active = state as NavigationActive;
      emit(NavigationActive(instruction: active.instruction, isSpeaking: active.isSpeaking));
    }
  }

  void startNavigation({required String destinationName, required double destLat, required double destLng, int? destFloor, String localeCode = 'en'}) async {
    if (_isNavigating) return;
    
    bool hasPermission = await _navService.checkPermission();
    if (!hasPermission) {
      emit(NavigationError("Location permission denied"));
      return;
    }

    _isNavigating = true;
    _localeCode = localeCode;
    _hasSpokenArrival = false;
    _navService.startNavigation();
    
    final startingText = _localeCode == 'ar'
        ? "جاري بدء الملاحة إلى $destinationName"
        : "Starting navigation to $destinationName";
        
    emit(NavigationActive(instruction: startingText));
    if (!isMuted) {
      await _ttsService.speak(startingText);
    }

    _positionSub = _navService.positionStream.listen((position) {
      _processLocationUpdate(position, destinationName, destLat, destLng, destFloor);
    });
  }

  void stopNavigation() {
    _isNavigating = false;
    _hasSpokenArrival = false;
    _navService.stopNavigation();
    _positionSub?.cancel();
    _ttsService.stop();
    emit(NavigationInitial());
  }

  Future<void> _processLocationUpdate(Position position, String destName, double destLat, double destLng, int? destFloor) async {
    // 1. Calculate distance locally
    final distance = Geolocator.distanceBetween(position.latitude, position.longitude, destLat, destLng);
    
    // 2. Local Arrival Trigger (within 20 meters)
    if (distance < 20) {
      if (!_hasSpokenArrival) {
        _hasSpokenArrival = true;
        
        String arrivalText = "";
        if (_localeCode == 'ar') {
          if (destFloor != null) {
            arrivalText = "لقد وصلت إلى $destName. يرجى التوجه إلى ${_getFloorOrdinalArabic(destFloor)}.";
          } else {
            arrivalText = "لقد وصلت إلى $destName.";
          }
        } else {
          if (destFloor != null) {
            arrivalText = "You have arrived at $destName. Please proceed to the ${_getFloorOrdinal(destFloor)} floor.";
          } else {
            arrivalText = "You have arrived at $destName.";
          }
        }
        
        emit(NavigationActive(instruction: arrivalText, isSpeaking: true));
        if (!isMuted) {
          await _ttsService.speak(arrivalText);
        }
        
        // Reset speaking state after a short delay
        Future.delayed(const Duration(seconds: 6), () {
          if (!isClosed && state is NavigationActive) {
            emit(NavigationActive(instruction: arrivalText, isSpeaking: false));
          }
        });
      }
      return; // Do not call the AI once arrived
    }

    // Reset arrival flag if user moves away (re-entry allowed)
    if (distance > 30) {
      _hasSpokenArrival = false;
    }

    // Throttle AI calls: Only call every 15 seconds
    if (_lastInstructionTime != null && DateTime.now().difference(_lastInstructionTime!) < const Duration(seconds: 15)) {
      return;
    }

    // Determine context
    String context = "Language: $_localeCode. " + _navService.generateContext(
      position, 
      destName, 
      destLat, 
      destLng, 
      0, // Assuming ground floor for user for now (mock)
      destFloor
    );

    try {
      if (_model != null) {
        final content = [Content.text(context)];
        final response = await _model!.generateContent(content);
        
        String? instruction = response.text;
        if (instruction != null && instruction.isNotEmpty) {
          emit(NavigationActive(instruction: instruction, isSpeaking: true));
          if (!isMuted) {
            await _ttsService.speak(instruction);
          }
          _lastInstructionTime = DateTime.now();
          // Reset speaking state after a delay (approximate duration)
          Future.delayed(const Duration(seconds: 5), () {
             if (!isClosed && state is NavigationActive) {
                emit(NavigationActive(instruction: instruction, isSpeaking: false));
             }
          });
        }
      }
    } catch (e) {
      // Silent error, don't interrupt navigation flow
      print("Navigation AI Error: $e");
    }
  }

  String _getFloorOrdinal(int floor) {
    if (floor == 0) return 'ground';
    if (floor == 1) return 'first';
    if (floor == 2) return 'second';
    if (floor == 3) return 'third';
    if (floor == -1) return 'basement';
    return '${floor}th';
  }

  String _getFloorOrdinalArabic(int floor) {
    if (floor == 0) return 'الدور الأرضي';
    if (floor == 1) return 'الدور الأول';
    if (floor == 2) return 'الدور الثاني';
    if (floor == 3) return 'الدور الثالث';
    if (floor == -1) return 'البدروم';
    return 'الدور $floor';
  }

  @override
  Future<void> close() {
    stopNavigation();
    return super.close();
  }
}

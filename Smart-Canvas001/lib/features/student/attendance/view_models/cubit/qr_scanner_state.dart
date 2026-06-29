part of 'qr_scanner_cubit.dart';

abstract class QrScannerState {}

class QrScannerInitial extends QrScannerState {}

class QrScannerLoading extends QrScannerState {}

class QrScannerAwaitingPIN extends QrScannerState {
  final String token;
  final String sessionId;
  final String subjectId;

  QrScannerAwaitingPIN({
    required this.token,
    required this.sessionId,
    required this.subjectId,
  });
}

class QrScannerSuccess extends QrScannerState {
  final String message;
  QrScannerSuccess({required this.message});
}

class QrScannerError extends QrScannerState {
  final String message;
  QrScannerError({required this.message});
}

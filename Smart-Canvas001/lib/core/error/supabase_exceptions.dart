class SupabaseExceptions implements Exception {
  final String errorMessage;

  SupabaseExceptions({required this.errorMessage});
  @override
  String toString() {
    return errorMessage;
  }
}

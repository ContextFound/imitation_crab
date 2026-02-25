/// Thrown when an API request fails.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.hint,
  });

  final int statusCode;
  final String message;
  final String? code;
  final String? hint;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

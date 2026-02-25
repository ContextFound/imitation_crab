import 'package:flutter/foundation.dart';

/// Holds request and response data for a single API call.
class ApiCallRecord {
  const ApiCallRecord({
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    required this.responseStatus,
    this.responseHeaders,
    this.responseBody,
    this.error,
  });

  final String method;
  final String url;
  final Map<String, dynamic> requestHeaders;
  final dynamic requestBody;
  final int? responseStatus;
  final Map<String, List<String>>? responseHeaders;
  final dynamic responseBody;
  final String? error;

  bool get isError => error != null;
}

class ApiDebugNotifier extends ChangeNotifier {
  ApiCallRecord? _latest;

  ApiCallRecord? get latest => _latest;

  void record(ApiCallRecord record) {
    _latest = record;
    notifyListeners();
  }
}

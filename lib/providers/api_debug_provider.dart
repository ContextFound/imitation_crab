import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/debug/api_debug.dart';

final apiDebugNotifierProvider = Provider<ApiDebugNotifier>((ref) {
  return ApiDebugNotifier();
});

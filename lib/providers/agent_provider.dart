import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

final agentProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, name) async {
  final api = ref.watch(moltbookApiProvider);
  return api.getAgentProfile(name);
});

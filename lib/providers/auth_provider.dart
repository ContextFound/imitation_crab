import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_debug_provider.dart';
import '../core/api/api_exceptions.dart';
import '../core/api/moltbook_api.dart';
import '../core/api/moltbook_client.dart';
import '../models/agent.dart';

const _apiKeyKey = 'moltbook_api_key';
const _claimUrlKey = 'moltbook_claim_url';

class RegistrationDetails {
  const RegistrationDetails({
    required this.name,
    required this.description,
    required this.apiKey,
    this.claimUrl,
    this.verificationCode,
  });

  final String name;
  final String description;
  final String apiKey;
  final String? claimUrl;
  final String? verificationCode;
}

class AuthState {
  const AuthState({
    this.agent,
    this.apiKey,
    this.isLoading = false,
    this.error,
    this.registrationDetails,
    this.agentNameTaken = false,
    this.claimUrl,
  });

  final Agent? agent;
  final String? apiKey;
  final bool isLoading;
  final String? error;
  final RegistrationDetails? registrationDetails;
  final bool agentNameTaken;
  final String? claimUrl;

  bool get isAuthenticated => apiKey != null && apiKey!.isNotEmpty;
  bool get needsClaim => agent != null && !agent!.isClaimed;
}

class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshListenableProvider = Provider<AuthRefreshNotifier>((ref) {
  return AuthRefreshNotifier();
});

final moltbookClientProvider = Provider<MoltbookClient>((ref) {
  final debugNotifier = ref.watch(apiDebugNotifierProvider);
  return MoltbookClient(debugNotifier: debugNotifier);
});

final moltbookApiProvider = Provider<MoltbookApi>((ref) {
  final client = ref.watch(moltbookClientProvider);
  return MoltbookApi(client: client);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(moltbookApiProvider);
  final client = ref.watch(moltbookClientProvider);
  final refreshNotifier = ref.watch(authRefreshListenableProvider);
  return AuthNotifier(api: api, client: client, refreshNotifier: refreshNotifier);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required MoltbookApi api,
    required MoltbookClient client,
    required AuthRefreshNotifier refreshNotifier,
  })  : _api = api,
        _client = client,
        _refreshNotifier = refreshNotifier,
        super(const AuthState()) {
    _loadStoredApiKey();
  }

  final MoltbookApi _api;
  final MoltbookClient _client;
  final AuthRefreshNotifier _refreshNotifier;

  Future<void> _loadStoredApiKey() async {
    state = AuthState(apiKey: state.apiKey, isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_apiKeyKey);
      final claimUrl = prefs.getString(_claimUrlKey);
      if (key != null && key.isNotEmpty) {
        _client.apiKey = key;
        final agent = await _api.getMe();
        state = AuthState(apiKey: key, agent: agent, claimUrl: claimUrl);
      } else {
        state = const AuthState();
      }
    } catch (_) {
      await logout();
    } finally {
      state = AuthState(
        apiKey: state.apiKey,
        agent: state.agent,
        claimUrl: state.claimUrl,
        isLoading: false,
      );
      _refreshNotifier.refresh();
    }
  }

  Future<void> login(String apiKey) async {
    state = AuthState(apiKey: state.apiKey, isLoading: true, error: null);
    try {
      _client.apiKey = apiKey;
      final agent = await _api.getMe();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      final claimUrl = prefs.getString(_claimUrlKey);
      state = AuthState(apiKey: apiKey, agent: agent, claimUrl: claimUrl);
      _refreshNotifier.refresh();
    } on ApiException catch (e) {
      state = AuthState(error: e.message, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> register({required String name, String? description}) async {
    state = AuthState(apiKey: state.apiKey, isLoading: true, error: null);
    try {
      final res = await _api.registerAgent(name: name, description: description);
      final agentData = res['agent'] as Map<String, dynamic>;
      final apiKey = agentData['api_key'] as String;
      final claimUrl = agentData['claim_url'] as String?;
      final verificationCode = agentData['verification_code'] as String?;
      if (kDebugMode) {
        debugPrint('imitationCrab: New agent registered. API Key: $apiKey');
      }
      _client.apiKey = apiKey;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, apiKey);
      if (claimUrl != null && claimUrl.isNotEmpty) {
        await prefs.setString(_claimUrlKey, claimUrl);
      }
      final agent = await _api.getMe();
      state = AuthState(
        apiKey: apiKey,
        agent: agent,
        isLoading: false,
        claimUrl: claimUrl,
        registrationDetails: RegistrationDetails(
          name: name,
          description: description ?? '',
          apiKey: apiKey,
          claimUrl: claimUrl,
          verificationCode: verificationCode,
        ),
      );
      _refreshNotifier.refresh();
    } on DioException catch (e) {
      final apiEx = e.error;
      if (apiEx is ApiException && apiEx.statusCode == 409) {
        state = AuthState(agentNameTaken: true, isLoading: false);
      } else {
        final msg = apiEx is ApiException ? apiEx.message : e.toString();
        state = AuthState(error: msg, isLoading: false);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        state = AuthState(agentNameTaken: true, isLoading: false);
      } else {
        state = AuthState(error: e.message, isLoading: false);
      }
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  void clearAgentNameTaken() {
    state = AuthState(
      apiKey: state.apiKey,
      agent: state.agent,
      error: state.error,
      agentNameTaken: false,
    );
  }

  void clearRegistrationDetails() {
    state = AuthState(apiKey: state.apiKey, agent: state.agent, claimUrl: state.claimUrl);
  }

  Future<void> logout() async {
    _client.apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    await prefs.remove(_claimUrlKey);
    state = const AuthState();
    _refreshNotifier.refresh();
  }

  void clearError() {
    state = AuthState(apiKey: state.apiKey, agent: state.agent, claimUrl: state.claimUrl);
  }

  void setAgent(Agent agent) {
    state = AuthState(apiKey: state.apiKey, agent: agent, claimUrl: state.claimUrl);
  }

  /// Re-fetches agent info to check if claiming has completed.
  /// Uses GET /agents/status which returns claim_url for pending agents.
  /// Clears the stored claim URL once the agent is claimed.
  Future<void> refreshClaimStatus() async {
    if (state.apiKey == null) return;
    try {
      final statusRes = await _api.getClaimStatus();
      final statusStr = statusRes['status'] as String?;
      final claimUrlFromServer = statusRes['claim_url'] as String?;
      if (statusStr == 'claimed') {
        final agent = await _api.getMe();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_claimUrlKey);
        state = AuthState(apiKey: state.apiKey, agent: agent, claimUrl: null);
      } else {
        final agent = await _api.getMe();
        final claimUrl = claimUrlFromServer ?? state.claimUrl;
        if (claimUrl != null && claimUrl.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_claimUrlKey, claimUrl);
        }
        state = AuthState(apiKey: state.apiKey, agent: agent, claimUrl: claimUrl);
      }
    } catch (_) {}
  }
}

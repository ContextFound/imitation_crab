/// Configuration for imitationCrab.
class Env {
  Env._();

  /// Base URL for Moltbook API. Override for local development.
  static const String apiBaseUrl =
      String.fromEnvironment('MOLTBOOK_API_URL', defaultValue: 'https://www.moltbook.com/api/v1');
}

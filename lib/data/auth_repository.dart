import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  Future<bool> hasSession() async => (await _tokens.read()) != null;

  Future<void> login(String email, String password) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    await _tokens.write(data['access_token'] as String);
  }

  Future<void> register(String email, String password) => _api.post(
        '/auth/register',
        body: {'email': email.trim(), 'password': password},
        auth: false,
      );

  Future<void> logout() => _tokens.clear();
}

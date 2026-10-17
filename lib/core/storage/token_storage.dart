import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'token';

  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(_key);

  Future<void> write(String token) async =>
      (await SharedPreferences.getInstance()).setString(_key, token);

  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);
}

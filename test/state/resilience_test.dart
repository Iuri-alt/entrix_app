import 'package:entrix/core/network/api_client.dart';
import 'package:entrix/core/storage/token_storage.dart';
import 'package:entrix/data/auth_repository.dart';
import 'package:entrix/data/finance_repository.dart';
import 'package:entrix/state/finance_store.dart';
import 'package:entrix/state/session_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simula o plugin de armazenamento quebrado no release (NoSuchMethodError via JNI).
class _BrokenStorage implements TokenStorage {
  @override
  Future<String?> read() => throw PlatformException(code: 'NoSuchMethodError');
  @override
  Future<void> write(String token) => throw PlatformException(code: 'NoSuchMethodError');
  @override
  Future<void> clear() => throw PlatformException(code: 'NoSuchMethodError');
}

class _MemoryStorage implements TokenStorage {
  @override
  Future<String?> read() async => 'token';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  test('falha ao ler a sessão salva leva ao login em vez de travar no splash', () async {
    final storage = _BrokenStorage();
    final api = ApiClient(baseUrl: 'http://x', tokens: storage, httpClient: MockClient((_) async => http.Response('', 500)));
    final session = SessionController(AuthRepository(api, storage));

    await session.restore();

    expect(session.status, SessionStatus.signedOut);
  });

  test('erro inesperado no carregamento vira estado de erro, não carregamento infinito', () async {
    SharedPreferences.setMockInitialValues({'token': 't'});
    final api = ApiClient(
      baseUrl: 'http://x',
      tokens: _MemoryStorage(),
      httpClient: MockClient((_) async => http.Response('<html>não é json</html>', 200)),
    );
    final store = FinanceStore(FinanceRepository(api));

    await store.load();

    expect(store.status, LoadStatus.error);
    expect(store.error, isNotEmpty);
  });
}

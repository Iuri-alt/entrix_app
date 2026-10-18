import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

enum SessionStatus { unknown, signedOut, signedIn }

class SessionController extends ChangeNotifier {
  SessionController(this._auth);

  final AuthRepository _auth;
  SessionStatus _status = SessionStatus.unknown;
  bool _expired = false;

  SessionStatus get status => _status;

  /// Verdadeiro quando a saída foi causada por token expirado (mostra aviso no login).
  bool get expired => _expired;

  Future<void> restore() async {
    bool hasSession;
    try {
      hasSession = await _auth.hasSession();
    } catch (e) {
      // Armazenamento local indisponível: pede login em vez de travar no splash.
      debugPrint('Falha ao ler a sessão salva: $e');
      hasSession = false;
    }
    _set(hasSession ? SessionStatus.signedIn : SessionStatus.signedOut);
  }

  Future<void> login(String email, String password) async {
    await _auth.login(email, password);
    _expired = false;
    _set(SessionStatus.signedIn);
  }

  Future<void> register(String email, String password) => _auth.register(email, password);

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (e) {
      debugPrint('Falha ao apagar a sessão salva: $e');
    }
    _set(SessionStatus.signedOut);
  }

  Future<void> expire() async {
    if (_status != SessionStatus.signedIn) return;
    _expired = true;
    await logout();
  }

  void _set(SessionStatus value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }
}

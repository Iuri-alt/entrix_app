import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../data/finance_repository.dart';
import '../state/finance_store.dart';
import '../state/session_controller.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/home/home_shell.dart';
import '../ui/screens/splash_screen.dart';
import 'app_scope.dart';
import 'theme.dart';

class EntrixApp extends StatefulWidget {
  const EntrixApp({super.key, required this.session, required this.store});

  /// Monta as dependências reais (API no Render).
  factory EntrixApp.create() {
    final tokens = TokenStorage();
    final api = ApiClient(baseUrl: ApiClient.defaultBaseUrl, tokens: tokens);
    final session = SessionController(AuthRepository(api, tokens));
    api.onUnauthorized = session.expire;
    return EntrixApp(session: session, store: FinanceStore(FinanceRepository(api)));
  }

  final SessionController session;
  final FinanceStore store;

  @override
  State<EntrixApp> createState() => _EntrixAppState();
}

class _EntrixAppState extends State<EntrixApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    widget.session.restore();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (widget.session.status == SessionStatus.signedIn) {
      widget.store.load();
    } else {
      // Fecha formulários e diálogos abertos antes de voltar ao login.
      _navigator.currentState?.popUntil((route) => route.isFirst);
      widget.store.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: widget.session,
      store: widget.store,
      child: MaterialApp(
        navigatorKey: _navigator,
        title: 'Entrix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ListenableBuilder(
          listenable: widget.session,
          builder: (context, _) => switch (widget.session.status) {
            SessionStatus.unknown => const SplashScreen(),
            SessionStatus.signedOut => const LoginScreen(),
            SessionStatus.signedIn => const HomeShell(),
          },
        ),
      ),
    );
  }
}

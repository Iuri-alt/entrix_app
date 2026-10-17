import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../widgets/feedback.dart';
import 'auth_layout.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.session.expired) {
        showMessage(context, 'Sua sessão expirou. Entre novamente.');
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await runWithFeedback(context, () => context.session.login(_email.text, _password.text));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openRegister() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (email != null) _email.text = email;
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      subtitle: 'Controle financeiro e planejador de compras',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                label: 'Senha',
                validator: validatePassword,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              BusyButton(busy: _busy, label: 'Entrar', onPressed: _submit),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _openRegister,
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

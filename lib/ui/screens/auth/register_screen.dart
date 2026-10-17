import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../widgets/feedback.dart';
import 'auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await runWithFeedback(
      context,
      () => context.session.register(_email.text, _password.text),
      success: 'Conta criada! Entre com seu email e senha.',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      subtitle: 'Crie sua conta',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            PasswordField(controller: _password, label: 'Senha', validator: validatePassword),
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirm,
              label: 'Confirmar senha',
              validator: (v) => v != _password.text ? 'As senhas não coincidem' : null,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            BusyButton(busy: _busy, label: 'Cadastrar', onPressed: _submit),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('Já tenho conta'),
            ),
          ],
        ),
      ),
    );
  }
}

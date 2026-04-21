import 'package:entrix/api/api_service.dart';
import 'package:entrix/screens/login_screen.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();

  bool obscureSenha = true;
  bool obscureConfirmar = true;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    final success = await ApiService.register(
      emailController.text,
      senhaController.text,
    );

    try {
      await ApiService.register(
        emailController.text,
        senhaController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B3D),
              Color(0xFF1B2A49),
            ],
            begin: Alignment.topCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.white.withOpacity(0.1),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'lib/assets/logo.png',
                          height: 100,
                        ),
                        const SizedBox(height: 20),

                        // EMAIL
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu email';
                            }
                            if (!value.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.email, color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF0D1B3D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SENHA
                        TextFormField(
                          controller: senhaController,
                          obscureText: obscureSenha,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureSenha
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureSenha = !obscureSenha;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D1B3D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CONFIRMAR SENHA
                        TextFormField(
                          controller: confirmarSenhaController,
                          obscureText: obscureConfirmar,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value != senhaController.text) {
                              return 'Senhas não coincidem';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmar
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmar = !obscureConfirmar;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D1B3D),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // BOTÃO CADASTRAR
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await handleRegister();
                              }
                            },
                            child: const Text('Cadastrar'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // BOTÃO VOLTAR
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DB954),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Voltar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

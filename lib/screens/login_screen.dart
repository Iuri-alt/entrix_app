import 'package:entrix/api/api_service.dart';
import 'package:entrix/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:entrix/screens/register_screen.dart';
import 'package:entrix/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  // Controllers capturam o que o usuário digita
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final data = await ApiService.login(
      emailController.text,
      senhaController.text,
    );

    if (data != null) {
      await AuthService.saveToken(data['access_token']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login inválido')),
      );
    }
  }
  @override //UI da Login Screen
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1B3D),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: <Color>[
              Color(0xFF0D1B3D),
              Color(0xFF1B2A49),
            ],
              begin: Alignment.topCenter,
            )
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: Colors.white.withOpacity(0.1),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🖼️ LOGO
                      Image.asset(
                        'lib/assets/logo.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      //Email
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.email, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      //Senha
                      TextField(
                        controller: senhaController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: TextStyle(color: Colors.white),
                          prefixIcon: Icon(Icons.lock, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 🔘 BOTÃO
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1DB954), // verde Entrix
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async{
                            final data = await ApiService.login(
                              emailController.text,
                              senhaController.text,
                            );
                            if (data != null) {
                              await AuthService.saveToken(data['access_token']);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Login inválido')),
                              );
                            }
                          },
                          child: const Text('Entrar'),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 📝 CADASTRO
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1DB954), // verde Entrix
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Cadastre-se'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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

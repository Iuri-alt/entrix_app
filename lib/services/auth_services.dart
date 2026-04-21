import '../models/user_model.dart';

class AuthService {

  Future<bool> register(User user) async {
    // 🔥 Aqui futuramente vai o FastAPI

    print("Enviando dados:");
    print(user.toJson());

    await Future.delayed(const Duration(seconds: 1));

    return true; // simula sucesso
  }
}

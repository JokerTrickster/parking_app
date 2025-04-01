import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;

  String _username = '';
  String _password = '';

  LoginViewModel({required this.loginUseCase});

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  bool login() {
    final user = UserEntity(username: _username, password: _password);
    return loginUseCase.execute(user);
  }
}

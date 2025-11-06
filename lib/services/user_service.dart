// user_service.dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserService with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<User> getCurrentUser() async {
    // Здесь должна быть логика получения пользователя из хранилища (например, SharedPreferences)
    // Пока возвращаем _currentUser, если он есть, или пустого пользователя.
    return _currentUser ?? User(id: 0, email: '', name: '');
  }

  Future<void> updateUser(User updatedUser) async {
    _currentUser = updatedUser;
    notifyListeners();
    // Здесь должна быть логика сохранения в хранилище
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }
}
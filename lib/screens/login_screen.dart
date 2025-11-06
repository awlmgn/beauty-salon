import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Валидация email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!value.contains('@')) {
      return 'Email должен содержать @';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  // Валидация пароля
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен быть не менее 6 символов';
    }
    return null;
  }

  // Сохраняем данные пользователя
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['id'] ?? 0);
    await prefs.setString('user_name', userData['name'] ?? 'Пользователь');
    await prefs.setString('user_email', userData['email'] ?? '');
    print('✅ Данные пользователя сохранены: ${userData['name']}');
  }

  void _login() async {
    // Проверяем валидность формы
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(_emailController.text, _passwordController.text);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (result['user'] != null) {
          await _saveUserData(result['user']);
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ошибка входа'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сети: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.purple.shade50],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Логотип и заголовок
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.shade100,
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.spa,
                          size: 60,
                          color: Colors.pink,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Добро пожаловать',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.pink.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Войдите в свой аккаунт',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 40),

                      // Поле email с валидацией
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.pink),
                          hintText: 'your@email.com',
                          errorMaxLines: 2,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: 20),

                      // Поле пароля с валидацией
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock, color: Colors.pink),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          helperText: 'Минимум 6 символов',
                          errorMaxLines: 2,
                        ),
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: 30),

                      // Кнопка входа
                      if (_isLoading)
                        CircularProgressIndicator(color: Colors.pink)
                      else
                        ElevatedButton(
                          onPressed: _login,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text('Войти'),
                          ),
                        ),
                      SizedBox(height: 20),

                      // Ссылка на регистрацию
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Нет аккаунта?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Зарегистрируйтесь',
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
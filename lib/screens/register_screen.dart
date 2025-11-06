import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Валидация имени
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите имя';
    }
    if (value.length < 2) {
      return 'Имя должно быть не менее 2 символов';
    }
    if (value.length > 50) {
      return 'Имя слишком длинное';
    }
    return null;
  }

  // Валидация email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пожалуйста, введите email';
    }
    if (!value.contains('@')) {
      return 'Email должен содержать @';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Введите корректный email (например: user@example.com)';
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
    if (value.length > 20) {
      return 'Пароль слишком длинный';
    }
    // Дополнительная проверка на сложность пароля
    if (!RegExp(r'^(?=.*[a-zA-Z]).{6,}$').hasMatch(value)) {
      return 'Пароль должен содержать буквы';
    }
    return null;
  }

  void _register() async {
    // Проверяем валидность формы
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Регистрация успешна! Теперь войдите.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ошибка регистрации'),
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
      appBar: AppBar(
        title: Text('Регистрация'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.pink,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.pink.shade50],
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
                      SizedBox(height: 20),
                      Text(
                        'Создать аккаунт',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.purple.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Заполните данные для регистрации',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 40),

                      // Поле имени с валидацией
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person, color: Colors.purple),
                          helperText: 'Минимум 2 символа',
                          errorMaxLines: 2,
                        ),
                        validator: _validateName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        textCapitalization: TextCapitalization.words,
                      ),
                      SizedBox(height: 20),

                      // Поле email с валидацией
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.purple),
                          hintText: 'your@example.com',
                          helperText: 'Должен содержать @ и домен',
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
                          prefixIcon: Icon(Icons.lock, color: Colors.purple),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          helperText: '6-20 символов, должен содержать буквы',
                          errorMaxLines: 2,
                        ),
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: 30),

                      // Индикатор сложности пароля
                      _buildPasswordStrength(),
                      SizedBox(height: 20),

                      // Кнопка регистрации
                      if (_isLoading)
                        CircularProgressIndicator(color: Colors.purple)
                      else
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text('Зарегистрироваться'),
                          ),
                        ),
                      SizedBox(height: 20),

                      // Ссылка на вход
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Уже есть аккаунт?'),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text(
                              'Войдите',
                              style: TextStyle(
                                color: Colors.purple,
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

  // Виджет для отображения сложности пароля
  Widget _buildPasswordStrength() {
    if (_passwordController.text.isEmpty) {
      return SizedBox.shrink();
    }

    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    String text;
    Color color;

    switch (strength) {
      case 0:
      case 1:
        text = 'Слабый пароль';
        color = Colors.red;
        break;
      case 2:
        text = 'Средний пароль';
        color = Colors.orange;
        break;
      case 3:
        text = 'Хороший пароль';
        color = Colors.blue;
        break;
      default:
        text = 'Отличный пароль!';
        color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сложность пароля: $text',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 5,
          backgroundColor: Colors.grey.shade300,
          color: color,
        ),
      ],
    );
  }
}
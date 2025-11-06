import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user; // Добавлен параметр user
  const ProfileScreen({super.key, required this.user}); // Обновлен конструктор

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Контроллеры для смены пароля
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Контроллеры для имени и почты
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late User _currentUser; // Теперь используем переданного пользователя

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user; // Инициализируем переданным пользователем
    _loadUserData();
  }

  void _loadUserData() {
    // Инициализация контроллеров текущими данными пользователя
    _nameController.text = _currentUser.name;
    _emailController.text = _currentUser.email;
  }

  void _logout() {
    ApiService.token = null;
    final userService = Provider.of<UserService>(context, listen: false);
    userService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // НОВЫЙ МЕТОД: Сохранение изменений профиля (Имя и Email)
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus(); // Скрываем клавиатуру

    // 1. Проверка на пустые поля
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Имя и Email обязательны для заполнения'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Проверка, изменились ли данные
    if (_nameController.text == _currentUser.name && _emailController.text == _currentUser.email) {
      setState(() {
        _isEditing = false;
      });
      return; // Данные не изменились, выходим
    }

    try {
      // 3. Отправка запроса на API
      final result = await ApiService.updateProfile(
        _nameController.text,
        _emailController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // 4. Успешное обновление
        final updatedUser = result['user'] as User;
        setState(() {
          _currentUser = updatedUser;
          _isEditing = false;
        });

        // Обновляем в UserService
        final userService = Provider.of<UserService>(context, listen: false);
        await userService.updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Профиль успешно обновлен'), backgroundColor: Colors.green),
        );

        // Возвращаем обновленного пользователя обратно
        Navigator.pop(context, updatedUser);
      } else {
        // 5. Ошибка API
        // Возвращаем контроллеры к предыдущему значению
        _nameController.text = _currentUser.name;
        _emailController.text = _currentUser.email;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Не удалось обновить профиль'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // 6. Ошибка сети/прочая ошибка
      _nameController.text = _currentUser.name;
      _emailController.text = _currentUser.email;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети при сохранении профиля'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Форматируем дату регистрации
    final registrationDate = _currentUser.createdAt != null
        ? '${_currentUser.createdAt!.day.toString().padLeft(2, '0')}.${_currentUser.createdAt!.month.toString().padLeft(2, '0')}.${_currentUser.createdAt!.year}'
        : 'Н/Д';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка 'Редактировать' / 'Сохранить'
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
            tooltip: _isEditing ? 'Сохранить изменения' : 'Редактировать профиль',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар и основная информация
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.pink.shade100,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.pink,
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: () {
                                  // Логика смены аватара
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Редактируемые поля ИМЯ и EMAIL
                    _buildProfileItem('Имя', _currentUser.name, isEditable: _isEditing, controller: _nameController),
                    _buildProfileItem('Email', _currentUser.email, isEditable: _isEditing, controller: _emailController, isEmail: true),

                    Divider(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Записи', '12'),
                        _buildStatItem('Отзывы', '4'),
                        _buildStatItem('Дата рег.', registrationDate),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Кнопка Сменить пароль
            ListTile(
              leading: Icon(Icons.lock, color: Colors.pink),
              title: Text('Сменить пароль'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              onTap: _changePassword,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            ),
            SizedBox(height: 10),

            // Кнопка Выйти
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Выйти'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              onTap: _logout,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для отображения/редактирования поля профиля
  Widget _buildProfileItem(String title, String value, {
    bool isEditable = false,
    TextEditingController? controller,
    bool isEmail = false
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isEditable
                ? TextField(
              controller: controller, // Используем переданный контроллер
              keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            )
                : Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для отображения статистики
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Смена пароля'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Текущий пароль',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Новый пароль',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _confirmPasswordChange,
            child: Text('Сменить'),
          ),
        ],
      ),
    );
  }

  void _confirmPasswordChange() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароли не совпадают'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль должен быть не менее 6 символов'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      // Здесь вызов API для смены пароля
      final result = await ApiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка смены пароля'), backgroundColor: Colors.red),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароль успешно изменен'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
      setState(() {
        _isChangingPassword = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка смены пароля: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
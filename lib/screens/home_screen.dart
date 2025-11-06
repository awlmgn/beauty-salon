import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import 'master_detail_screen.dart';
import '../widgets/search_widget.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'appointments_screen.dart';
import 'reviews_screen.dart';
import 'about_screen.dart';
import 'payment_screen.dart';
import 'payment_success_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Master>> _mastersFuture;
  List<Master> _allMasters = [];
  List<Master> _filteredMasters = [];
  String _searchQuery = '';
  String _selectedSpecialization = 'Все';
  List<String> _specializations = ['Все'];

  User? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _mastersFuture = _loadData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _getUserFromStorage();
      setState(() {
        _currentUser = userData;
        _loadingUser = false;
      });
    } catch (error) {
      print('Ошибка загрузки пользователя: $error');
      setState(() {
        _loadingUser = false;
      });
    }
  }

  Future<User> _getUserFromStorage() async {
    await Future.delayed(Duration(milliseconds: 100));
    return User(id: 1, email: 'guest@example.com', name: 'Гость');
  }

  Future<List<Master>> _loadData() async {
    try {
      final allMasters = await ApiService.getMasters();
      if (!mounted) return [];

      setState(() {
        _allMasters = allMasters;
        _filteredMasters = allMasters;
        _specializations = ['Все', ...allMasters.map((m) => m.specialization).toSet().toList()];
      });
      return allMasters;
    } catch (e) {
      throw Exception('Не удалось загрузить данные: $e');
    }
  }

  // Геттер для безопасного доступа к пользователю
  User get currentUser {
    return _currentUser ?? User(id: 0, email: 'guest@example.com', name: 'Гость');
  }

  Future<void> _toggleFavorite(Master master) async {
    final originalIsFavorite = master.isFavorite;

    setState(() {
      for (var m in _allMasters) {
        if (m.id == master.id) {
          m.isFavorite = !originalIsFavorite;
        }
      }
      for (var m in _filteredMasters) {
        if (m.id == master.id) {
          m.isFavorite = !originalIsFavorite;
        }
      }
    });

    try {
      final result = originalIsFavorite
          ? await ApiService.removeFromFavorites(master.id)
          : await ApiService.addToFavorites(master.id);

      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          for (var m in _allMasters) {
            if (m.id == master.id) {
              m.isFavorite = originalIsFavorite;
            }
          }
          for (var m in _filteredMasters) {
            if (m.id == master.id) {
              m.isFavorite = originalIsFavorite;
            }
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Результат'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        for (var m in _allMasters) {
          if (m.id == master.id) {
            m.isFavorite = originalIsFavorite;
          }
        }
        for (var m in _filteredMasters) {
          if (m.id == master.id) {
            m.isFavorite = originalIsFavorite;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _logout() {
    ApiService.token = null;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onSpecializationChanged(String? specialization) {
    setState(() {
      _selectedSpecialization = specialization ?? 'Все';
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Master> filtered = _allMasters;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((master) =>
      master.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          master.specialization.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedSpecialization != 'Все') {
      filtered = filtered.where((master) =>
      master.specialization == _selectedSpecialization)
          .toList();
    }

    setState(() {
      _filteredMasters = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedSpecialization = 'Все';
      _filteredMasters = _allMasters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Beauty Salon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                final updatedUser = await Navigator.push(  // ЖДЕМ ВОЗВРАТА
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(user: currentUser)),
                );

                if (updatedUser != null) {
                  setState(() {
                    _currentUser = updatedUser; // ОБНОВЛЯЕМ ПОЛЬЗОВАТЕЛЯ
                  });
                }
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.pink,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView( // ДОБАВЛЕНО SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя часть с приветствием
            Container(
              height: 140, // УМЕНЬШЕНА высота
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink, Colors.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final updatedUser = await Navigator.push(  // ЖДЕМ ВОЗВРАТА
                        context,
                        MaterialPageRoute(builder: (context) => ProfileScreen(user: currentUser)),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Добро пожаловать,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          currentUser.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Найдите своего мастера',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Поиск и фильтры
            Container(
              height: 172, // УМЕНЬШЕНА высота
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SearchWidget(onSearchChanged: _onSearchChanged),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSpecialization,
                          decoration: InputDecoration(
                            labelText: 'Специализация',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _specializations.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: _onSpecializationChanged,
                        ),
                      ),
                      SizedBox(width: 12),
                      if (_searchQuery.isNotEmpty || _selectedSpecialization != 'Все')
                        IconButton(
                          onPressed: _clearFilters,
                          icon: Icon(Icons.clear_all, color: Colors.pink),
                          tooltip: 'Сбросить фильтры',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Список мастеров - УБРАН Expanded, добавлена фиксированная высота
            Container(
              height: 600, // Фиксированная высота для списка
              child: FutureBuilder<List<Master>>(
                future: _mastersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.pink),
                          SizedBox(height: 16),
                          Text('Загружаем данные...'),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Ошибка загрузки',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _mastersFuture = _loadData();
                              });
                            },
                            child: Text('Попробовать снова'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || _filteredMasters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Мастера не найдены',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty || _selectedSpecialization != 'Все')
                            Text(
                              'Попробуйте изменить параметры поиска',
                              style: TextStyle(color: Colors.grey),
                            ),
                          SizedBox(height: 16),
                          if (_searchQuery.isNotEmpty || _selectedSpecialization != 'Все')
                            ElevatedButton.icon(
                              onPressed: _clearFilters,
                              icon: Icon(Icons.clear_all),
                              label: Text('Сбросить фильтры'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredMasters.length,
                    itemBuilder: (context, index) {
                      final master = _filteredMasters[index];
                      return _buildMasterCard(master, context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // УПРОЩЕННЫЙ DrawerHeader - только аватар и имя
          Container(
            height: 120, // Уменьшенная высота
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.pink,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    currentUser.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Главная',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Мой профиль',
                  onTap: () async {
                    Navigator.pop(context);
                    final updatedUser = await Navigator.push(  // ЖДЕМ ВОЗВРАТА
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen(user: currentUser)),
                    );

                    if (updatedUser != null) {
                      setState(() {
                        _currentUser = updatedUser; // ОБНОВЛЯЕМ ПОЛЬЗОВАТЕЛЯ
                      });
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  title: 'Избранное',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FavoritesScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'Мои записи',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AppointmentsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.star,
                  title: 'Мои отзывы',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReviewsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  title: 'Оплата услуг',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          amount: 1500.0,
                          serviceType: 'Услуга салона',
                        ),
                      ),
                    );
                  },
                ),
                Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Настройки',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),

                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'О приложении',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Выйти'),
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.pink),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildMasterCard(Master master, BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MasterDetailScreen(master: master),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(master.imageUrl),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: Colors.pink.shade200, width: 2),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          master.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          master.specialization,
                          style: TextStyle(
                            color: Colors.pink.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.work, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${master.experience} лет опыта',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                master.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: master.isFavorite ? Colors.red : Colors.grey.shade400,
              ),
              onPressed: () => _toggleFavorite(master),
              tooltip: master.isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
            ),
          ),
        ],
      ),
    );
  }
}
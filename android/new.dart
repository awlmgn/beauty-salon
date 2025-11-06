import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import 'master_detail_screen.dart';
import '../widgets/search_widget.dart';

// Предполагается, что у вас есть экран FavoritesScreen
// import 'favorites_screen.dart'; 

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

  @override
  void initState() {
    super.initState();
    _mastersFuture = ApiService.getMasters().then((masters) {
      _allMasters = masters;
      _filteredMasters = masters;

      // Получаем уникальные специализации
      _specializations.addAll(
          masters.map((m) => m.specialization).toSet().toList());

      return masters;
    });
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

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((master) =>
      master.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          master.specialization.toLowerCase().contains(
              _searchQuery.toLowerCase()) ||
          master.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Фильтр по специализации
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
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.white),
            onPressed: () {
              // Для этого кода требуется наличие экрана FavoritesScreen
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => FavoritesScreen()),
              // );
            },
            tooltip: 'Избранное',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Наши мастера',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Профессионалы с любовью к своему делу',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Поиск и фильтры
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Поиск
                SearchWidget(onSearchChanged: _onSearchChanged),
                SizedBox(height: 12),

                // Фильтр по специализации
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
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                    // Кнопка сброса фильтров
                    if (_searchQuery.isNotEmpty ||
                        _selectedSpecialization != 'Все')
                      IconButton(
                        onPressed: _clearFilters,
                        icon: Icon(Icons.clear_all, color: Colors.pink),
                        tooltip: 'Сбросить фильтры',
                      ),
                  ],
                ),

                // Информация о результатах
                if (_searchQuery.isNotEmpty || _selectedSpecialization != 'Все')
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Найдено мастеров: ${_filteredMasters.length}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Список мастеров
          Expanded(
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
                          'Мастеры не найдены',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        if (_searchQuery.isNotEmpty ||
                            _selectedSpecialization != 'Все')
                          Text(
                            'Попробуйте изменить параметры поиска',
                            style: TextStyle(color: Colors.grey),
                          ),
                        SizedBox(height: 16),
                        if (_searchQuery.isNotEmpty ||
                            _selectedSpecialization != 'Все')
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
    );
  }

  Widget _buildMasterCard(Master master, BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
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
    );
  }
}

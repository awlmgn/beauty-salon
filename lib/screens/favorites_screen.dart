import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import 'master_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Master>> _favoritesFuture;
  List<Master> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = ApiService.getFavorites();
    });
  }

  void _removeFromFavorites(int masterId) async {
    final result = await ApiService.removeFromFavorites(masterId);

    if (result['success'] == true) {
      // Обновляем список
      _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Мастер удален из избранного'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Ошибка удаления'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Избранное',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
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
              children: [
                Icon(Icons.favorite, size: 50, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Избранные мастера',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ваши любимые специалисты',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Список избранных
          Expanded(
            child: FutureBuilder<List<Master>>(
              future: _favoritesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.pink),
                        SizedBox(height: 16),
                        Text('Загружаем избранное...'),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                          onPressed: _loadFavorites,
                          child: Text('Попробовать снова'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Пока нет избранных мастеров',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Добавляйте мастеров в избранное,\nчтобы они появились здесь',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Вернуться к списку мастеров
                          },
                          child: Text('Найти мастеров'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final favorites = snapshot.data!;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final master = favorites[index];
                    return _buildFavoriteCard(master, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Master master, BuildContext context) {
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
                  // Аватар мастера
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

                  // Информация о мастере
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

                  // Стрелка
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Кнопка удаления из избранного
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFromFavorites(master.id),
              tooltip: 'Удалить из избранного',
            ),
          ),
        ],
      ),
    );
  }
}
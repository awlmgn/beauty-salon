import 'package:flutter/material.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../screens/booking_screen.dart';

class MasterDetailScreen extends StatefulWidget {
  final Master master;

  const MasterDetailScreen({Key? key, required this.master}) : super(key: key);

  @override
  _MasterDetailScreenState createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> {
  // 1. Переменная для отслеживания состояния избранного
  bool _isFavorite = false;
  bool _isLoadingFavoriteStatus = true; // Для индикатора загрузки статуса

  @override
  void initState() {
    super.initState();
    // 2. При запуске экрана проверяем, в избранном ли мастер
    _checkIfFavorite();
  }

  // 3. Метод для проверки статуса "избранное"
  Future<void> _checkIfFavorite() async {
    try {
      final favoriteMasters = await ApiService.getFavorites();
      if (!mounted) return;

      setState(() {
        _isFavorite = favoriteMasters.any((favMaster) => favMaster.id == widget.master.id);
        _isLoadingFavoriteStatus = false;
      });
    } catch (e) {
      print("Ошибка при проверке избранного: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingFavoriteStatus = false;
      });
    }
  }

  // 4. Универсальный метод для добавления/удаления из избранного
  Future<void> _toggleFavorite() async {
    // Оптимистичное обновление UI для мгновенного отклика
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final result = _isFavorite
          ? await ApiService.addToFavorites(widget.master.id)
          : await ApiService.removeFromFavorites(widget.master.id);

      if (!mounted) return;

      // Если запрос не удался, откатываем изменение UI
      if (result['success'] != true) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Неизвестный результат'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Откатываем изменение в случае ошибки сети
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сети при обновлении избранного'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.master.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              // 5. Динамическая иконка
              _isLoadingFavoriteStatus
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
                  : IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                // 6. Вызываем универсальный метод
                onPressed: _toggleFavorite,
                tooltip: _isFavorite ? 'Удалить из избранного' : 'Добавить в избранное',
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // Функция поделиться
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.master.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.master.specialization,
                      style: TextStyle(
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  _buildInfoRow(
                    icon: Icons.work,
                    title: 'Опыт работы',
                    value: '${widget.master.experience} лет',
                  ),
                  SizedBox(height: 16),

                  Text(
                    'О мастере',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.master.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 40),

                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Записаться на прием',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.purple),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(selectedMaster: widget.master),
      ),
    );
  }
}

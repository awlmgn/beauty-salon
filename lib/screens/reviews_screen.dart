// reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/master.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 5;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  int? _selectedMasterId;
  int? _selectedServiceId;
  List<Master> _masters = [];
  List<dynamic> _services = [];
  bool _loadingMasters = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadReviews(),
        _loadMasters(),
        _loadServices(),
      ]);
    } catch (error) {
      print('Ошибка загрузки данных: $error');
      setState(() {
        _isLoading = false;
        _loadingMasters = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ApiService.getReviews();
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (error) {
      print('Ошибка загрузки отзывов: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMasters() async {
    try {
      final masters = await ApiService.getMasters();
      setState(() {
        _masters = masters;
        _loadingMasters = false;
      });
    } catch (error) {
      print('Ошибка загрузки мастеров: $error');
      setState(() {
        _loadingMasters = false;
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      // Загрузка услуг из базы данных
      final services = await _getServicesFromDatabase();
      setState(() {
        _services = services;
      });
    } catch (error) {
      print('Ошибка загрузки услуг: $error');
      // Запасной вариант - базовые услуги
      setState(() {
        _services = [
          {'id': 1, 'name': 'Стрижка'},
          {'id': 2, 'name': 'Окрашивание'},
          {'id': 3, 'name': 'Маникюр'},
          {'id': 4, 'name': 'Педикюр'},
          {'id': 5, 'name': 'Макияж'},
          {'id': 6, 'name': 'Уход за кожей'},
        ];
      });
    }
  }

  Future<List<dynamic>> _getServicesFromDatabase() async {
    // В реальном приложении замените на вызов API
    // return await ApiService.getServices();

    // Заглушка - имитация загрузки из базы
    await Future.delayed(Duration(milliseconds: 500));
    return [
      {'id': 1, 'name': 'Женская стрижка'},
      {'id': 2, 'name': 'Мужская стрижка'},
      {'id': 3, 'name': 'Окрашивание волос'},
      {'id': 4, 'name': 'Мелирование'},
      {'id': 5, 'name': 'Кератиновое выпрямление'},
      {'id': 6, 'name': 'Укладка'},
      {'id': 7, 'name': 'Вечерняя прическа'},
      {'id': 8, 'name': 'Свадебная прическа'},
      {'id': 9, 'name': 'Маникюр'},
      {'id': 10, 'name': 'Педикюр'},
      {'id': 11, 'name': 'Наращивание ногтей'},
      {'id': 12, 'name': 'Дизайн ногтей'},
      {'id': 13, 'name': 'Макияж дневной'},
      {'id': 14, 'name': 'Макияж вечерний'},
      {'id': 15, 'name': 'Свадебный макияж'},
      {'id': 16, 'name': 'Чистка лица'},
      {'id': 17, 'name': 'Уход за кожей'},
      {'id': 18, 'name': 'Массаж лица'},
    ];
  }

  Future<void> _addReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст отзыва')),
      );
      return;
    }

    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите мастера')),
      );
      return;
    }

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите услугу')),
      );
      return;
    }

    try {
      final result = await ApiService.addReview(
        _reviewController.text,
        _rating,
        _selectedMasterId!,
        _selectedServiceId!, // Добавляем ID услуги
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Отзыв добавлен!')),
        );
        _reviewController.clear();
        setState(() {
          _rating = 5;
          _selectedMasterId = null;
          _selectedServiceId = null;
        });
        _loadReviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка добавления отзыва')),
        );
      }
    } catch (error) {
      print('Ошибка добавления отзыва: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления отзыва')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Форма добавления отзыва
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавить отзыв',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Выбор мастера
                    const Text(
                      'Выберите мастера:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _loadingMasters
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Загрузка мастеров...'),
                          ],
                        ),
                      )
                          : DropdownButton<int>(
                        value: _selectedMasterId,
                        hint: const Text('Выберите мастера'),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _masters.map((master) {
                          return DropdownMenuItem<int>(
                            value: master.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  master.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (master.specialization != null)
                                  Text(
                                    master.specialization!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedMasterId = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Выбор услуги
                    const Text(
                      'Выберите услугу:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedServiceId,
                        hint: const Text('Выберите услугу'),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _services.map((service) {
                          return DropdownMenuItem<int>(
                            value: service['id'],
                            child: Text(service['name']),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedServiceId = newValue;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Рейтинг
                    Row(
                      children: [
                        const Text('Оценка:'),
                        const SizedBox(width: 10),
                        ...List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            icon: Icon(
                              Icons.star,
                              color: index < _rating ? Colors.amber : Colors.grey,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Текст отзыва
                    TextField(
                      controller: _reviewController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Ваш отзыв',
                        hintText: 'Поделитесь вашими впечатлениями...',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Кнопка отправки
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Опубликовать отзыв'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Список отзывов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reviews, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Пока нет отзывов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['user_name'] ?? 'Аноним',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (review['master_name'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Мастер: ${review['master_name']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                  if (review['service_name'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Услуга: ${review['service_name']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              _formatDate(DateTime.parse(review['created_at'])),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: starIndex < (review['rating'] as int)
                                  ? Colors.amber
                                  : Colors.grey,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(review['text']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/master.dart'; // Добавьте импорт
import 'chat_screen.dart'; // Добавьте импорт

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final appointments = await ApiService.getAppointments();
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (error) {
      print('Ошибка загрузки записей: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки записей')),
      );
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      final result = await ApiService.cancelAppointment(appointmentId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Запись отменена')),
        );
        _loadAppointments(); // Обновляем список
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка отмены записи')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка отмены записи')),
      );
    }
  }

  // НОВЫЙ МЕТОД: Переход в чат с мастером
  void _openChatWithMaster(Map<String, dynamic> appointment) {
    // Создаем объект мастера из данных записи
    final master = Master(
      id: appointment['master_id'] ?? 0,
      name: appointment['master_name'] ?? 'Мастер',
      specialization: appointment['specialization'] ?? 'Парикмахер',
      description: appointment['specialization'] ?? 'Профессиональный мастер',
      experience: 3,
      imageUrl: 'assets/default_master.png',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(master: master),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои записи'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          // Кнопка для перехода в общий чат со всеми мастерами
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.pushNamed(context, '/chats');
            },
            tooltip: 'Чаты с мастерами',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'У вас пока нет записей',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Запишитесь к мастеру, чтобы начать общение',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            final appointment = _appointments[index];
            final dateTime = DateTime.parse(appointment['date_time']);
            final isPast = dateTime.isBefore(DateTime.now());

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            appointment['master_name'] ?? 'Мастер',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Кнопка чата - всегда видна
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.blue),
                              onPressed: () {
                                _openChatWithMaster(appointment);
                              },
                              tooltip: 'Написать мастеру',
                            ),
                            // Кнопка отмены - только для будущих записей
                            if (!isPast)
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  _showCancelDialog(appointment['id']);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Услуга: ${appointment['service']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Дата: ${_formatDate(dateTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Время: ${_formatTime(dateTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Статус: ${isPast ? 'Завершено' : 'Запланировано'}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isPast ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isPast)
                          ElevatedButton.icon(
                            onPressed: () {
                              _openChatWithMaster(appointment);
                            },
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Написать'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                      ],
                    ),
                    // Если запись завершена, предлагаем написать отзыв
                    if (isPast)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Добавить переход на экран отзыва
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Функция отзыва в разработке')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, size: 16),
                              SizedBox(width: 8),
                              Text('Оставить отзыв'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCancelDialog(int appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена записи'),
        content: const Text('Вы уверены, что хотите отменить запись?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
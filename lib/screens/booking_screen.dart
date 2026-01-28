import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import 'chat_screen.dart'; // Импортируем экран чата

class BookingScreen extends StatefulWidget {
  final Master? selectedMaster;

  const BookingScreen({super.key, this.selectedMaster});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int? _selectedMasterId;
  String _selectedMasterName = '';
  String _selectedService = 'Стрижка';

  bool _showSuccessMessage = false; // Добавляем флаг для отображения успеха
  Master? _bookedMaster; // Сохраняем мастера для чата

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Master> _masters = [];
  final List<String> _services = [
    'Стрижка',
    'Окрашивание',
    'Укладка',
    'Маникюр',
    'Педикюр',
    'Макияж'
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMasters();

    if (widget.selectedMaster != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedMasterId = widget.selectedMaster!.id;
          _selectedMasterName = widget.selectedMaster!.name;
        });
      });
    }
  }

  Future<void> _loadMasters() async {
    try {
      final masters = await ApiService.getMasters();
      setState(() {
        _masters = masters;
        if (masters.isNotEmpty && _selectedMasterId == null) {
          _selectedMasterId = masters.first.id;
          _selectedMasterName = masters.first.name;
        }
        _isLoading = false;
      });
    } catch (error) {
      print('Ошибка загрузки мастеров: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка загрузки мастеров')),
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    if (_selectedMasterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите мастера')),
      );
      return;
    }

    final appointmentDateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (appointmentDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя записаться на прошедшее время')),
      );
      return;
    }

    try {
      final result = await ApiService.addAppointment(
        _selectedMasterId!,
        _selectedService,
        appointmentDateTime,
        _nameController.text,
        _phoneController.text,
      );

      if (result['success'] == true) {
        // Находим мастера для чата
        // В методе _bookAppointment найдите:
        final bookedMaster = _masters.firstWhere(
              (master) => master.id == _selectedMasterId,
          orElse: () => Master(
            id: _selectedMasterId!,
            name: _selectedMasterName,
            specialization: 'Парикмахер',  // Добавьте
            description: 'Профессиональный мастер',  // Добавьте
            experience: 3,  // Добавьте
            imageUrl: 'assets/default_master.png',  // Добавьте
          ),
        );

        setState(() {
          _showSuccessMessage = true;
          _bookedMaster = bookedMaster;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Запись успешно создана!')),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка создания записи')),
        );
      }
    } catch (error) {
      print('Ошибка создания записи: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка создания записи')),
      );
    }
  }

  void _openChat() {
    if (_bookedMaster != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(master: _bookedMaster!),
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _showSuccessMessage = false;
      _bookedMaster = null;
      _nameController.clear();
      _phoneController.clear();
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Запись'),
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Если запись успешна, показываем сообщение и кнопку чата
            if (_showSuccessMessage && _bookedMaster != null)
              _buildSuccessCard(),

            if (!_showSuccessMessage) ...[
              // КАЛЕНДАРЬ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Выбранная дата: ${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.pink.shade100,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ВЫБОР ВРЕМЕНИ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выберите время:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Text('${_selectedTime.format(context)}'),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: _selectTime,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Выбор мастера и услуги
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Мастер:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<int>(
                        value: _selectedMasterId,
                        isExpanded: true,
                        items: _masters.map((Master master) {
                          return DropdownMenuItem<int>(
                            value: master.id,
                            child: Text(master.name),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedMasterId = newValue;
                            _selectedMasterName = _masters
                                .firstWhere((master) => master.id == newValue)
                                .name;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Услуга:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedService,
                        isExpanded: true,
                        items: _services.map((String service) {
                          return DropdownMenuItem<String>(
                            value: service,
                            child: Text(service),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedService = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Данные клиента
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ваши данные:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Кнопка записи
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Записаться',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],

            // Кнопка новой записи (показывается после успеха)
            if (_showSuccessMessage)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Создать новую запись',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Запись успешно создана!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Мастер: $_selectedMasterName',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Дата: ${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Время: ${_selectedTime.format(context)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Хотите обсудить детали с мастером?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.chat),
                label: const Text(
                  'Начать чат с мастером',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
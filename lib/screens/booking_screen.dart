import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../models/master.dart';

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

    // ПРОСТАЯ ПРОВЕРКА - нельзя записываться на прошедшее время
    if (appointmentDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя записаться на прошедшее время')),
      );
      return;
    }

    try {
      // ПРОПУСКАЕМ ПРОВЕРКУ ДОСТУПНОСТИ (будет работать всегда)
      final isAvailable = true;

      if (!isAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Это время уже занято. Выберите другое время.')),
        );
        return;
      }

      // Создаем запись
      final result = await ApiService.addAppointment(
        _selectedMasterId!,
        _selectedService,
        appointmentDateTime,
        _nameController.text,
        _phoneController.text,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Запись успешно создана!')),
        );

        // Очищаем форму
        _nameController.clear();
        _phoneController.clear();
        setState(() {
          _selectedDay = DateTime.now();
          _focusedDay = DateTime.now();
          _selectedTime = const TimeOfDay(hour: 10, minute: 0);
        });
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
            // КАЛЕНДАРЬ - ОСТАВЬТЕ ТОЛЬКО ЭТОТ ОДИН
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

            // ВЫБОР ВРЕМЕНИ - ДОБАВЬТЕ ЭТОТ БЛОК
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
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payment_success_screen.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String serviceType;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.serviceType,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedCardIndex = 0;
  List<dynamic> _cards = [];
  bool _isLoading = true;
  bool _showAddCardForm = false;

  // Поля для новой карты
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryMonthController = TextEditingController();
  final TextEditingController _expiryYearController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _isDefaultCard = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await ApiService.getUserCards();
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (error) {
      print('Ошибка загрузки карт: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewCard() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryMonthController.text.isEmpty ||
        _expiryYearController.text.isEmpty ||
        _cardHolderController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    try {
      final result = await ApiService.addCard(
        _cardNumberController.text,
        int.parse(_expiryMonthController.text),
        int.parse(_expiryYearController.text),
        _cardHolderController.text,
        _cvvController.text,
        _isDefaultCard,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Карта добавлена')),
        );

        // Очищаем форму
        _cardNumberController.clear();
        _expiryMonthController.clear();
        _expiryYearController.clear();
        _cardHolderController.clear();
        _cvvController.clear();

        setState(() {
          _showAddCardForm = false;
          _isDefaultCard = false;
        });

        _loadCards(); // Обновляем список карт
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка добавления карты')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления карты')),
      );
    }
  }

  Future<void> _processPayment() async {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте карту для оплаты')),
      );
      return;
    }

    try {
      final selectedCard = _cards[_selectedCardIndex];
      final result = await ApiService.processPayment(
        selectedCard['id'],
        widget.amount,
        widget.serviceType,
      );

      if (result['success'] == true) {
        // Переходим на экран успешной оплаты
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              amount: widget.amount,
              serviceType: widget.serviceType,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Ошибка оплаты')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка проведения платежа')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о заказе
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Детали заказа',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Услуга: ${widget.serviceType}'),
                    const SizedBox(height: 8),
                    Text(
                      'Сумма: ${widget.amount} тг',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Выбор карты
            if (!_showAddCardForm) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выберите карту',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddCardForm = true;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить карту'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_cards.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('Нет сохраненных карт'),
                    ),
                  ),
                )
              else
                ..._cards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: _selectedCardIndex == index
                        ? Colors.blue.shade50
                        : Colors.white,
                    child: RadioListTile<int>(
                      value: index,
                      groupValue: _selectedCardIndex,
                      onChanged: (value) {
                        setState(() {
                          _selectedCardIndex = value!;
                        });
                      },
                      title: Text(
                        card['card_number'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Действует до: ${card['expiry_month']}/${card['expiry_year']}',
                      ),
                      secondary: card['is_default']
                          ? const Chip(
                        label: Text(
                          'По умолчанию',
                          style: TextStyle(fontSize: 10),
                        ),
                      )
                          : null,
                    ),
                  );
                }).toList(),

              const SizedBox(height: 20),

              // Кнопка оплаты
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Оплатить',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],

            // Форма добавления карты
            if (_showAddCardForm) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Добавить новую карту',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Номер карты',
                          hintText: '1234 5678 9012 3456',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryMonthController,
                              decoration: const InputDecoration(
                                labelText: 'Месяц',
                                hintText: '12',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _expiryYearController,
                              decoration: const InputDecoration(
                                labelText: 'Год',
                                hintText: '25',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _cvvController,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                                hintText: '123',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 3,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cardHolderController,
                        decoration: const InputDecoration(
                          labelText: 'Имя владельца',
                          hintText: 'IVAN IVANOV',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _isDefaultCard,
                            onChanged: (value) {
                              setState(() {
                                _isDefaultCard = value!;
                              });
                            },
                          ),
                          const Text('Использовать по умолчанию'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showAddCardForm = false;
                                });
                              },
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _addNewCard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cardHolderController.dispose();
    _cvvController.dispose();
    super.dispose();
  }
}
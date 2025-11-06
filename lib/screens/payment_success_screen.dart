import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String serviceType;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Анимация успеха
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Заголовок
          const Text(
            'Оплата прошла успешно!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Поздравление
          Text(
            'Поздравляем! Вы успешно оплатили услугу',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            '"$serviceType"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'на сумму ${amount} ₽',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 40),

          // Детали платежа
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Статус:', style: TextStyle(color: Colors.grey)),
                    Text('Успешно', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Дата:', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Время:', style: TextStyle(color: Colors.grey)),
                    Text(
                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Кнопки
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Возврат на главную
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Вернуться на главную'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // TODO: Переход к истории платежей
                  },
                  child: const Text('Посмотреть историю платежей'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
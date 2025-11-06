import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('О приложении'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Логотип приложения
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.spa,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Название приложения
            Text(
              'Beauty Salon',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade700,
              ),
            ),

            const SizedBox(height: 8),

            // Версия
            Text(
              'Версия 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 40),

            // Карточка с описанием
            _buildInfoCard(
              icon: Icons.brush,
              title: 'О приложении',
              content: 'Beauty Salon - это современное мобильное приложение для записи в салон красоты. '
                  'Выбирайте мастеров, бронируйте удобное время и получайте качественные услуги '
                  'в пару касаний.',
            ),

            const SizedBox(height: 20),

            // Карточка с возможностями
            _buildInfoCard(
              icon: Icons.star,
              title: 'Возможности',
              content: '• Запись к мастерам\n'
                  '• Просмотр отзывов\n'
                  '• Избранные мастера\n'
                  '• Управление записями\n'
                  '• Онлайн-бронирование',
            ),

            const SizedBox(height: 20),

            // Карточка с контактами
            _buildInfoCard(
              icon: Icons.phone,
              title: 'Контакты',
              content: '📞 +7 (777) 199-11-07\n'
                  '📧 info@beautysalon.ru\n'
                  '📍 г. Астана, ул. Мангилик ел, 1\n'
                  '🕒 Ежедневно с 9:00 до 21:00',
            ),

            const SizedBox(height: 30),

            // Разработчики
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Разработка',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.code,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flutter Development Team',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Создано с ❤️ на Flutter',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Кнопка обратной связи
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showFeedbackDialog(context);
                },
                icon: const Icon(Icons.feedback),
                label: const Text('Обратная связь'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Копирайт
            Text(
              '© 2024 Beauty Salon. Все права защищены.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.pink, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обратная связь'),
        content: const Text(
          'Спасибо за интерес к нашему приложению! '
              'Ваши предложения и замечания можно отправить на почту info@beautysalon.ru',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Спасибо за ваше мнение!')),
              );
            },
            child: const Text('Хорошо'),
          ),
        ],
      ),
    );
  }
}
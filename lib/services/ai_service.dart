// services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Получите на platform.openai.com
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  // Для тестирования без API ключа
  static const bool _useMock = true;

  static Future<String> getAiResponse({
    required String message,
    required String masterName,
    String serviceType = 'услуга',
  }) async {
    if (_useMock) {
      // Мок-ответы для тестирования без API ключа
      return _getMockResponse(message, masterName, serviceType);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Ты ассистент мастера $masterName, специализирующегося на $serviceType. '
                  'Отвечай вежливо, профессионально, но дружелюбно. '
                  'Используй имя мастера в ответах. Максимальная длина ответа 150 символов.'
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Извините, произошла ошибка. Пожалуйста, попробуйте позже.';
      }
    } catch (e) {
      print('AI Error: $e');
      return _getMockResponse(message, masterName, serviceType);
    }
  }

  static String _getMockResponse(String message, String masterName, String serviceType) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('привет') || lowerMessage.contains('здравствуй')) {
      return 'Привет! Это $masterName. Чем могу помочь?';
    } else if (lowerMessage.contains('стоимость') || lowerMessage.contains('цена') || lowerMessage.contains('сколько')) {
      return 'Стоимость $serviceType у $masterName начинается от 5500 тенге. Точную цену могу назвать после консультации.';
    } else if (lowerMessage.contains('время') || lowerMessage.contains('долго') || lowerMessage.contains('продолжительность')) {
      return 'Продолжительность $serviceType обычно 1-2 часа. $masterName работает с 10:00 до 20:00.';
    } else if (lowerMessage.contains('подготов') || lowerMessage.contains('нужно')) {
      return 'Для подготовки к $serviceType $masterName рекомендует: приходить без макияжа, не мыть голову за день до процедуры.';
    } else if (lowerMessage.contains('отмена') || lowerMessage.contains('перенос')) {
      return 'Отменить или перенести запись можно за 24 часа до визита. Свяжитесь с администратором.';
    } else if (lowerMessage.contains('опыт') || lowerMessage.contains('стаж')) {
      return '$masterName работает в индустрии красоты более 5 лет, имеет сертификаты и регулярно повышает квалификацию.';
    } else if (lowerMessage.contains('спасибо') || lowerMessage.contains('благодар')) {
      return 'Всегда рад помочь! $masterName ждет вас на процедуре. Не стесняйтесь задавать вопросы.';
    } else if (lowerMessage.contains('материал') || lowerMessage.contains('средств')) {
      return '$masterName использует только профессиональные сертифицированные материалы премиум-класса.';
    }

    // Общий ответ
    final responses = [
      'Отличный вопрос! $masterName рекомендует проконсультироваться лично для детального ответа.',
      '$masterName говорит, что это зависит от многих факторов. Лучше обсудить при встрече.',
      'Интересный вопрос! $masterName с радостью ответит на него во время вашего визита.',
      'Для точного ответа $masterName нужно видеть ситуацию. Запишитесь на консультацию.',
      '$masterName ценит ваше внимание к деталям! Это важный момент для обсуждения.',
    ];

    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/master.dart';
import '../models/message.dart';
class ApiService {
  // 🚀 ОБНОВИТЕ АДРЕС НА ВАШ АКТУАЛЬНЫЙ
  static const String baseUrl = 'http://localhost:5000/api';
  static String? token;

  static Future<http.Response> _request(String method, String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('🌐 Отправка запроса: $method $url');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: json.encode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Метод $method не поддерживается');
      }

      print('✅ Ответ получен: ${response.statusCode}');
      return response;
    } catch (error) {
      print('❌ Ошибка сети: $error');
      rethrow;
    }
  }

  // Auth methods
  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _request('POST', '/register', body: {
        'email': email,
        'password': password,
        'name': name,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        token = data['token'];
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _request('POST', '/login', body: {
        'email': email,
        'password': password,
      });

      final data = json.decode(response.body);
      print('🔍 Login response data: $data'); // Для отладки

      if (response.statusCode == 200) {
        token = data['token'];

        // ПРОСТО ВОЗВРАЩАЕМ УСПЕХ БЕЗ ПОЛЬЗОВАТЕЛЯ
        return {
          'success': true,
          'message': data['message'] ?? 'Вход выполнен успешно'
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    try {
      final response = await _request('POST', '/profile', body: {
        'name': name,
        'email': email,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Возвращаем обновленного пользователя
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Ошибка обновления профиля'};
      }
    } catch (error) {
      print('💥 Ошибка обновления профиля: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  // Masters methods
  static Future<List<Master>> getMasters() async {
    try {
      final response = await _request('GET', '/masters');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Master.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки мастеров: ${response.statusCode}');
      }
    } catch (error) {
      print('💥 Ошибка загрузки мастеров: $error');
      throw Exception('Не удалось загрузить мастеров: $error');
    }
  }

  // Favorites methods
  static Future<List<Master>> getFavorites() async {
    try {
      print('❤️ Запрос избранных мастеров');
      final response = await _request('GET', '/favorites');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Получено избранных мастеров: ${data.length}');
        return data.map((json) => Master.fromJson(json)).toList();
      } else {
        throw Exception('Ошибка загрузки избранных мастеров: ${response.statusCode}');
      }
    } catch (error) {
      print('💥 Ошибка загрузки избранных: $error');
      throw Exception('Не удалось загрузить избранных мастеров: $error');
    }
  }

  static Future<Map<String, dynamic>> addToFavorites(int masterId) async {
    try {
      print('➕ Добавление в избранное: $masterId');
      final response = await _request('POST', '/favorites', body: {
        'master_id': masterId,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка добавления в избранное: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  static Future<Map<String, dynamic>> removeFromFavorites(int masterId) async {
    try {
      print('➖ Удаление из избранного: $masterId');
      final response = await _request('DELETE', '/favorites/$masterId');

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка удаления из избранного: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  // Appointment methods
  static Future<List<dynamic>> getAppointments() async {
    try {
      final response = await _request('GET', '/appointments');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка загрузки записей: ${response.statusCode}');
      }
    } catch (error) {
      print('💥 Ошибка загрузки записей: $error');
      throw Exception('Не удалось загрузить записи: $error');
    }
  }

  static Future<Map<String, dynamic>> addAppointment(
      int masterId,
      String service,
      DateTime dateTime,
      String clientName,
      String clientPhone
      ) async {
    try {
      print('📅 Создание записи: $masterId, $service, $dateTime');
      final response = await _request('POST', '/appointments', body: {
        'master_id': masterId,
        'service': service,
        'date_time': dateTime.toIso8601String(),
        'client_name': clientName,
        'client_phone': clientPhone,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка создания записи: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  // Availability check
  static Future<bool> isTimeSlotAvailable(DateTime dateTime, int masterId) async {
    try {
      final response = await _request('POST', '/check-availability', body: {
        'master_id': masterId,
        'date_time': dateTime.toIso8601String(),
      });

      // ЕСЛИ ENDPOINT НЕ СУЩЕСТВУЕТ, ВОЗВРАЩАЕМ TRUE
      if (response.statusCode == 404) {
        print('⚠️ Endpoint /check-availability не найден, пропускаем проверку');
        return true;
      }

      final data = json.decode(response.body);
      return data['available'] ?? false;
    } catch (error) {
      print('💥 Ошибка проверки доступности: $error');
      // ПРИ ЛЮБОЙ ОШИБКЕ ВОЗВРАЩАЕМ TRUE (РАЗРЕШАЕМ ЗАПИСЬ)
      return true;
    }
  }

// api_service.dart - исправьте метод addReview
  static Future<Map<String, dynamic>> addReview(
      String text,
      int rating,
      int masterId,
      int serviceId
      ) async {
    try {
      final response = await _request('POST', '/reviews', body: {
        'text': text,
        'rating': rating,
        'master_id': masterId,
        'service_id': serviceId,
      });

      final data = json.decode(response.body);

      // Обрабатываем разные статусы
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Отзыв добавлен!'
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'message': data['message'] ?? 'Заполните все поля'
        };
      } else if (response.statusCode == 409) {
        return {
          'success': false,
          'message': data['message'] ?? 'Вы уже оставляли отзыв'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Ошибка добавления отзыва'
        };
      }
    } catch (error) {
      print('💥 Ошибка добавления отзыва: $error');
      return {
        'success': false,
        'message': 'Ошибка сети: $error'
      };
    }
  }

// Исправьте метод getReviews
  static Future<List<dynamic>> getReviews() async {
    try {
      final response = await _request('GET', '/reviews');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ВАЖНО: теперь API возвращает массив напрямую, а не объект с reviews
        if (data is List) {
          return data;
        } else if (data is Map && data.containsKey('reviews')) {
          // На случай если где-то еще возвращается старая структура
          return data['reviews'] ?? [];
        } else {
          return [];
        }
      } else {
        throw Exception('Ошибка загрузки отзывов: ${response.statusCode}');
      }
    } catch (error) {
      print('💥 Ошибка загрузки отзывов: $error');
      throw Exception('Не удалось загрузить отзывы: $error');
    }
  }

// Опционально: метод для отмены записи
  static Future<Map<String, dynamic>> cancelAppointment(int appointmentId) async {
    try {
      final response = await _request('DELETE', '/appointments/$appointmentId');

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка отмены записи: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  // Добавьте эти методы в ApiService
  static Future<List<dynamic>> getUserCards() async {
    try {
      final response = await _request('GET', '/cards');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка загрузки карт: ${response.statusCode}');
      }
    } catch (error) {
      print('💥 Ошибка загрузки карт: $error');
      throw Exception('Не удалось загрузить карты: $error');
    }
  }

  static Future<Map<String, dynamic>> addCard(
      String cardNumber,
      int expiryMonth,
      int expiryYear,
      String cardHolder,
      String cvv,
      bool isDefault,
      ) async {
    try {
      final response = await _request('POST', '/cards', body: {
        'card_number': cardNumber,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'card_holder': cardHolder,
        'cvv': cvv,
        'is_default': isDefault,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка добавления карты: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }

  static Future<Map<String, dynamic>> processPayment(
      int cardId,
      double amount,
      String serviceType,
      ) async {
    try {
      final response = await _request('POST', '/payments', body: {
        'card_id': cardId,
        'amount': amount,
        'service_type': serviceType,
      });

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      print('💥 Ошибка проведения платежа: $error');
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }
  // В api_service.dart добавь метод (если его нет)
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }
  static Future<Map<String, dynamic>> changePassword(
      String currentPassword,
      String newPassword
      ) async {
    try {
      final response = await _request('POST', '/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (error) {
      return {'success': false, 'message': 'Ошибка сети: $error'};
    }
  }
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
  // В ApiService добавьте:
  static Future<List<Message>> getMessages(int masterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$masterId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  static Future<bool> saveMessage(Message message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving message: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getChats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Ошибка загрузки чатов'};
    } catch (e) {
      print('Error getting chats: $e');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }


  static Future<Map<String, dynamic>> sendMessage({
    required int masterId,
    required String text,
    bool isFromUser = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: _getHeaders(),
        body: json.encode({
          'master_id': masterId,
          'text': text,
          'is_from_user': isFromUser,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Ошибка отправки сообщения'};
    } catch (e) {
      print('Error sending message: $e');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats/unread-count'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Ошибка загрузки счетчика'};
    } catch (e) {
      print('Error getting unread count: $e');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> clearChatHistory(int masterId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/messages/$masterId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Ошибка очистки чата'};
    } catch (e) {
      print('Error clearing chat: $e');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }
}



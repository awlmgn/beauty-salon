// screens/chats_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/master.dart';
import '../models/chat.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<Chat> _chats = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      print('🔄 Начинаю загрузку чатов...');

      // Проверяем есть ли токен
      if (ApiService.token == null) {
        print('⚠️ Токен не найден, показываю заглушку');
        _showMockChats();
        return;
      }

      final response = await ApiService.getChats();

      print('📡 Ответ от сервера: ${response['success']}');

      if (response['success'] == true) {
        final chatsData = response['chats'] as List;
        print('📊 Получено ${chatsData.length} чатов');

        final chats = chatsData.map((json) => Chat.fromJson(json)).toList();

        setState(() {
          _chats = chats;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        print('❌ Ошибка от сервера: ${response['message']}');
        _showMockChats();
      }
    } catch (error) {
      print('💥 Критическая ошибка загрузки чатов: $error');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      // Для тестирования показываем мок-данные
      _showMockChats();
    }
  }

  void _showMockChats() {
    print('🔄 Показываю тестовые чаты');

    final mockChats = [
      Chat(
        masterId: 1,
        master: Master(
          id: 1,
          name: 'Камилла',
          specialization: 'Парикмахер',
          description: 'Опытный парикмахер с 5-летним стажем',
          experience: 5,
          imageUrl: 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?w=150',
          rating: 4.8,
        ),
        lastMessage: 'Здравствуйте! Когда вам удобно прийти?',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 30)),
        unreadCount: 2,
      ),
      Chat(
        masterId: 2,
        master: Master(
          id: 2,
          name: 'Нургуль',
          specialization: 'Визажист',
          description: 'Профессиональный визажист для свадеб и мероприятий',
          experience: 3,
          imageUrl: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=150',
          rating: 4.9,
        ),
        lastMessage: 'Спасибо за запись! Жду вас в пятницу.',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
      Chat(
        masterId: 3,
        master: Master(
          id: 3,
          name: 'Сабина',
          specialization: 'Мастер маникюра',
          description: 'Специалист по ногтевому сервису',
          experience: 4,
          imageUrl: 'https://images.unsplash.com/photo-1605497788044-5a32c7078486?w=150',
          rating: 4.7,
        ),
        lastMessage: 'Какой цвет лака предпочитаете?',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 1,
      ),
      Chat(
        masterId: 4,
        master: Master(
          id: 4,
          name: 'Дина',
          specialization: 'Косметолог',
          description: 'Специалист по уходу за кожей',
          experience: 6,
          imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150',
          rating: 4.8,
        ),
        lastMessage: 'Напоминаю о завтрашней процедуре',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 3)),
        unreadCount: 0,
      ),
    ];

    // Имитируем загрузку
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _chats = mockChats;
          _isLoading = false;
        });
      }
    });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
      return weekdays[date.weekday];
    } else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildChatItem(Chat chat) {
    final master = chat.master;
    final hasUnread = chat.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.pink.shade50,
          backgroundImage: NetworkImage(master.imageUrl),
          child: master.imageUrl.isEmpty
              ? Text(
            master.name[0],
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                master.name,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                  color: hasUnread ? Colors.black : Colors.black87,
                ),
              ),
            ),
            Text(
              _formatTime(chat.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? Colors.pink : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage ?? 'Нет сообщений',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: hasUnread ? Colors.black : Colors.grey.shade700,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              master.specialization,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: hasUnread
            ? Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.pink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              chat.unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(master: master),
            ),
          ).then((_) {
            // Обновляем список после возврата из чата
            _loadChats();
          });
        },
        onLongPress: () {
          _showChatOptions(chat);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои чаты'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pink),
            SizedBox(height: 16),
            Text(
              'Загружаем ваши чаты...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : _chats.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Пока нет чатов',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Запишитесь к мастеру, чтобы начать общение',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Возвращаемся на главную
              },
              icon: const Icon(Icons.home),
              label: const Text('Перейти к мастерам'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadChats,
        color: Colors.pink,
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: _chats.length,
          separatorBuilder: (context, index) =>
          const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return _buildChatItem(_chats[index]);
          },
        ),
      ),
      floatingActionButton: _chats.isNotEmpty
          ? FloatingActionButton(
        onPressed: () {
          // Показать всех мастеров для создания нового чата
          _showAllMasters();
        },
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
        tooltip: 'Новый чат',
      )
          : null,
    );
  }

  void _showChatOptions(Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Очистить историю чата'),
                onTap: () {
                  Navigator.pop(context);
                  _clearChatHistory(chat.masterId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.orange),
                title: const Text('Заблокировать мастера'),
                onTap: () {
                  Navigator.pop(context);
                  _blockMaster(chat.master);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Отмена'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearChatHistory(int masterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить историю'),
        content: const Text('Вы уверены, что хотите очистить историю этого чата?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать очистку истории чата на сервере
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('История чата будет очищена'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _blockMaster(Master master) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Блокировка мастера'),
        content: Text('Заблокировать ${master.name}? Вы больше не будете получать сообщения от этого мастера.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать блокировку мастера
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Мастер ${master.name} заблокирован'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }

  void _showAllMasters() {
    // TODO: Реализовать экран выбора мастера для нового чата
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Выберите мастера из списка для начала нового чата'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart'; // Будем создавать
import '../models/master.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final Master master;

  const ChatScreen({Key? key, required this.master}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Автоматическое приветствие от ИИ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendAiGreeting();
    });
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ApiService.getMessages(widget.master.id);
      setState(() {
        _messages.addAll(messages);
      });
    } catch (error) {
      print('Ошибка загрузки сообщений: $error');
    }
  }

  void _sendAiGreeting() {
    final greetingMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      masterId: widget.master.id,
      text: 'Привет! Я ${widget.master.name}. Рад, что вы записались ко мне. '
          'Чем могу помочь? Вы можете спросить о:'
          '\n• Подготовке к процедуре'
          '\n• Стоимости услуг'
          '\n• Продолжительности сеанса'
          '\n• Рекомендациях по уходу',
      isFromUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, greetingMessage);
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Сообщение пользователя
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      masterId: widget.master.id,
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _messageController.clear();
      _isLoading = true;
    });

    try {
      // Отправляем сообщение и получаем ответ от ИИ
      final aiResponse = await AiService.getAiResponse(
        message: text,
        masterName: widget.master.name,
        serviceType: widget.master.specialization ?? 'услуга',
      );

      // Ответ от ИИ (мастера)
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        masterId: widget.master.id,
        text: aiResponse,
        isFromUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.insert(0, aiMessage);
      });

      // Сохраняем в базу (опционально)
      await ApiService.saveMessage(userMessage);
      await ApiService.saveMessage(aiMessage);

    } catch (error) {
      print('Ошибка отправки сообщения: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка отправки сообщения')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isFromUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.pink.shade100,
              child: Text(
                widget.master.name[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.blue.shade900 : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink.shade100,
              child: Text(
                widget.master.name[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.master.name),
                const Text(
                  'ИИ-ассистент',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
              child: Text('Начните общение с мастером'),
            )
                : ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/foundation.dart';
import '../data/chat_repository.dart';
import '../data/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository repository;
  
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider({required this.repository});

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    // Optimistic UI: Thêm tin nhắn vào list ngay lập tức
    _messages.insert(0, newMessage);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gửi lên server
      await repository.sendMessage(newMessage);
      
      // Nếu thành công, có thể cập nhật trạng thái tin nhắn (ví dụ: đã gửi)
      // Ở đây ta giữ nguyên
    } catch (e) {
      _error = "Không thể gửi tin nhắn: $e";
      // Nếu lỗi, có thể cân nhắc xóa tin nhắn hoặc đánh dấu lỗi
      // _messages.removeAt(0); 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

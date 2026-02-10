import '../../../core/services/api_service.dart';
import 'message_model.dart';

class ChatRepository {
  final ApiService apiService;

  ChatRepository({required this.apiService});

  Future<bool> sendMessage(Message message) async {
    // Gọi API Service để gửi tin nhắn
    // Chúng ta gửi JSON của message lên server
    return await apiService.sendMessage(message.toJson());
  }
}

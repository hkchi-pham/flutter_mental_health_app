import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_nhat_ky/features/chat/data/dto/message_dto.dart';
import 'package:flutter_application_nhat_ky/features/chat/data/dto/conversation_dto.dart';
import 'package:flutter_application_nhat_ky/features/chat/data/models/chat_message.dart';
import 'package:flutter_application_nhat_ky/features/chat/data/models/conversation.dart';

void main() {
  group('MessageDto role mapping', () {
    test('message_type:ai -> ChatRole.bot', () {
      final dto = MessageDto.fromJson({
        'id': '1',
        'conversation_id': 'c1',
        'content': 'hi',
        'message_type': 'ai',
      });
      expect(dto.toLocal().role, ChatRole.bot);
    });

    test('message_type:text -> ChatRole.user', () {
      final dto = MessageDto.fromJson({
        'id': '2',
        'conversation_id': 'c1',
        'content': 'hi',
        'message_type': 'text',
      });
      expect(dto.toLocal().role, ChatRole.user);
    });

    test('sender_id:ai_assistant -> ChatRole.bot', () {
      final dto = MessageDto.fromJson({
        'id': '3',
        'sender_id': 'ai_assistant',
        'conversation_id': 'c1',
        'content': 'hello',
        'message_type': 'ai',
      });
      expect(dto.toLocal().role, ChatRole.bot);
    });

    test('sender_id:ai_assistant with non-ai message_type -> ChatRole.bot', () {
      final dto = MessageDto.fromJson({
        'id': '4',
        'sender_id': 'ai_assistant',
        'conversation_id': 'c1',
        'content': 'hello',
        'message_type': 'text',
      });
      expect(dto.toLocal().role, ChatRole.bot);
    });

    test('content is preserved', () {
      final dto = MessageDto.fromJson({
        'id': '5',
        'conversation_id': 'c1',
        'content': 'Test message',
        'message_type': 'text',
      });
      expect(dto.toLocal().content, 'Test message');
    });
  });

  group('ConversationDto mapping', () {
    test('fromJson parses id and persona', () {
      final dto = ConversationDto.fromJson({
        'id': 'c1',
        'user_id': 'u1',
        'persona': 'komo',
        'created_at': '2026-06-28T10:00:00',
      });
      final local = dto.toLocal();
      expect(local.id, 'c1');
      expect(local.persona, 'komo');
    });

    test('fromJson parses createdAt', () {
      final dto = ConversationDto.fromJson({
        'id': 'c1',
        'user_id': 'u1',
        'persona': 'komo',
        'created_at': '2026-06-28T10:00:00',
      });
      final local = dto.toLocal();
      expect(local.createdAt.year, 2026);
      expect(local.createdAt.month, 6);
      expect(local.createdAt.day, 28);
    });

    test('toLocal title is null (derived later)', () {
      final dto = ConversationDto.fromJson({
        'id': 'c1',
        'user_id': 'u1',
        'persona': 'komo',
        'created_at': '2026-06-28T10:00:00',
      });
      expect(dto.toLocal().title, isNull);
    });

    test('toCreateJson returns komo persona', () {
      final json = ConversationDto.createJson();
      expect(json['persona'], 'komo');
    });
  });

  group('Conversation.deriveTitle', () {
    test('short message returns as-is', () {
      const msg = 'Chào Komo';
      final title = Conversation.deriveTitle(msg);
      expect(title, 'Chào Komo');
      expect(title.length, lessThanOrEqualTo(33)); // 30 + ellipsis
    });

    test('long message is truncated with ellipsis', () {
      const msg = 'Mình đang cảm thấy vui. Chào Komo hôm nay trời rất đẹp';
      final title = Conversation.deriveTitle(msg);
      expect(title.endsWith('…'), isTrue);
      expect(title.length, lessThanOrEqualTo(31)); // 30 chars + '…'
    });

    test('message exactly 30 chars is not truncated', () {
      // 30 chars exactly
      const msg = '123456789012345678901234567890';
      final title = Conversation.deriveTitle(msg);
      expect(title, msg);
      expect(title.endsWith('…'), isFalse);
    });

    test('message 31 chars is truncated', () {
      const msg = '1234567890123456789012345678901';
      final title = Conversation.deriveTitle(msg);
      expect(title.endsWith('…'), isTrue);
    });

    test('whitespace is trimmed', () {
      const msg = '  Chào Komo  ';
      final title = Conversation.deriveTitle(msg);
      expect(title, 'Chào Komo');
    });
  });
}

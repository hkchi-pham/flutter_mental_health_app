import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_nhat_ky/features/profile/data/profile_user.dart';

void main() {
  group('ProfileUser.fromJson', () {
    test('parses full MeRead payload correctly', () {
      final json = {
        'id': 'abc123',
        'user_name': 'khanh_chi',
        'fullname': 'Khánh Chi',
        'email': 'khanh@example.com',
        'avatar': 'https://example.com/avatar.png',
        'points': 150,
        'water_units': 42,
        'tree_grown': 7,
        'journal_count': 12,
        'conversation_count': 5,
        'badge_count': 3,
        'created_at': '2025-01-01T00:00:00Z',
      };
      final user = ProfileUser.fromJson(json);

      expect(user.id, 'abc123');
      expect(user.userName, 'khanh_chi');
      expect(user.fullname, 'Khánh Chi');
      expect(user.email, 'khanh@example.com');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.points, 150);
      expect(user.waterUnits, 42);
      expect(user.treeGrown, 7);
      expect(user.journalCount, 12);
      expect(user.conversationCount, 5);
      expect(user.badgeCount, 3);
    });

    test('defaults missing numeric counts to 0', () {
      final json = <String, dynamic>{
        'id': 'x',
        'user_name': 'u',
        'fullname': 'F',
        'email': 'e@e.com',
        'avatar': '',
        // all numeric fields omitted
      };
      final user = ProfileUser.fromJson(json);

      expect(user.points, 0);
      expect(user.waterUnits, 0);
      expect(user.treeGrown, 0);
      expect(user.journalCount, 0);
      expect(user.conversationCount, 0);
      expect(user.badgeCount, 0);
    });

    test('defaults missing email to empty string', () {
      final json = <String, dynamic>{
        'id': 'x',
        'user_name': 'u',
        'fullname': 'F',
        // email omitted
        // avatar omitted
      };
      final user = ProfileUser.fromJson(json);

      expect(user.email, '');
      expect(user.avatar, '');
    });

    test('defaults null numeric fields to 0', () {
      final json = <String, dynamic>{
        'id': 'x',
        'user_name': 'u',
        'fullname': 'F',
        'email': null,
        'avatar': null,
        'points': null,
        'water_units': null,
        'tree_grown': null,
        'journal_count': null,
        'conversation_count': null,
        'badge_count': null,
      };
      final user = ProfileUser.fromJson(json);

      expect(user.email, '');
      expect(user.avatar, '');
      expect(user.points, 0);
      expect(user.waterUnits, 0);
      expect(user.treeGrown, 0);
      expect(user.journalCount, 0);
      expect(user.conversationCount, 0);
      expect(user.badgeCount, 0);
    });
  });

  group('ProfileUser.copyWith', () {
    late ProfileUser base;

    setUp(() {
      base = ProfileUser.fromJson({
        'id': 'abc',
        'user_name': 'chi',
        'fullname': 'Old Name',
        'email': 'chi@example.com',
        'avatar': 'komo.png',
        'points': 10,
        'water_units': 5,
        'tree_grown': 2,
        'journal_count': 8,
        'conversation_count': 3,
        'badge_count': 1,
      });
    });

    test('copyWith(fullname:) changes only fullname', () {
      final updated = base.copyWith(fullname: 'New Name');

      expect(updated.fullname, 'New Name');
      // All other fields preserved
      expect(updated.id, base.id);
      expect(updated.userName, base.userName);
      expect(updated.email, base.email);
      expect(updated.avatar, base.avatar);
      expect(updated.points, base.points);
      expect(updated.waterUnits, base.waterUnits);
      expect(updated.treeGrown, base.treeGrown);
      expect(updated.journalCount, base.journalCount);
      expect(updated.conversationCount, base.conversationCount);
      expect(updated.badgeCount, base.badgeCount);
    });

    test('copyWith with no arguments returns equivalent object', () {
      final copy = base.copyWith();

      expect(copy.id, base.id);
      expect(copy.fullname, base.fullname);
      expect(copy.email, base.email);
    });

    test('copyWith(avatar:) changes only avatar', () {
      final updated = base.copyWith(avatar: 'new_avatar.png');

      expect(updated.avatar, 'new_avatar.png');
      expect(updated.fullname, base.fullname);
    });
  });
}

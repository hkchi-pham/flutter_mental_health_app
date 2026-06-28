// Unit tests for Mood model + moodFromFirstMessage + ChatDateGroup bucketing.
// These are pure Dart tests — no widgets, no Flutter binding.
//
// TDD RED phase: written BEFORE the implementation files exist.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_nhat_ky/features/chat/logic/mood.dart';
import 'package:flutter_application_nhat_ky/features/chat/logic/chat_date_group.dart';

void main() {
  group('Mood enum', () {
    test('has exactly 7 values', () {
      expect(Mood.values.length, 7);
    });

    test('Mood.happy.label == "Vui"', () {
      expect(Mood.happy.label, 'Vui');
    });

    test('Mood.calm.label == "Bình tĩnh"', () {
      expect(Mood.calm.label, 'Bình tĩnh');
    });

    test('Mood.normal.label == "Bình thường"', () {
      expect(Mood.normal.label, 'Bình thường');
    });

    test('Mood.sad.label == "Buồn"', () {
      expect(Mood.sad.label, 'Buồn');
    });

    test('Mood.anxious.label == "Lo lắng"', () {
      expect(Mood.anxious.label, 'Lo lắng');
    });

    test('Mood.angry.label == "Giận"', () {
      expect(Mood.angry.label, 'Giận');
    });

    test('Mood.tired.label == "Mệt"', () {
      expect(Mood.tired.label, 'Mệt');
    });

    test('Mood.happy.iconAsset is the mood_happy_icon_@3x.png path', () {
      expect(
        Mood.happy.iconAsset,
        'assets/ui_icons/icons/mood_happy_icon_@3x.png',
      );
    });

    test('Mood.normal.iconAsset is null (no asset exists)', () {
      expect(Mood.normal.iconAsset, isNull);
    });

    test('Mood.sad.prependSentence == "Mình đang cảm thấy buồn. "', () {
      expect(Mood.sad.prependSentence, 'Mình đang cảm thấy buồn. ');
    });

    test('Mood.calm.prependSentence uses multi-word moodWord', () {
      expect(
        Mood.calm.prependSentence,
        'Mình đang cảm thấy bình tĩnh. ',
      );
    });
  });

  group('moodFromFirstMessage', () {
    test('returns Mood.sad when message starts with sad prepend', () {
      expect(
        moodFromFirstMessage('Mình đang cảm thấy buồn. Chào Komo'),
        Mood.sad,
      );
    });

    test('returns null when no mood prefix present', () {
      expect(moodFromFirstMessage('Chào Komo'), isNull);
    });

    test('returns null for null input', () {
      expect(moodFromFirstMessage(null), isNull);
    });

    test('returns null for empty input', () {
      expect(moodFromFirstMessage(''), isNull);
    });

    test('returns Mood.calm for multi-word moodWord "bình tĩnh"', () {
      expect(
        moodFromFirstMessage('Mình đang cảm thấy bình tĩnh. ...'),
        Mood.calm,
      );
    });

    test('returns Mood.happy for happy prepend', () {
      expect(
        moodFromFirstMessage('Mình đang cảm thấy vui. Hôm nay vui lắm'),
        Mood.happy,
      );
    });

    test('does not mis-detect short moodWord within longer one', () {
      // "bình thường" contains "bình" — should not match "bình tĩnh"
      // Check that "bình thường" maps correctly to Mood.normal
      expect(
        moodFromFirstMessage('Mình đang cảm thấy bình thường. '),
        Mood.normal,
      );
    });
  });

  group('ChatDateGroup bucketing', () {
    final now = DateTime(2024, 6, 15, 12, 0);

    test('same calendar day → today', () {
      expect(chatDateGroup(now, now: now), ChatDateGroup.today);
    });

    test('1 calendar day ago → yesterday', () {
      final yesterday = DateTime(2024, 6, 14, 23, 59);
      expect(chatDateGroup(yesterday, now: now), ChatDateGroup.yesterday);
    });

    test('3 days ago → thisWeek', () {
      final threeDaysAgo = DateTime(2024, 6, 12, 10, 0);
      expect(chatDateGroup(threeDaysAgo, now: now), ChatDateGroup.thisWeek);
    });

    test('20 days ago → thisMonth (bucket of last resort)', () {
      final twentyDaysAgo = DateTime(2024, 5, 26, 10, 0);
      expect(chatDateGroup(twentyDaysAgo, now: now), ChatDateGroup.thisMonth);
    });

    test('very old date → thisMonth (every conversation lands in a group)', () {
      final oldDate = DateTime(2020, 1, 1);
      expect(chatDateGroup(oldDate, now: now), ChatDateGroup.thisMonth);
    });
  });

  group('ChatDateGroup.label', () {
    test('today label is "Hôm nay"', () {
      expect(ChatDateGroup.today.label, 'Hôm nay');
    });

    test('yesterday label is "Hôm qua"', () {
      expect(ChatDateGroup.yesterday.label, 'Hôm qua');
    });

    test('thisWeek label is "Tuần này"', () {
      expect(ChatDateGroup.thisWeek.label, 'Tuần này');
    });

    test('thisMonth label is "Tháng này"', () {
      expect(ChatDateGroup.thisMonth.label, 'Tháng này');
    });
  });

  group('itemShortDate', () {
    final now = DateTime(2024, 6, 15, 14, 30);

    test('same day → HH:mm format', () {
      final todayTime = DateTime(2024, 6, 15, 9, 5);
      final result = itemShortDate(todayTime, now: now);
      expect(result, '09:05');
    });

    test('different day → d MMM format', () {
      final anotherDay = DateTime(2024, 5, 3, 10, 0);
      final result = itemShortDate(anotherDay, now: now);
      // Just verify it is not HH:mm — the exact locale-default format can vary
      expect(result.contains(':'), isFalse,
          reason: 'Non-today dates should not show HH:mm');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sogsal/logic/body_calc.dart';
import 'package:sogsal/models/models.dart';
import 'package:sogsal/widgets/character.dart';

void main() {
  group('꾸미기 저장', () {
    test('예전 저장본(피부색·머리 모양 없음)은 기본값으로 읽는다', () {
      final s = CharacterStyle.fromJson({'hairColor': 0xFF8A5A44, 'outfitColor': 0xFF3A6FD8});
      expect(s.skinColor, CharacterStyle.defaultSkin);
      expect(s.hairStyle, isNull);
    });

    test('피부색과 머리 모양이 저장됐다 다시 읽힌다', () {
      final s = const CharacterStyle().copyWith(skinColor: 0xFFC0835A, hairStyle: 'hush');
      final r = CharacterStyle.fromJson(s.toJson());
      expect(r.skinColor, 0xFFC0835A);
      expect(r.hairStyle, 'hush');
    });
  });

  group('머리 모양', () {
    test('여자 10개, 남자 10개', () {
      expect(HairStyles.female.length, 10);
      expect(HairStyles.male.length, 10);
    });

    test('성별에 없는 스타일이면 기본값', () {
      expect(HairStyles.resolve(Gender.male, 'hime'), 'crop');
      expect(HairStyles.resolve(Gender.female, null), 'bob');
      expect(HairStyles.resolve(Gender.female, 'layered'), 'layered');
    });
  });

  group('눈바디 보정', () {
    test('범위를 넘는 값은 잘라서 읽는다', () {
      final t = BodyTweak.fromJson({'shoulder': 3, 'waist': -2, 'hip': 0.4});
      expect(t.shoulder, 1);
      expect(t.waist, -1);
      expect(t.hip, 0.4);
      expect(t.arm, 0);
    });

    test('모두 0이면 보정 없음', () {
      expect(BodyTweak.none.isNone, isTrue);
      expect(const BodyTweak(thigh: 0.1).isNone, isFalse);
    });
  });

  testWidgets('머리 모양 20개 모두 그려진다', (tester) async {
    for (final g in Gender.values) {
      for (final (id, _) in HairStyles.of(g)) {
        await tester.pumpWidget(CharacterHead(
          gender: g,
          shape: const BodyShape(0.5, 0.5),
          style: CharacterStyle(hairStyle: id),
        ));
        expect(tester.takeException(), isNull, reason: id);
      }
    }
  });
}

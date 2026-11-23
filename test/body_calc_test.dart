import 'package:flutter_test/flutter_test.dart';
import 'package:sogsal/logic/body_calc.dart';
import 'package:sogsal/models/models.dart';

BodyComposition body(double w, double muscle, double fat, {DateTime? date}) =>
    BodyComposition(
      date: date ?? DateTime(2026, 11, 23),
      weightKg: w,
      muscleKg: muscle,
      fatKg: fat,
      visceralLevel: 5,
      source: BodySource.inbody,
    );

void main() {
  group('미 해군법 체지방률', () {
    test('남성 기준값', () {
      final bf = BodyCalc.navyBodyFatPercent(
          gender: Gender.male, heightCm: 175, neckCm: 38, waistCm: 85)!;
      expect(bf, closeTo(17.3, 1.0));
    });
    test('여성 기준값', () {
      final bf = BodyCalc.navyBodyFatPercent(
          gender: Gender.female, heightCm: 162, neckCm: 32, waistCm: 72, hipCm: 94)!;
      expect(bf, closeTo(27.5, 1.5));
    });
    test('여성은 엉덩이 둘레가 없으면 계산하지 않는다', () {
      expect(
          BodyCalc.navyBodyFatPercent(
              gender: Gender.female, heightCm: 162, neckCm: 32, waistCm: 72),
          isNull);
    });
    test('말이 안 되는 치수는 null', () {
      expect(
          BodyCalc.navyBodyFatPercent(
              gender: Gender.male, heightCm: 175, neckCm: 90, waistCm: 80),
          isNull);
    });
  });

  group('체형 6종 분류', () {
    test('표준', () => expect(BodyCalc.classify(Gender.male, 175, body(70, 32, 11)), BodyType.standard));
    test('마른비만', () => expect(BodyCalc.classify(Gender.female, 162, body(54, 17.5, 17)), BodyType.skinnyFat));
    test('근육형', () => expect(BodyCalc.classify(Gender.male, 175, body(78, 38, 10)), BodyType.muscular));
    test('통통', () => expect(BodyCalc.classify(Gender.female, 162, body(70, 22, 25)), BodyType.chubby));
    test('근육돼지', () => expect(BodyCalc.classify(Gender.male, 175, body(95, 40, 24)), BodyType.muscleFat));
    test('저체중', () => expect(BodyCalc.classify(Gender.female, 165, body(46, 18, 9)), BodyType.underweight));
  });

  group('안전 가드', () {
    test('저체중 목표는 막는다', () {
      expect(BodyCalc.targetWeightWarning(165, 45), isNotNull);
      expect(BodyCalc.targetWeightWarning(165, 55), isNull);
    });
    test('급감량 경고', () {
      final recs = [
        body(70, 30, 15, date: DateTime(2026, 11, 16)),
        body(68, 29.5, 14, date: DateTime(2026, 11, 23)),
      ];
      expect(BodyCalc.rapidLossWarning(recs), isNotNull);
      final slow = [
        body(70, 30, 15, date: DateTime(2026, 11, 16)),
        body(69.6, 30, 14.6, date: DateTime(2026, 11, 23)),
      ];
      expect(BodyCalc.rapidLossWarning(slow), isNull);
    });
    test('칼로리 목표는 하한 아래로 내려가지 않는다', () {
      const p = UserProfile(
          gender: Gender.female, age: 30, heightCm: 150, targetWeightKg: 45,
          goal: Goal.lose, agreedDisclaimer: true);
      expect(BodyCalc.dailyCalories(p, 45), greaterThanOrEqualTo(1200));
    });
  });

  test('근육이 줄면 근육 손실 메시지', () {
    final msg = BodyCalc.changeMessage(body(70, 30, 15), body(69, 29.4, 14.8));
    expect(msg, contains('근육이가 줄었어요'));
  });
}

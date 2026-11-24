import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sogsal/logic/body_calc.dart';
import 'package:sogsal/models/models.dart';
import 'package:sogsal/widgets/body_comp_form.dart';

void main() {
  group('키·몸무게로 어림한 보통 체지방률', () {
    test('보통 체격이면 흔한 범위 안', () {
      final f = BodyCalc.standardFatPercent(gender: Gender.female, heightCm: 162, weightKg: 59, age: 29);
      final m = BodyCalc.standardFatPercent(gender: Gender.male, heightCm: 175, weightKg: 70, age: 30);
      expect(f, inInclusiveRange(25, 32));
      expect(m, inInclusiveRange(15, 22));
    });

    test('나이를 모르면 30살로 본다', () {
      expect(
        BodyCalc.standardFatPercent(gender: Gender.female, heightCm: 160, weightKg: 55),
        BodyCalc.standardFatPercent(gender: Gender.female, heightCm: 160, weightKg: 55, age: 30),
      );
    });

    test('말이 안 되는 값으로 튀지 않는다', () {
      expect(BodyCalc.standardFatPercent(gender: Gender.male, heightCm: 190, weightKg: 45, age: 18), 5);
      expect(BodyCalc.standardFatPercent(gender: Gender.female, heightCm: 150, weightKg: 140, age: 80), 48);
    });
  });

  Future<BodyComposition?> pumpForm(WidgetTester tester, {required void Function(BodyComposition) onSubmit}) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BodyCompForm(
            gender: Gender.female,
            heightCm: 162,
            age: 29,
            initialWeightKg: 59,
            submitLabel: '캐릭터 만들기',
            onSubmit: onSubmit,
          ),
        ),
      ),
    ));
    return null;
  }

  testWidgets('모르겠어요를 누르면 빈칸이 채워지고 추정값으로 저장된다', (tester) async {
    BodyComposition? got;
    await pumpForm(tester, onSubmit: (b) => got = b);
    await tester.tap(find.text('모르겠어요'));
    await tester.pump();
    expect(find.text('키와 몸무게로 채운 보통 값이에요. 아는 숫자가 있으면 고쳐 주세요.'), findsOneWidget);
    await tester.tap(find.text('캐릭터 만들기'));
    await tester.pump();
    expect(got, isNotNull);
    expect(got!.source, BodySource.estimate);
    expect(got!.fatPercent, closeTo(
        BodyCalc.standardFatPercent(gender: Gender.female, heightCm: 162, weightKg: 59, age: 29), 0.2));
  });

  testWidgets('이미 넣은 체지방은 그대로 두고 나머지만 채운다', (tester) async {
    BodyComposition? got;
    await pumpForm(tester, onSubmit: (b) => got = b);
    // 체지방량 칸에 직접 입력
    await tester.enterText(find.byType(TextField).at(2), '15');
    await tester.tap(find.text('모르겠어요'));
    await tester.pump();
    await tester.tap(find.text('캐릭터 만들기'));
    await tester.pump();
    expect(got!.fatKg, 15);
    expect(got!.muscleKg, closeTo(BodyCalc.estimateMuscleKg(Gender.female, 59, 15 / 59 * 100), 0.06));
  });

  testWidgets('채운 칸을 모두 고치면 실측으로 저장된다', (tester) async {
    BodyComposition? got;
    await pumpForm(tester, onSubmit: (b) => got = b);
    await tester.tap(find.text('모르겠어요'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '21');
    await tester.enterText(find.byType(TextField).at(2), '17');
    await tester.enterText(find.byType(TextField).at(3), '6');
    await tester.pump();
    await tester.tap(find.text('캐릭터 만들기'));
    await tester.pump();
    expect(got!.source, BodySource.inbody);
  });
}

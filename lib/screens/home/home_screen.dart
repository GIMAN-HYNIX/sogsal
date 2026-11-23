// 홈: 오늘의 체형, 캐릭터 말풍선, 부위 이름표 달린 캐릭터, 체성분표, 하루 목표.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/character.dart';
import '../../widgets/ui.dart';
import 'part_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.profile!, b = store.latest!;
    final type = store.bodyType!;
    final rapid = BodyCalc.rapidLossWarning(store.records);
    final message = rapid ?? BodyCalc.changeMessage(store.previous, b) ?? type.comment;
    final warn = rapid != null || type.isWarning;
    final now = DateTime.now();

    return Paper(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
              child: Row(
                children: [
                  const Expanded(child: Text('속살', style: Txt.h3)),
                  Text('${now.month}월 ${now.day}일', style: Txt.secondary),
                ],
              ),
            ),
            Text('오늘 내 몸은', style: Txt.secondary),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(type.label,
                      style: Txt.h1.copyWith(
                          fontSize: 48, color: type.isWarning ? Riso.error : Riso.ink)),
                ),
                const SizedBox(width: 10),
                if (b.isEstimate)
                  const Padding(padding: EdgeInsets.only(bottom: 8), child: EstimateTag()),
              ],
            ),
            const SizedBox(height: 14),
            // 캐릭터가 하는 말: 손으로 그린 말풍선, 꼬리는 아래 캐릭터 쪽
            SpeechBubble(text: message, warn: warn),
            const SizedBox(height: 4),
            GridPlate(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              caption: const Text('이름표를 누르면 그 부위 속을 볼 수 있어요.'),
              child: CharacterView(
                gender: p.gender,
                shape: store.shape,
                style: store.style,
                tired: type.isWarning,
                height: 340,
                onPartTap: (part) => showPartSheet(context, part),
              ),
            ),
            const SizedBox(height: 20),
            LabelTable(
              title: '체성분표',
              trailing: Text('${b.date.month}월 ${b.date.day}일 기록'),
              rows: [
                LabelRow('체중', b.weightKg.toStringAsFixed(1), unit: 'kg', strong: true),
                LabelRow('체지방량', b.fatKg.toStringAsFixed(1),
                    unit: 'kg', sub: '${b.fatPercent.toStringAsFixed(1)}%', swatch: Riso.yellow),
                LabelRow('내장지방 레벨', '${b.visceralLevel.round()}',
                    indent: true, swatch: Riso.orange),
                LabelRow('골격근량', b.muscleKg.toStringAsFixed(1), unit: 'kg', swatch: Riso.pink),
              ],
              footnote: b.isEstimate ? estimateNotice : '인바디로 잰 값이에요.',
            ),
            const SizedBox(height: 28),
            LabelTable(
              plain: true,
              title: '하루 목표',
              trailing: Text(p.goal.label),
              rows: [
                LabelRow('칼로리', '${BodyCalc.dailyCalories(p, b.weightKg)}', unit: 'kcal'),
                LabelRow('단백질', '${BodyCalc.dailyProteinG(p, b.weightKg)}', unit: 'g'),
              ],
            ),
            const SizedBox(height: 20),
            InkButton(
              label: '오늘 체중 기록',
              icon: Icons.add,
              onPressed: () => showWeightSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// 체중 빠른 기록 시트.
Future<void> showWeightSheet(BuildContext context) {
  final store = StoreScope.of(context);
  final c = TextEditingController(text: store.latest!.weightKg.toStringAsFixed(1));
  return showInkSheet(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final w = parseNum(c);
        final ok = w != null && w >= 25 && w <= 250;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('오늘 체중', style: Txt.h2),
              const SizedBox(height: 16),
              InkField(
                controller: c,
                label: '체중',
                unit: 'kg',
                helper: '지방·근육은 지난 기록 비율로 추정해요. 인바디를 쟀다면 체성분 기록에 넣어주세요.',
                onChanged: (_) => setState(() {}),
              ),
              InkButton(
                label: '기록하기',
                onPressed: ok
                    ? () {
                        store.addWeightOnly(w);
                        Navigator.pop(ctx);
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    ),
  );
}

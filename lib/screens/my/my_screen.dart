// 마이: 내 정보, 목표 수정, 체성분 다시 재기, 안내.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'recalibrate_screen.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.profile!, b = store.latest!;

    return Paper(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: '마이'),
            LabelTable(
              plain: true,
              title: '내 정보',
              rows: [
                LabelRow('성별', p.gender.label),
                LabelRow('나이', '${p.age}', unit: '세'),
                LabelRow('키', p.heightCm.toStringAsFixed(1), unit: 'cm'),
                LabelRow('목표', p.goal.label, strong: true),
                LabelRow('목표 체중', p.targetWeightKg.toStringAsFixed(1), unit: 'kg', indent: true),
                LabelRow('체성분 출처', b.isEstimate ? '줄자 추정' : '인바디'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Riso.sheet,
                border: Border.all(color: Riso.line),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  _Item(title: '목표 바꾸기', onTap: () => _showGoalSheet(context)),
                  const Divider(height: 1, thickness: 1, color: Riso.line),
                  _Item(
                    title: '체성분 다시 재기',
                    sub: '인바디를 쟀다면 실측값으로 바꿔요',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecalibrateScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle('알아두세요'),
            const Text(
              '이 앱은 진단이 아니라 참고용이에요. 몸속 그림과 부위별 숫자는 입력한 값으로 계산한 추정이에요. '
              '무리한 감량은 권하지 않아요. 건강 문제가 있으면 전문가와 상담하세요.',
              style: Txt.secondary,
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _confirmReset(context),
                style: TextButton.styleFrom(foregroundColor: Riso.error, padding: EdgeInsets.zero),
                child: const Text('모든 기록 지우기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final store = StoreScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모든 기록을 지울까요?'),
        content: const Text('프로필, 체성분 기록, 눈바디 사진이 모두 사라지고 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('그대로 두기')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              store.reset();
            },
            style: TextButton.styleFrom(foregroundColor: Riso.error),
            child: const Text('기록 지우기'),
          ),
        ],
      ),
    );
  }

  void _showGoalSheet(BuildContext context) {
    final store = StoreScope.of(context);
    final p = store.profile!;
    final c = TextEditingController(text: p.targetWeightKg.toStringAsFixed(1));
    var goal = p.goal;

    showInkSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final t = parseNum(c);
          final err = t == null ? null : BodyCalc.targetWeightWarning(p.heightCm, t);
          final ok = t != null && t <= 250 && err == null;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('목표 바꾸기', style: Txt.h2),
                const SizedBox(height: 16),
                ChoiceGroup<Goal>(
                  options: const [(Goal.lose, '살 빼기'), (Goal.maintain, '유지'), (Goal.muscle, '근육 늘리기')],
                  selected: goal,
                  onChanged: (g) => setState(() => goal = g),
                ),
                const SizedBox(height: 16),
                InkField(
                  controller: c,
                  label: '목표 체중',
                  unit: 'kg',
                  errorText: err,
                  onChanged: (_) => setState(() {}),
                ),
                InkButton(
                  label: '목표 저장',
                  onPressed: ok
                      ? () {
                          store.updateProfile(p.copyWith(goal: goal, targetWeightKg: t));
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
}

class _Item extends StatelessWidget {
  final String title;
  final String? sub;
  final VoidCallback onTap;

  const _Item({required this.title, this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Txt.bodyText),
                    if (sub != null) Text(sub!, style: Txt.secondary),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Riso.ink),
            ],
          ),
        ),
      );
}

// 부위 속 보기 하단 시트: 지방·근육 층 그림, 속 친구의 한마디, 부위 체성분표.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/cross_section.dart';
import '../../widgets/ui.dart';

Future<void> showPartSheet(BuildContext context, BodyPart part) {
  final store = StoreScope.of(context);
  return showInkSheet(context, (_) => _PartSheet(store: store, part: part));
}

class _PartSheet extends StatelessWidget {
  final AppStore store;
  final BodyPart part;
  const _PartSheet({required this.store, required this.part});

  @override
  Widget build(BuildContext context) {
    final p = store.profile!, b = store.latest!;
    final d = PartCalc.of(p.gender, b, part);
    final s = store.shape;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${part.label} 속', style: Txt.h2),
              const SizedBox(width: 8),
              const Padding(padding: EdgeInsets.only(bottom: 4), child: EstimateTag()),
            ],
          ),
          const SizedBox(height: 14),
          GridPlate(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            caption: Text(part == BodyPart.belly
                ? '살이 빠지면 노란 지방층과 주황 내장지방이 줄고, 근육이 붙으면 빨간 근육이 커져요.'
                : '살이 빠지면 노란 지방층이 얇아지고, 근육이 붙으면 빨간 근육이 커져요.'),
            child: LayoutBuilder(
              builder: (_, c) => Center(
                child: CrossSection(
                  part: part,
                  shape: s,
                  visceralLevel: d.visceralLevel,
                  female: p.gender == Gender.female,
                  skin: Color(store.style.skinColor),
                  width: c.maxWidth.clamp(240.0, 420.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(PartCalc.partComment(part, d, s), style: Txt.bodyText),
          const SizedBox(height: 16),
          LabelTable(
            title: '${part.label} 체성분',
            trailing: const Text('추정'),
            rows: [
              LabelRow('피하지방', d.subFatKg.toStringAsFixed(1), unit: 'kg', swatch: Riso.yellow),
              LabelRow('근육', d.muscleKg.toStringAsFixed(1), unit: 'kg', swatch: Riso.pink),
              if (d.visceralLevel != null)
                LabelRow('내장지방 레벨', '${d.visceralLevel!.round()}', swatch: Riso.orange),
            ],
            footnote: '전체 체성분을 부위별로 나눠 계산한 추정 그림이에요. 실제와 다를 수 있어요.',
          ),
        ],
      ),
    );
  }
}

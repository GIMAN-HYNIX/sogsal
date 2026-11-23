// 기록 탭: 체중·체성분 기록 추가와 지난 기록 목록.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import '../home/home_screen.dart' show showWeightSheet;
import '../my/recalibrate_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.records.reversed.toList();

    return Paper(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: '기록'),
            Row(
              children: [
                Expanded(
                  child: InkButton(
                    label: '체중',
                    icon: Icons.add,
                    onPressed: () => showWeightSheet(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkButton(
                    label: '체성분',
                    icon: Icons.add,
                    outlined: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecalibrateScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionTitle('지난 기록'),
            Container(
              decoration: BoxDecoration(
                color: Riso.sheet,
                border: Border.all(color: Riso.line),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1, color: Riso.line),
                    _RecordRow(list[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final BodyComposition r;
  const _RecordRow(this.r);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text('${r.date.month}/${r.date.day}', style: Txt.num),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '지방 ${r.fatKg.toStringAsFixed(1)}kg, 근육 ${r.muscleKg.toStringAsFixed(1)}kg',
                    style: Txt.secondary,
                  ),
                  const SizedBox(height: 2),
                  r.isEstimate
                      ? const Align(alignment: Alignment.centerLeft, child: EstimateTag())
                      : Text('인바디', style: Txt.meta.copyWith(color: Riso.good)),
                ],
              ),
            ),
            Text.rich(TextSpan(children: [
              TextSpan(text: r.weightKg.toStringAsFixed(1), style: Txt.num.copyWith(fontSize: 24)),
              const TextSpan(text: 'kg', style: Txt.secondary),
            ])),
          ],
        ),
      );
}

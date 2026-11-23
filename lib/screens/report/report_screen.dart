// 리포트: 기간 선택, 감량의 질(체성분표 모양), 체중·체지방·골격근·허리 그래프.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _days = 30; // 0 = 전체

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final all = store.records;
    final from = _days == 0 ? null : DateTime.now().subtract(Duration(days: _days));
    final list = from == null ? all : all.where((r) => r.date.isAfter(from)).toList();
    final waist = list.where((r) => r.waistCm != null).toList();

    return Paper(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: '리포트'),
            ChoiceGroup<int>(
              options: const [(7, '1주'), (30, '1달'), (90, '3달'), (0, '전체')],
              selected: _days,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: 20),
            if (list.length < 2)
              const _Empty()
            else ...[
              _Quality(list.first, list.last),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Riso.sheet,
                  border: Border.all(color: Riso.line),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    _Chart('체중', 'kg', Riso.ink, list, (r) => r.weightKg),
                    const Divider(height: 1, thickness: 1, color: Riso.line),
                    _Chart('체지방량', 'kg', const Color(0xFFE0A800), list, (r) => r.fatKg),
                    const Divider(height: 1, thickness: 1, color: Riso.line),
                    _Chart('골격근량', 'kg', Riso.pink, list, (r) => r.muscleKg),
                    if (waist.length >= 2) ...[
                      const Divider(height: 1, thickness: 1, color: Riso.line),
                      _Chart('허리둘레', 'cm', Riso.blue, waist, (r) => r.waistCm!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Riso.sheet,
          border: Border.all(color: Riso.line),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('그래프는 기록이 두 번 쌓이면 그려져요', style: Txt.h3),
            SizedBox(height: 6),
            Text('기록 탭에서 오늘 체중을 넣어보세요.', style: Txt.secondary),
          ],
        ),
      );
}

/// 감량의 질: 기간 동안 지방과 근육이 각각 얼마나 변했는지.
class _Quality extends StatelessWidget {
  final BodyComposition first, last;
  const _Quality(this.first, this.last);

  @override
  Widget build(BuildContext context) {
    final dFat = last.fatKg - first.fatKg;
    final dMus = last.muscleKg - first.muscleKg;
    final dW = last.weightKg - first.weightKg;
    final estimated = first.isEstimate || last.isEstimate;

    final String verdict;
    if (dFat < -0.2 && dMus > -0.2) {
      verdict = '지방 위주로 빠지고 있어요. 좋은 감량이에요.';
    } else if (dMus <= -0.3 && dMus.abs() >= dFat.abs() * 0.5) {
      verdict = '근육도 같이 빠지고 있어요. 단백질과 근력운동을 챙겨요.';
    } else if (dMus > 0.2 && dFat <= 0.2) {
      verdict = '근육이 늘고 있어요.';
    } else if (dFat > 0.3) {
      verdict = '지방이 조금 늘었어요. 천천히 되돌려봐요.';
    } else {
      verdict = '큰 변화 없이 유지하고 있어요.';
    }

    String fmt(double v) => '${v >= 0 ? '+' : '−'}${v.abs().toStringAsFixed(1)}';
    Color? tone(double v, {required bool goodWhenDown}) {
      if (v.abs() < 0.05) return null;
      final good = goodWhenDown ? v < 0 : v > 0;
      return good ? Riso.good : Riso.error;
    }

    return LabelTable(
      title: '감량의 질',
      trailing: Text('${first.date.month}/${first.date.day}부터 ${last.date.month}/${last.date.day}까지'),
      rows: [
        LabelRow('체중', fmt(dW), unit: 'kg', strong: true),
        LabelRow('지방', fmt(dFat),
            unit: 'kg', swatch: Riso.yellow, valueColor: tone(dFat, goodWhenDown: true)),
        LabelRow('근육', fmt(dMus),
            unit: 'kg', swatch: Riso.pink, valueColor: tone(dMus, goodWhenDown: false)),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(verdict, style: Txt.bodyText),
          if (estimated) ...[
            const SizedBox(height: 4),
            const Text('추정값이 섞여 있어요. 인바디로 재면 더 정확해요.', style: Txt.meta),
          ],
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final String title, unit;
  final Color color;
  final List<BodyComposition> list;
  final double Function(BodyComposition) pick;

  const _Chart(this.title, this.unit, this.color, this.list, this.pick);

  @override
  Widget build(BuildContext context) {
    final t0 = list.first.date;
    final spots = [
      for (final r in list) FlSpot(r.date.difference(t0).inHours / 24.0, pick(r)),
    ];
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) < 1 ? 1.0 : (maxY - minY) * 0.25;
    final maxX = spots.last.x <= 0 ? 1.0 : spots.last.x;
    final change = pick(list.last) - pick(list.first);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 10, height: 10, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Txt.label)),
              Text(
                '${change >= 0 ? '+' : '−'}${change.abs().toStringAsFixed(1)}',
                style: Txt.secondary,
              ),
              const SizedBox(width: 10),
              Text.rich(TextSpan(children: [
                TextSpan(text: pick(list.last).toStringAsFixed(1), style: Txt.num.copyWith(fontSize: 24)),
                TextSpan(text: unit, style: Txt.secondary),
              ])),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: minY - pad,
                maxY: maxY + pad,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY + pad) - (minY - pad)) / 3,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Riso.line, strokeWidth: 1, dashArray: [2, 4]),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(bottom: BorderSide(color: Riso.ink, width: 1.5)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: maxX,
                      getTitlesWidget: (v, meta) {
                        final d = t0.add(Duration(hours: (v * 24).round()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${d.month}/${d.day}', style: Txt.meta),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Riso.ink,
                    getTooltipItems: (items) => [
                      for (final i in items)
                        LineTooltipItem(
                          '${i.y.toStringAsFixed(1)}$unit',
                          const TextStyle(
                              fontFamily: Txt.body, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 2.5,
                    isCurved: false,
                    // 마지막(오늘) 점만 찍는다
                    dotData: FlDotData(
                      checkToShowDot: (s, bar) => s == bar.spots.last,
                      getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

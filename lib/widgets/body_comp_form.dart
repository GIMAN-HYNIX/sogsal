// 체성분 입력 폼. 온보딩 2단계와 체성분 기록(재보정)에서 같이 쓴다.
import 'package:flutter/material.dart';

import '../logic/body_calc.dart';
import '../models/models.dart';
import '../theme.dart';
import 'ui.dart';

class BodyCompForm extends StatefulWidget {
  final Gender gender;
  final double heightCm;
  final double? initialWeightKg;
  final bool inbodyFirst;
  final String submitLabel;
  final ValueChanged<BodyComposition> onSubmit;

  const BodyCompForm({
    super.key,
    required this.gender,
    required this.heightCm,
    required this.onSubmit,
    required this.submitLabel,
    this.initialWeightKg,
    this.inbodyFirst = true,
  });

  @override
  State<BodyCompForm> createState() => _BodyCompFormState();
}

class _BodyCompFormState extends State<BodyCompForm> {
  late bool _inbody = widget.inbodyFirst;
  bool _fatAsPercent = false;

  late final _weight = TextEditingController(
      text: widget.initialWeightKg?.toStringAsFixed(1) ?? '');
  final _muscle = TextEditingController();
  final _fat = TextEditingController();
  final _visceral = TextEditingController();
  final _neck = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();

  @override
  void dispose() {
    for (final c in [_weight, _muscle, _fat, _visceral, _neck, _waist, _hip]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _female => widget.gender == Gender.female;

  /// 지금 입력으로 만들 수 있는 결과. 부족하면 null.
  BodyComposition? get _result {
    final w = parseNum(_weight);
    if (w == null || w < 25 || w > 250) return null;

    if (_inbody) {
      final m = parseNum(_muscle);
      final f = parseNum(_fat);
      if (m == null || f == null || m <= 0 || f <= 0) return null;
      final fatKg = _fatAsPercent ? w * f / 100 : f;
      if (fatKg >= w || m >= w || fatKg + m >= w) return null;
      final fp = fatKg / w * 100;
      final v = parseNum(_visceral);
      return BodyComposition(
        date: DateTime.now(),
        weightKg: w,
        muscleKg: m,
        fatKg: fatKg,
        visceralLevel: (v != null && v >= 1 && v <= 20)
            ? v
            : BodyCalc.estimateVisceralLevel(
                gender: widget.gender, fatPercent: fp),
        source: BodySource.inbody,
      );
    }

    final neck = parseNum(_neck), waist = parseNum(_waist), hip = parseNum(_hip);
    if (neck == null || waist == null) return null;
    final bf = BodyCalc.navyBodyFatPercent(
      gender: widget.gender,
      heightCm: widget.heightCm,
      neckCm: neck,
      waistCm: waist,
      hipCm: hip,
    );
    if (bf == null) return null;
    return BodyComposition(
      date: DateTime.now(),
      weightKg: w,
      muscleKg: BodyCalc.estimateMuscleKg(widget.gender, w, bf),
      fatKg: w * bf / 100,
      visceralLevel: BodyCalc.estimateVisceralLevel(
          gender: widget.gender, fatPercent: bf, waistCm: waist),
      waistCm: waist,
      source: BodySource.estimate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    void refresh(String _) => setState(() {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceGroup<bool>(
          options: const [(true, '인바디 결과가 있어요'), (false, '줄자로 잴게요')],
          selected: _inbody,
          onChanged: (v) => setState(() => _inbody = v),
        ),
        const SizedBox(height: 8),
        Text(
          _inbody
              ? '인바디 결과지에 적힌 숫자를 그대로 옮겨 주세요.'
              : '목·허리·엉덩이 둘레로 체지방률을 계산해요. 정확도는 인바디보다 낮아요.',
          style: Txt.secondary,
        ),
        const SizedBox(height: 20),
        InkField(controller: _weight, label: '체중', unit: 'kg', onChanged: refresh),
        if (_inbody) ...[
          InkField(controller: _muscle, label: '골격근량', unit: 'kg', onChanged: refresh),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: InkField(
                  controller: _fat,
                  label: _fatAsPercent ? '체지방률' : '체지방량',
                  unit: _fatAsPercent ? '%' : 'kg',
                  onChanged: refresh,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: TextButton(
                  onPressed: () => setState(() {
                    _fatAsPercent = !_fatAsPercent;
                    _fat.clear();
                  }),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 50)),
                  child: Text(_fatAsPercent ? 'kg로 입력' : '%로 입력'),
                ),
              ),
            ],
          ),
          InkField(
            controller: _visceral,
            label: '내장지방 레벨',
            unit: '1~20',
            helper: '결과지에 없으면 비워두세요. 대신 추정해요.',
            integer: true,
            onChanged: refresh,
          ),
        ] else ...[
          InkField(
            controller: _neck,
            label: '목 둘레',
            unit: 'cm',
            helper: '목젖 바로 아래를 수평으로 재요.',
            onChanged: refresh,
          ),
          InkField(
            controller: _waist,
            label: '허리 둘레',
            unit: 'cm',
            helper: '배꼽 높이에서, 숨을 편하게 내쉰 상태로 재요.',
            onChanged: refresh,
          ),
          InkField(
            controller: _hip,
            label: _female ? '엉덩이 둘레' : '엉덩이 둘레 (안 재도 돼요)',
            unit: 'cm',
            helper: '가장 튀어나온 곳을 수평으로 재요.',
            onChanged: refresh,
          ),
        ],
        if (r != null) ...[
          const SizedBox(height: 4),
          LabelTable(
            title: '체성분표',
            trailing: r.isEstimate ? const EstimateTag() : const Text('인바디 실측'),
            rows: [
              LabelRow('체중', r.weightKg.toStringAsFixed(1), unit: 'kg', strong: true),
              LabelRow('체지방량', r.fatKg.toStringAsFixed(1),
                  unit: 'kg', sub: '${r.fatPercent.toStringAsFixed(1)}%', swatch: Riso.yellow),
              LabelRow('골격근량', r.muscleKg.toStringAsFixed(1), unit: 'kg', swatch: Riso.pink),
            ],
            footnote: r.isEstimate ? estimateNotice : null,
          ),
        ],
        const SizedBox(height: 20),
        InkButton(
          label: widget.submitLabel,
          onPressed: r == null ? null : () => widget.onSubmit(r),
        ),
        if (r == null)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('칸을 다 채우면 눌러져요.',
                textAlign: TextAlign.center, style: Txt.meta),
          ),
      ],
    );
  }
}

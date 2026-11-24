// 체성분 입력 폼. 온보딩 2단계와 체성분 기록(재보정)에서 같이 쓴다.
import 'package:flutter/material.dart';

import '../logic/body_calc.dart';
import '../models/models.dart';
import '../theme.dart';
import 'ui.dart';

class BodyCompForm extends StatefulWidget {
  final Gender gender;
  final double heightCm;
  final int? age;
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
    this.age,
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
  // '모르겠어요'로 채운 칸. 사용자가 고치면 빠진다. 하나라도 남아 있으면 추정값으로 저장한다.
  final _guessed = <TextEditingController>{};

  @override
  void dispose() {
    for (final c in [_weight, _muscle, _fat, _visceral, _neck, _waist, _hip]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _female => widget.gender == Gender.female;

  double? get _weightKg {
    final w = parseNum(_weight);
    return (w == null || w < 25 || w > 250) ? null : w;
  }

  /// 채울 칸이 남았는지 (줄자 쪽에서 누르면 숫자 칸으로 넘어가 채운다)
  bool get _canFill =>
      !_inbody || parseNum(_muscle) == null || parseNum(_fat) == null || parseNum(_visceral) == null;

  /// 모르겠어요: 비어 있는 칸만 키·몸무게로 어림한 보통 값으로 채운다. 이미 넣은 숫자는 그대로 둔다.
  void _fillStandard() {
    final w = _weightKg;
    if (w == null) return;
    setState(() {
      _inbody = true;
      final f = parseNum(_fat);
      final double fp;
      if (f == null || f <= 0) {
        fp = BodyCalc.standardFatPercent(
            gender: widget.gender, heightCm: widget.heightCm, weightKg: w, age: widget.age);
        _fat.text = (_fatAsPercent ? fp : w * fp / 100).toStringAsFixed(1);
        _guessed.add(_fat);
      } else {
        fp = _fatAsPercent ? f : f / w * 100;
      }
      if (parseNum(_muscle) == null) {
        _muscle.text = BodyCalc.estimateMuscleKg(widget.gender, w, fp).toStringAsFixed(1);
        _guessed.add(_muscle);
      }
      if (parseNum(_visceral) == null) {
        _visceral.text =
            BodyCalc.estimateVisceralLevel(gender: widget.gender, fatPercent: fp).round().toString();
        _guessed.add(_visceral);
      }
    });
  }

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
        source: _guessed.isEmpty ? BodySource.inbody : BodySource.estimate,
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
    // 채운 칸을 사용자가 고치면 '모르겠어요' 표시에서 뺀다
    ValueChanged<String> edited(TextEditingController c) => (_) => setState(() => _guessed.remove(c));
    final guessing = _inbody && _guessed.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceGroup<bool>(
          options: const [(true, '숫자를 알아요'), (false, '줄자로 잴게요')],
          selected: _inbody,
          onChanged: (v) => setState(() => _inbody = v),
        ),
        const SizedBox(height: 8),
        Text(
          guessing
              ? '키와 몸무게로 채운 보통 값이에요. 아는 숫자가 있으면 고쳐 주세요.'
              : _inbody
                  ? '인바디나 체성분 체중계에 나온 숫자를 넣어 주세요.'
                  : '목·허리·엉덩이 둘레로 체지방률을 계산해요. 정확도는 인바디보다 낮아요.',
          style: Txt.secondary,
        ),
        const SizedBox(height: 20),
        InkField(controller: _weight, label: '체중', unit: 'kg', onChanged: refresh),
        if (_inbody) ...[
          InkField(controller: _muscle, label: '골격근량', unit: 'kg', onChanged: edited(_muscle)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: InkField(
                  controller: _fat,
                  label: _fatAsPercent ? '체지방률' : '체지방량',
                  unit: _fatAsPercent ? '%' : 'kg',
                  onChanged: edited(_fat),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: TextButton(
                  onPressed: () => setState(() {
                    _fatAsPercent = !_fatAsPercent;
                    _fat.clear();
                    _guessed.remove(_fat);
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
            onChanged: edited(_visceral),
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
        // 세부 숫자를 모를 때: 키·몸무게로 보통 값 채우기. 채울 빈칸이 없으면 숨긴다
        if (_canFill) ...[
          InkButton(
            label: '모르겠어요',
            icon: Icons.help_outline,
            outlined: true,
            onPressed: _weightKg != null ? _fillStandard : null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Text(
              _weightKg == null ? '체중을 먼저 넣으면 눌러져요.' : '빈칸을 키와 몸무게로 어림한 보통 값으로 채워요. 넣은 숫자는 그대로 둬요.',
              style: Txt.secondary,
            ),
          ),
        ],
        if (r != null) ...[
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

// 온보딩 3단계: 기본 정보 → 체성분 → 내 캐릭터.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/body_comp_form.dart';
import '../../widgets/character.dart';
import '../../widgets/ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  Gender _gender = Gender.female;
  Goal _goal = Goal.lose;
  bool _agreed = false;
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _target = TextEditingController();

  UserProfile? _profile;
  BodyComposition? _body;

  static const _titles = ['나에 대해 알려주세요', '몸속을 재볼게요', '내 몸속 친구들'];

  @override
  void dispose() {
    for (final c in [_age, _height, _weight, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _targetError {
    final h = parseNum(_height), t = parseNum(_target);
    if (h == null || t == null || h < 100) return null;
    return BodyCalc.targetWeightWarning(h, t);
  }

  bool get _basicValid {
    final a = parseNum(_age), h = parseNum(_height);
    final w = parseNum(_weight), t = parseNum(_target);
    return a != null && a >= 14 && a <= 100 &&
        h != null && h >= 120 && h <= 220 &&
        w != null && w >= 25 && w <= 250 &&
        t != null && t >= 25 && t <= 250 &&
        _targetError == null &&
        _agreed;
  }

  void _submitBasic() {
    _profile = UserProfile(
      gender: _gender,
      age: parseNum(_age)!.round(),
      heightCm: parseNum(_height)!,
      targetWeightKg: parseNum(_target)!,
      goal: _goal,
      agreedDisclaimer: true,
    );
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: Paper(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _StepHeader(
                      step: _step,
                      onBack: _step > 0 ? () => setState(() => _step--) : null,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_titles[_step], style: Txt.h2),
                            const SizedBox(height: 24),
                            switch (_step) {
                              0 => _basic(),
                              1 => BodyCompForm(
                                  gender: _profile!.gender,
                                  heightCm: _profile!.heightCm,
                                  initialWeightKg: parseNum(_weight),
                                  submitLabel: '캐릭터 만들기',
                                  onSubmit: (b) => setState(() {
                                    _body = b;
                                    _step = 2;
                                  }),
                                ),
                              _ => _result(),
                            },
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _basic() {
    void refresh(String _) => setState(() {});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('성별', style: Txt.label),
        const SizedBox(height: 6),
        ChoiceGroup<Gender>(
          options: [for (final g in Gender.values) (g, g.label)],
          selected: _gender,
          onChanged: (g) => setState(() => _gender = g),
        ),
        const SizedBox(height: 20),
        InkField(
          controller: _age,
          label: '나이',
          unit: '세',
          integer: true,
          helper: '칼로리 계산에만 써요. 캐릭터 모습에는 안 들어가요.',
          onChanged: refresh,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: InkField(controller: _height, label: '키', unit: 'cm', onChanged: refresh)),
            const SizedBox(width: 12),
            Expanded(
                child: InkField(controller: _weight, label: '지금 체중', unit: 'kg', onChanged: refresh)),
          ],
        ),
        InkField(
          controller: _target,
          label: '목표 체중',
          unit: 'kg',
          errorText: _targetError,
          onChanged: refresh,
        ),
        const Text('목표', style: Txt.label),
        const SizedBox(height: 6),
        ChoiceGroup<Goal>(
          options: const [(Goal.lose, '살 빼기'), (Goal.maintain, '유지'), (Goal.muscle, '근육 늘리기')],
          selected: _goal,
          onChanged: (g) => setState(() => _goal = g),
        ),
        const SizedBox(height: 24),
        _Agreement(value: _agreed, onChanged: (v) => setState(() => _agreed = v)),
        const SizedBox(height: 24),
        InkButton(label: '다음', onPressed: _basicValid ? _submitBasic : null),
      ],
    );
  }

  Widget _result() {
    final p = _profile!, b = _body!;
    final type = BodyCalc.classify(p.gender, p.heightCm, b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridPlate(
          child: Center(
            child: CharacterView(
              gender: p.gender,
              shape: BodyCalc.shapeOf(p.gender, p.heightCm, b),
              style: const CharacterStyle(),
              tired: type.isWarning,
              height: 280,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(type.label,
                style: Txt.h1.copyWith(color: type.isWarning ? Riso.error : Riso.ink)),
            const SizedBox(width: 10),
            if (b.isEstimate)
              const Padding(padding: EdgeInsets.only(bottom: 6), child: EstimateTag()),
          ],
        ),
        const SizedBox(height: 8),
        Text(type.comment, style: Txt.bodyText),
        if (b.isEstimate) ...[
          const SizedBox(height: 6),
          const Text(estimateNotice, style: Txt.secondary),
        ],
        const SizedBox(height: 28),
        InkButton(
          label: '시작하기',
          onPressed: () => StoreScope.of(context).completeOnboarding(p, b),
        ),
        const SizedBox(height: 10),
        const Text('머리·옷 색은 꾸미기 탭에서 바꿀 수 있어요.',
            textAlign: TextAlign.center, style: Txt.meta),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  const _StepHeader({required this.step, this.onBack});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              child: onBack == null
                  ? null
                  : IconButton(
                      tooltip: '이전 단계',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Riso.ink),
                    ),
            ),
            const Spacer(),
            Semantics(
              label: '3단계 중 ${step + 1}단계',
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 22,
                      height: 8,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: i <= step ? Riso.ink : Colors.transparent,
                        border: Border.all(color: Riso.ink, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      );
}

class _Agreement extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Agreement({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Semantics(
        checked: value,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Riso.sheet,
              border: Border.all(color: value ? Riso.ink : Riso.lineStrong, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: value ? Riso.ink : Riso.sheet,
                    border: Border.all(color: Riso.ink, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('진단이 아니라 참고용이라는 걸 알아요', style: Txt.label),
                      SizedBox(height: 4),
                      Text(
                        '몸속 그림은 입력한 숫자로 계산한 추정이에요. 건강 문제가 있으면 전문가와 상담하세요.',
                        style: Txt.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

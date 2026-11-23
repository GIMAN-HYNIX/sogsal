// 꾸미기: 머리 모양, 머리 색, 피부색, 속옷 색. 눈바디로 몸 맞추기로 가는 길도 여기 있다.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/character.dart';
import '../../widgets/ui.dart';
import '../noonbody/noonbody_screen.dart';

// 리소 잉크 이름을 빌린 색 견본
const _hairInks = [
  (0xFF1E2346, '먹'),
  (0xFF8A5A44, '밤색'),
  (0xFFE0A800, '겨자'),
  (0xFFFF4FA3, '형광 핑크'),
  (0xFF3A6FD8, '파랑'),
  (0xFF00A19A, '청록'),
];
const _skinInks = [
  (0xFFFBDCC8, '밝은 톤'),
  (CharacterStyle.defaultSkin, '기본'),
  (0xFFEDB592, '살구'),
  (0xFFDDA27A, '밀색'),
  (0xFFC0835A, '갈색'),
  (0xFF8F5B3D, '진한 갈색'),
];
const _outfitInks = [
  (0xFF3A6FD8, '파랑'),
  (0xFF00A19A, '청록'),
  (0xFFFF6B35, '주황'),
  (0xFFFFCF33, '노랑'),
  (0xFF8D6CC9, '보라'),
  (0xFF1E2346, '먹'),
];

class DecorateScreen extends StatelessWidget {
  const DecorateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final s = store.style;
    final g = store.profile!.gender;

    return Paper(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const ScreenHeader(title: '꾸미기'),
            GridPlate(
              child: Center(
                child: CharacterView(
                  gender: g,
                  shape: store.shape,
                  style: s,
                  tweak: store.tweak,
                  tired: store.bodyType!.isWarning,
                  height: 280,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkButton(
              label: '눈바디 사진으로 몸 맞추기',
              icon: Icons.photo_camera_outlined,
              outlined: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoonbodyScreen()),
              ),
            ),
            const SizedBox(height: 24),
            _HairPicker(
              gender: g,
              shape: store.shape,
              style: s,
              onPick: (id) => store.updateStyle(s.copyWith(hairStyle: id)),
            ),
            const SizedBox(height: 24),
            _Swatches(
              title: '머리 색',
              inks: _hairInks,
              selected: s.hairColor,
              onPick: (c) => store.updateStyle(s.copyWith(hairColor: c)),
            ),
            const SizedBox(height: 24),
            _Swatches(
              title: '피부색',
              inks: _skinInks,
              selected: s.skinColor,
              onPick: (c) => store.updateStyle(s.copyWith(skinColor: c)),
            ),
            const SizedBox(height: 24),
            _Swatches(
              title: '속옷 색',
              inks: _outfitInks,
              selected: s.outfitColor,
              onPick: (c) => store.updateStyle(s.copyWith(outfitColor: c)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 머리 모양: 얼굴 그림 10개, 5칸 2줄
class _HairPicker extends StatelessWidget {
  final Gender gender;
  final BodyShape shape;
  final CharacterStyle style;
  final ValueChanged<String> onPick;

  const _HairPicker({required this.gender, required this.shape, required this.style, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final list = HairStyles.of(gender);
    final current = HairStyles.resolve(gender, style.hairStyle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('머리 모양', trailing: Text(HairStyles.label(gender, current), style: Txt.secondary)),
        LayoutBuilder(builder: (context, c) {
          const gap = 8.0, cols = 5;
          final size = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (id, name) in list)
                Semantics(
                  button: true,
                  selected: id == current,
                  label: '머리 모양 $name',
                  excludeSemantics: true,
                  child: Tooltip(
                    message: name,
                    child: InkWell(
                      onTap: () => onPick(id),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Riso.sheet,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: id == current ? Riso.ink : Riso.line,
                            width: id == current ? 2.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CharacterHead(
                          gender: gender,
                          shape: shape,
                          style: style.copyWith(hairStyle: id),
                          size: size,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  final String title;
  final List<(int, String)> inks;
  final int selected;
  final ValueChanged<int> onPick;

  const _Swatches({
    required this.title,
    required this.inks,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title,
              trailing: Text(
                inks.firstWhere((e) => e.$1 == selected, orElse: () => (0, '')).$2,
                style: Txt.secondary,
              )),
          LayoutBuilder(builder: (context, c) {
            const gap = 8.0;
            final size = ((c.maxWidth - gap * (inks.length - 1)) / inks.length).clamp(44.0, 64.0);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final (color, name) in inks)
                  Semantics(
                    button: true,
                    selected: color == selected,
                    label: '$title $name',
                    child: InkWell(
                      onTap: () => onPick(color),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Color(color),
                          border: Border.all(
                            color: color == selected ? Riso.ink : Riso.line,
                            width: color == selected ? 3 : 1,
                          ),
                        ),
                        child: color == selected
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  color: Colors.white,
                                  child: const Icon(Icons.check, size: 16, color: Riso.ink),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      );
}

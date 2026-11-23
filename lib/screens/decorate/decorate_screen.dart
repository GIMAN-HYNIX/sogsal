// 꾸미기. 지금은 머리·옷 잉크 색만. 헤어·의상·소품 아이템은 캐릭터 그림이 나오면 추가한다.
import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../logic/body_calc.dart';
import '../../theme.dart';
import '../../widgets/character.dart';
import '../../widgets/ui.dart';

// 리소 잉크 이름을 빌린 색 견본
const _hairInks = [
  (0xFF1E2346, '먹'),
  (0xFF8A5A44, '밤색'),
  (0xFFE0A800, '겨자'),
  (0xFFFF4FA3, '형광 핑크'),
  (0xFF3A6FD8, '파랑'),
  (0xFF00A19A, '청록'),
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
                  gender: store.profile!.gender,
                  shape: store.shape,
                  style: s,
                  tired: store.bodyType!.isWarning,
                  height: 280,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _Swatches(
              title: '머리',
              inks: _hairInks,
              selected: s.hairColor,
              onPick: (c) => store.updateStyle(s.copyWith(hairColor: c)),
            ),
            const SizedBox(height: 24),
            _Swatches(
              title: '속옷',
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

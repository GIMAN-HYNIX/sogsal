// 눈바디: 몸 사진을 넣고, 사진을 보면서 부위별 막대로 캐릭터 몸을 맞춘다.
// 사진은 자동 분석하지 않는다. 폰 밖으로 보내지 않고 기기 저장소에만 둔다.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/store.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/character.dart';
import '../../widgets/ui.dart';

class NoonbodyScreen extends StatefulWidget {
  const NoonbodyScreen({super.key});

  @override
  State<NoonbodyScreen> createState() => _NoonbodyScreenState();
}

class _NoonbodyScreenState extends State<NoonbodyScreen> {
  final _bytes = <String, Uint8List>{}; // 사진 id → 풀어둔 바이트
  String? _selected;
  BodyTweak? _draft; // 막대를 움직이는 중인 값
  bool _picking = false;

  Uint8List _img(BodyPhoto p) => _bytes.putIfAbsent(p.id, () => base64Decode(p.jpegBase64));

  Future<void> _pick(AppStore store) async {
    setState(() => _picking = true);
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 1200,
        imageQuality: 78,
      );
      if (x == null) return;
      final data = await x.readAsBytes();
      final ok = await store.addPhoto(base64Encode(data));
      if (!mounted) return;
      if (ok) {
        setState(() => _selected = store.photos.last.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('사진을 저장할 공간이 모자라요. 예전 사진을 지우고 다시 넣어주세요.'),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('사진을 불러오지 못했어요. 다른 사진으로 다시 해보세요.'),
      ));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _confirmDelete(AppStore store, BodyPhoto p) {
    final name = '${p.date.month}월 ${p.date.day}일 사진';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name을 지울까요?'),
        content: const Text('이 폰에서 완전히 지워지고 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('그대로 두기')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bytes.remove(p.id);
              setState(() => _selected = null);
              store.deletePhoto(p.id);
            },
            style: TextButton.styleFrom(foregroundColor: Riso.error),
            child: const Text('사진 지우기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final photos = store.photos;
    final current = photos.isEmpty
        ? null
        : photos.firstWhere((p) => p.id == _selected, orElse: () => photos.last);
    final tweak = _draft ?? store.tweak;

    return Scaffold(
      body: Paper(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: const Offset(-12, 0),
                        child: IconButton(
                          tooltip: '뒤로',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Riso.ink),
                        ),
                      ),
                    ),
                  ),
                  const Text('눈바디', style: Txt.h2),
                  const SizedBox(height: 6),
                  const Text('사진은 이 폰에만 저장되고, 어디에도 보내지 않아요.', style: Txt.secondary),
                  const SizedBox(height: 20),
                  _SideBySide(
                    photo: current == null ? null : _img(current),
                    date: current?.date,
                    busy: _picking,
                    onAdd: () => _pick(store),
                    character: CharacterView(
                      gender: store.profile!.gender,
                      shape: store.shape,
                      style: store.style,
                      tweak: tweak,
                      height: 300,
                    ),
                  ),
                  if (current != null) ...[
                    const SizedBox(height: 12),
                    _PhotoStrip(
                      photos: photos,
                      selectedId: current.id,
                      bytesOf: _img,
                      busy: _picking,
                      onAdd: () => _pick(store),
                      onSelect: (p) => setState(() => _selected = p.id),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(store, current),
                        style: TextButton.styleFrom(foregroundColor: Riso.error),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: Text('${current.date.month}월 ${current.date.day}일 사진 지우기'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SectionTitle('캐릭터 몸 맞추기',
                      trailing: tweak.isNone
                          ? null
                          : TextButton(
                              onPressed: () {
                                setState(() => _draft = null);
                                store.updateTweak(BodyTweak.none);
                              },
                              child: const Text('숫자대로 되돌리기'),
                            )),
                  const Text(
                    '사진을 자동으로 읽지는 않아요. 사진을 보면서 막대를 움직이면 캐릭터가 바로 바뀌고, 손을 떼면 저장돼요.',
                    style: Txt.secondary,
                  ),
                  const SizedBox(height: 12),
                  _TweakPanel(
                    value: tweak,
                    onChanged: (t) => setState(() => _draft = t),
                    onChangeEnd: (t) {
                      store.updateTweak(t);
                      setState(() => _draft = null);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 사진이 아직 없을 때 왼쪽 칸
class _AddPhoto extends StatelessWidget {
  final bool busy;
  final VoidCallback onAdd;
  const _AddPhoto({required this.busy, required this.onAdd});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '몸 사진 넣기',
        excludeSemantics: true,
        child: Material(
          color: Riso.sheet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Riso.lineStrong),
          ),
          child: InkWell(
            onTap: busy ? null : onAdd,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  busy
                      ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Icon(Icons.add_photo_alternate_outlined, size: 32, color: Riso.ink),
                  const SizedBox(height: 10),
                  Text(busy ? '불러오는 중' : '몸 사진 넣기', style: Txt.label),
                  const SizedBox(height: 6),
                  const Text('거울 앞 정면, 몸선이 보이는 옷이면 맞추기 쉬워요.',
                      style: Txt.secondary, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}

/// 사진과 캐릭터를 나란히
class _SideBySide extends StatelessWidget {
  final Uint8List? photo;
  final DateTime? date;
  final bool busy;
  final VoidCallback onAdd;
  final Widget character;
  const _SideBySide({
    required this.photo,
    required this.date,
    required this.busy,
    required this.onAdd,
    required this.character,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 320,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: photo == null
                  ? _AddPhoto(busy: busy, onAdd: onAdd)
                  : Container(
                      decoration: BoxDecoration(
                        color: Riso.sheet,
                        border: Border.all(color: Riso.line),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        image: true,
                        label: '${date!.month}월 ${date!.day}일 눈바디 사진',
                        child: Image.memory(photo!, fit: BoxFit.contain, gaplessPlayback: true),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GridPlate(
                padding: const EdgeInsets.all(4),
                child: Center(child: FittedBox(child: character)),
              ),
            ),
          ],
        ),
      );
}

class _PhotoStrip extends StatelessWidget {
  final List<BodyPhoto> photos;
  final String selectedId;
  final Uint8List Function(BodyPhoto) bytesOf;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<BodyPhoto> onSelect;

  const _PhotoStrip({
    required this.photos,
    required this.selectedId,
    required this.bytesOf,
    required this.busy,
    required this.onAdd,
    required this.onSelect,
  });

  static const _w = 60.0, _h = 76.0;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _h + 22,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Semantics(
              button: true,
              label: '사진 넣기',
              child: InkWell(
                onTap: busy ? null : onAdd,
                child: Container(
                  width: _w,
                  height: _h,
                  decoration: BoxDecoration(
                    color: Riso.sheet,
                    border: Border.all(color: Riso.lineStrong),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: busy
                      ? const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : const Icon(Icons.add, color: Riso.ink),
                ),
              ),
            ),
            for (final p in photos.reversed) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                selected: p.id == selectedId,
                label: '${p.date.month}월 ${p.date.day}일 사진',
                child: InkWell(
                  onTap: () => onSelect(p),
                  child: Column(
                    children: [
                      Container(
                        width: _w,
                        height: _h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: p.id == selectedId ? Riso.ink : Riso.line,
                            width: p.id == selectedId ? 2.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(bytesOf(p), fit: BoxFit.cover, gaplessPlayback: true),
                      ),
                      const SizedBox(height: 4),
                      Text('${p.date.month}/${p.date.day}', style: Txt.meta),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// 부위별 막대 다섯 개
class _TweakPanel extends StatelessWidget {
  final BodyTweak value;
  final ValueChanged<BodyTweak> onChanged, onChangeEnd;
  const _TweakPanel({required this.value, required this.onChanged, required this.onChangeEnd});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String, double, BodyTweak Function(double))>[
      ('어깨', '좁게', '넓게', value.shoulder, (v) => value.copyWith(shoulder: v)),
      ('허리', '가늘게', '굵게', value.waist, (v) => value.copyWith(waist: v)),
      ('골반', '좁게', '넓게', value.hip, (v) => value.copyWith(hip: v)),
      ('팔', '가늘게', '굵게', value.arm, (v) => value.copyWith(arm: v)),
      ('허벅지', '가늘게', '굵게', value.thigh, (v) => value.copyWith(thigh: v)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Riso.sheet,
        border: Border.all(color: Riso.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: Riso.line),
            _TweakRow(
              label: rows[i].$1,
              low: rows[i].$2,
              high: rows[i].$3,
              value: rows[i].$4,
              onChanged: (v) => onChanged(rows[i].$5(v)),
              onChangeEnd: (v) => onChangeEnd(rows[i].$5(v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TweakRow extends StatelessWidget {
  final String label, low, high;
  final double value;
  final ValueChanged<double> onChanged, onChangeEnd;

  const _TweakRow({
    required this.label,
    required this.low,
    required this.high,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  String get _state {
    if (value.abs() < 0.05) return '그대로';
    final pct = (value.abs() * 100).round();
    return '${value < 0 ? low : high} $pct';
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: Txt.bodyText)),
                Text(_state, style: Txt.secondary),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                // 가운데가 '그대로'라서 양쪽 막대를 같은 색으로 둔다
                activeTrackColor: Riso.lineStrong,
                inactiveTrackColor: Riso.lineStrong,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                showValueIndicator: ShowValueIndicator.never,
                thumbColor: Riso.ink,
                overlayColor: Riso.ink.withValues(alpha: 0.08),
                trackHeight: 3,
              ),
              child: Slider(
                value: value,
                min: -1,
                max: 1,
                divisions: 20,
                semanticFormatterCallback: (_) => '$label $_state',
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
            Row(
              children: [
                Text(low, style: Txt.meta),
                const Spacer(),
                Text(high, style: Txt.meta),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
}

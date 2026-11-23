// 부위 속 보기: 그 부위를 동그랗게 잘라 본 단순한 층 그림.
// 바깥부터 피부 → 노란 피하지방 → 빨간 근육 다발, 배는 안쪽에 주황 내장지방 구름.
// 뼈·장기 같은 해부 구조는 일부러 뺐다. 보여주고 싶은 건 "지방·근육·내장지방이 얼마나 변했나" 하나.
// 지방 두께, 근육 크기·개수, 내장지방 양이 체형 숫자에 따라 눈에 띄게 달라진다.
// 그림체는 사용자 손그림을 따른다: 크레용 빗금, 떨리는 먹선, 얼굴 달린 지방이·근육이, 손글씨 이름표.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/body_calc.dart';
import '../theme.dart';
import 'inner_blob.dart' show BlobMood;
import 'riso_paint.dart';

// ---------- 크레용 색 ----------
const _skinInk = Color(0xFFF5C3A8);
const _fatInk = Color(0xFFFFDA5C);
const _muscleInk = Color(0xFFFF5468);
const _muscleWeak = Color(0xFFFF9AA6);
const _coreInk = Color(0xFFFFE4E8); // 근육 사이 바탕
const _insideInk = Color(0xFFF4EFEA); // 몸속 빈 곳
const _cavityInk = Color(0xFFFDEAE6); // 뱃속
const _visceralInk = Color(0xFFFF9A1F);

class CrossSection extends StatelessWidget {
  final BodyPart part;
  final BodyShape shape;
  final double? visceralLevel;
  final bool female;
  final double width;

  const CrossSection({
    super.key,
    required this.part,
    required this.shape,
    this.visceralLevel,
    this.female = false,
    this.width = 340,
  });

  static double aspect(BodyPart p) => switch (p) {
        BodyPart.arm || BodyPart.thigh => 250 / 320,
        BodyPart.chest || BodyPart.belly => 272 / 320,
      };

  String get _description => switch (part) {
        BodyPart.arm => '팔뚝 속 그림. 바깥부터 피부, 노란 피하지방, 빨간 근육',
        BodyPart.thigh => '허벅지 속 그림. 바깥부터 피부, 노란 피하지방, 빨간 근육',
        BodyPart.chest => '가슴 속 그림. 바깥부터 피부, 노란 피하지방, 가슴 근육과 등 근육',
        BodyPart.belly => '배 속 그림. 바깥부터 피부, 노란 피하지방, 빨간 근육, 안쪽에 주황 내장지방',
      };

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: _description,
        child: SizedBox(
          width: width,
          height: width * aspect(part),
          child: CustomPaint(
            painter: _SectionPainter(
                part, shape.fatness, shape.muscle, female, visceralLevel ?? 5),
          ),
        ),
      );
}

class _SectionPainter extends CustomPainter {
  final BodyPart part;
  final double fat, mus, level;
  final bool female;
  _SectionPainter(this.part, this.fat, this.mus, this.female, this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 320;
    canvas.save();
    canvas.scale(k);
    final s = switch (part) {
      BodyPart.arm => _LimbSection(fat, mus, thigh: false),
      BodyPart.thigh => _LimbSection(fat, mus, thigh: true, female: female),
      BodyPart.chest => _ChestSection(fat, mus, female),
      BodyPart.belly => _BellySection(fat, mus, level),
    };
    s.paint(canvas, Size(320, size.height / k));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SectionPainter o) =>
      o.part != part || o.fat != fat || o.mus != mus || o.female != female || o.level != level;
}

// =====================================================================
// 공통 도구
// =====================================================================

Offset _dir(double th) => Offset(math.cos(th), math.sin(th));

/// 타원 위 점까지의 거리 (중심에서 각도 th 방향).
double _ell(double a, double b, double th) {
  final c = math.cos(th), s = math.sin(th);
  return a * b / math.sqrt(b * b * c * c + a * a * s * s);
}

/// 각도 th가 mu 근처일 때 1, 멀어질수록 0.
double _g(double th, double mu, double sd) {
  var d = (th - mu) % (2 * math.pi);
  if (d > math.pi) d -= 2 * math.pi;
  return math.exp(-(d * d) / (sd * sd));
}

Path _closed(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// 반지름 함수로 닫힌 외곽선.
Path _polar(double Function(double) r, {int n = 180}) {
  final pts = <Offset>[
    for (var i = 0; i < n; i++)
      _dir(-math.pi + 2 * math.pi * i / n) * r(-math.pi + 2 * math.pi * i / n),
  ];
  return _closed(pts);
}

/// 살짝 울퉁불퉁한 타원.
Path _blob(Offset c, double rx, double ry, {double rot = 0, int seed = 1, double wob = 0.06}) {
  final r = math.Random(seed);
  final p1 = r.nextDouble() * 6.28, p2 = r.nextDouble() * 6.28, p3 = r.nextDouble() * 6.28;
  final cr = math.cos(rot), sr = math.sin(rot);
  const n = 44;
  return _closed([
    for (var i = 0; i < n; i++)
      () {
        final t = 2 * math.pi * i / n;
        final k = 1 +
            wob * (0.6 * math.sin(2 * t + p1) + 0.4 * math.sin(3 * t + p2) + 0.25 * math.sin(5 * t + p3));
        final x = math.cos(t) * rx * k, y = math.sin(t) * ry * k;
        return c + Offset(x * cr - y * sr, x * sr + y * cr);
      }(),
  ]);
}

Path _minus(Path a, Path b) => Path.combine(PathOperation.difference, a, b);
Path _plus(Path a, Path b) => Path.combine(PathOperation.union, a, b);
Path _and(Path a, Path b) => Path.combine(PathOperation.intersect, a, b);

/// 크레용으로 칠하고 떨리는 먹선으로 딴 한 조각. 아래가 비치지 않게 흰 밑칠을 먼저 깐다.
void _piece(Canvas c, Path p, Color ink,
    {int seed = 1,
    double base = 0.45,
    double spacing = 4,
    double angle = -0.55,
    double line = 1.4,
    double hatchW = 2.4,
    bool outline = true}) {
  c.drawPath(p, Paint()..color = Riso.sheet);
  Hand.hatch(c, p, ink, angle: angle, spacing: spacing, width: hatchW, base: base, seed: seed);
  if (outline) {
    Hand.outline(c, p, width: line, amp: 0.5, seed: seed + 50, shift: const Offset(0.7, 0.45));
  }
}

/// 형광펜으로 그은 듯한 노란 줄 (내장지방 표시, 사용자 손그림의 표현).
void _marker(Canvas c, Path region, int seed) {
  Hand.hatch(c, region, Riso.yellow.withValues(alpha: 0.85),
      angle: -0.12, spacing: 9, width: 4.5, base: 0, seed: seed);
}

BlobMood _fatMood(double fat) =>
    fat > 0.55 ? BlobMood.angry : (fat > 0.22 ? BlobMood.normal : BlobMood.sleepy);
BlobMood _musMood(double mus) =>
    mus >= 0.45 ? BlobMood.happy : (mus >= 0.25 ? BlobMood.normal : BlobMood.struggling);

class _Callout {
  final String text;
  final Offset at; // 글자 왼쪽 위 (캔버스 좌표)
  final Offset target; // 가리키는 점 (단면 좌표)
  const _Callout(this.text, this.at, this.target);
}

/// 단면 하나. 단면은 원점 중심 좌표로 그리고, 칸(box)에 맞춰 크기를 줄이거나 늘린다.
/// 그래서 살이 많아도 그림이 넘치지 않고, 대신 층 두께 비율로 차이가 보인다.
abstract class _Section {
  final double fat, mus;
  _Section(this.fat, this.mus);

  late Offset _o;
  late double _k;
  Offset toCanvas(Offset p) => _o + p * _k;

  Rect box(Size s);
  Path outline();
  void draw(Canvas c);
  List<_Callout> callouts(Size s);

  void paint(Canvas c, Size size) {
    final b = box(size);
    final ob = outline().getBounds();
    _k = math.min(b.width / ob.width, b.height / ob.height);
    _o = b.center - ob.center * _k;
    c.save();
    c.translate(_o.dx, _o.dy);
    c.scale(_k);
    draw(c);
    c.restore();
    for (final co in callouts(size)) {
      _callout(c, co);
    }
  }

  void _callout(Canvas c, _Callout co) {
    final tp = TextPainter(
      text: TextSpan(
          text: co.text,
          style: const TextStyle(fontFamily: 'NanumPen', fontSize: 18, color: Riso.ink, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, co.at);
    final r = co.at & tp.size;
    final t = toCanvas(co.target);
    final Offset from;
    if (t.dx > r.right + 6) {
      from = Offset(r.right + 3, r.center.dy);
    } else if (t.dx < r.left - 6) {
      from = Offset(r.left - 3, r.center.dy);
    } else if (t.dy < r.top) {
      from = Offset(r.center.dx, r.top - 2);
    } else {
      from = Offset(r.center.dx, r.bottom + 2);
    }
    _arrow(c, from, t, co.text.length);
  }

  void _arrow(Canvas c, Offset from, Offset to, int seed) {
    final d = to - from;
    final n = Offset(-d.dy, d.dx) * 0.12;
    final ctrl = from + d * 0.5 + n;
    final line = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);
    Hand.outline(c, line, width: 1.3, seed: 90 + seed, amp: 0.6);
    final ang = math.atan2(to.dy - ctrl.dy, to.dx - ctrl.dx);
    final head = Paint()
      ..color = Riso.ink
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final s in [0.45, -0.45]) {
      c.drawLine(to, to - Offset(math.cos(ang + s), math.sin(ang + s)) * 7, head);
    }
  }
}


// =====================================================================
// 공통: 근육 다발, 지방 얼굴
// =====================================================================

/// 얼굴 달린 근육 다발 하나 (겹친 타원, 사용자 손그림처럼).
void _bundle(Canvas c, Offset at, double rx, double ry, double rot, int seed, double mus) {
  final p = _blob(at, rx, ry, rot: rot, seed: seed, wob: 0.05);
  _piece(c, p, mus < 0.25 ? _muscleWeak : _muscleInk,
      seed: seed, base: 0.5, spacing: 3.8, angle: -0.6 + (seed % 3) * 0.55, line: 1.5);
  // 근육 결: 끝쪽에 짧은 줄 두세 개
  final fiber = Paint()
    ..color = Riso.ink.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..strokeCap = StrokeCap.round;
  final d = Offset(math.cos(rot), math.sin(rot));
  final n = Offset(-d.dy, d.dx);
  for (final k in [-0.25, 0.0, 0.25]) {
    final a = at + d * (rx * 0.62) + n * (ry * k);
    c.drawLine(a, a + d * (rx * 0.22), fiber);
  }
  sketchFace(c, at - d * (rx * 0.12), _musMood(mus), s: (math.min(rx, ry) / 15).clamp(0.45, 1.15));
}

/// 지방층에 얼굴 하나. 층이 너무 얇으면 그리지 않는다.
void _fatFace(Canvas c, Offset at, double thickness, double fat, {double max = 1.15}) {
  if (thickness < 6) return;
  sketchFace(c, at, _fatMood(fat), s: (thickness / 21).clamp(0.42, max));
}

Rect _trunkBox(Size s) =>
    Rect.fromCenter(center: Offset(160, s.height / 2 - 2), width: 236, height: s.height - 66);

// =====================================================================
// 팔뚝·허벅지: 동그란 단면. 피부 → 노란 지방 고리 → 근육 다발.
// 근육이 많을수록 다발이 크고 많아지고, 살이 찔수록 지방 고리가 두꺼워진다.
// 팔뚝살은 뒤쪽, 허벅지살은 바깥쪽·뒤쪽에 더 붙는다.
// =====================================================================
class _LimbSection extends _Section {
  final bool thigh, female;
  _LimbSection(super.fat, super.mus, {required this.thigh, this.female = false});

  // (x, y, rx, ry, 기울기) — 근육 덩어리 자리, 단위는 근육 반지름
  static const _armLayout = [
    (0.0, -0.42, 0.62, 0.46, 0.1),
    (0.02, 0.42, 0.70, 0.50, -0.1),
    (-0.56, 0.0, 0.40, 0.52, 0.3),
    (0.58, -0.02, 0.38, 0.50, -0.3),
    (0.38, -0.60, 0.30, 0.24, 0.5),
    (-0.40, 0.62, 0.32, 0.25, -0.4),
  ];
  static const _thighLayout = [
    (0.04, -0.50, 0.56, 0.42, 0.15),
    (0.56, 0.04, 0.42, 0.56, -0.2),
    (0.04, 0.52, 0.60, 0.42, -0.1),
    (-0.54, 0.04, 0.42, 0.54, 0.25),
    (-0.44, -0.56, 0.30, 0.24, 0.6),
    (0.46, 0.62, 0.30, 0.23, -0.5),
    (0.0, 0.0, 0.30, 0.27, 0.0),
  ];

  double get rc => (thigh ? 60 : 50) * (0.8 + 0.4 * mus);
  double rm(double th) => rc * (1 + 0.04 * math.cos(2 * th + 0.4) + 0.025 * math.sin(3 * th + 1));
  double ft(double th) => thigh
      ? (5 + 36 * fat) *
          (1 + 0.3 * math.cos(th) + 0.25 * math.max(0.0, math.sin(th)) + (female ? 0.15 : 0))
      : (4 + 32 * fat) * (1 + 0.45 * math.max(0.0, math.sin(th)));
  double rf(double th) => rm(th) + ft(th);
  double rs(double th) => rf(th) + 3.2;

  List<(double, double, double, double, double)> get _bundles =>
      (thigh ? _thighLayout : _armLayout).take(thigh ? 4 + (mus * 3).round() : 3 + (mus * 3).round()).toList();

  @override
  Rect box(Size s) => Rect.fromCenter(center: Offset(160, s.height / 2), width: 190, height: s.height - 24);

  @override
  Path outline() => _polar(rs);

  @override
  void draw(Canvas c) {
    _piece(c, _polar(rs), _skinInk, seed: 1, base: 0.5, spacing: 4.4, line: 1.8);
    _piece(c, _polar(rf), _fatInk, seed: 2, base: 0.5, spacing: 4.2, angle: 0.6, line: 1.6);
    final core = _polar(rm);
    _piece(c, core, _coreInk, seed: 3, base: 0.7, spacing: 6, line: 1.6, hatchW: 1.6);

    // 근육 다발: 작은 것부터 그려서 큰 다발이 위에 겹치게
    final k = 0.95 + 0.15 * mus;
    final items = _bundles;
    c.save();
    c.clipPath(core);
    for (var i = items.length - 1; i >= 0; i--) {
      final (x, y, rx, ry, rot) = items[i];
      _bundle(c, Offset(x, y) * rc, rx * rc * k, ry * rc * k, rot, 10 + i, mus);
    }
    c.restore();
    Hand.outline(c, core, width: 1.6, amp: 0.5, seed: 9);

    final fa = thigh ? 0.35 : math.pi / 2 + 0.2;
    _fatFace(c, _dir(fa) * (rm(fa) + ft(fa) / 2), ft(fa), fat);
    final fb = thigh ? 1.95 : math.pi / 2 + 1.25;
    if (ft(fb) > 15) _fatFace(c, _dir(fb) * (rm(fb) + ft(fb) / 2), ft(fb), fat, max: 0.9);
  }

  @override
  List<_Callout> callouts(Size s) {
    final side = _bundles[2];
    return [
      _Callout('근육', Offset(10, s.height / 2 - 12), Offset(side.$1 * 0.55, side.$2 - 0.12) * rc),
      _Callout('피부', const Offset(276, 26), _dir(-0.75) * (rf(-0.75) + 1.6)),
      _Callout('피하지방', Offset(254, s.height - 40), _dir(1.0) * (rm(1.0) + ft(1.0) / 2)),
    ];
  }
}

// =====================================================================
// 가슴·등: 옆으로 긴 단면. 피부 → 노란 지방층 → 앞 가슴 근육, 옆 근육, 뒤 등 근육.
// 가운데 몸속은 비워 둔다 (장기는 안 그린다). 여자는 가슴 앞 지방이 두툼하다.
// =====================================================================
class _ChestSection extends _Section {
  final bool female;
  _ChestSection(super.fat, super.mus, this.female);

  double rIn(double th) => _ell(62, 36, th);
  double mT(double th) {
    final front = math.max(0.0, -math.sin(th)), back = math.max(0.0, math.sin(th));
    return (9 + 10 * mus) + (8 + 18 * mus) * front * front + (6 + 12 * mus) * back * back;
  }

  double rMus(double th) => rIn(th) + mT(th);
  double ft(double th) {
    final base = (4 + 28 * fat) * (1 + 0.25 * math.cos(th) * math.cos(th));
    final breast = female
        ? (6 + 26 * fat) * (_g(th, -math.pi / 2 - 0.6, 0.38) + _g(th, -math.pi / 2 + 0.6, 0.38))
        : 0.0;
    return base + breast;
  }

  double rF(double th) => rMus(th) + ft(th);
  double rS(double th) => rF(th) + 3;
  Offset ringAt(double th) => _dir(th) * (rIn(th) + mT(th) / 2);

  // (각도, 가로 반폭(각도), 세로 비율)
  static const _spots = [
    (0.0, 0.55, 0.6), (math.pi, 0.55, 0.6), // 옆
    (math.pi / 2 - 0.52, 0.5, 0.66), (math.pi / 2 + 0.52, 0.5, 0.66), // 등
    (-math.pi / 2 - 0.55, 0.6, 0.68), (-math.pi / 2 + 0.55, 0.6, 0.68), // 가슴
  ];

  @override
  Rect box(Size s) => _trunkBox(s);

  @override
  Path outline() => _polar(rS);

  @override
  void draw(Canvas c) {
    _piece(c, _polar(rS), _skinInk, seed: 1, base: 0.5, spacing: 4.4, line: 1.8);
    _piece(c, _polar(rF), _fatInk, seed: 2, base: 0.5, spacing: 4.2, angle: 0.6, line: 1.6);
    final musOut = _polar(rMus), inside = _polar(rIn);
    _piece(c, musOut, _coreInk, seed: 3, base: 0.7, spacing: 6, line: 1.6, hatchW: 1.6);
    _piece(c, inside, _insideInk, seed: 4, base: 0.6, spacing: 7, line: 1.4, hatchW: 1.4);

    c.save();
    c.clipPath(_minus(musOut, inside));
    var i = 0;
    for (final (th, hw, hr) in _spots) {
      final r = rIn(th) + mT(th) / 2;
      _bundle(c, ringAt(th), hw * r, mT(th) * hr, th + math.pi / 2, 20 + i++, mus);
    }
    c.restore();
    Hand.outline(c, musOut, width: 1.6, amp: 0.5, seed: 8);
    Hand.outline(c, inside, width: 1.4, amp: 0.5, seed: 9);
    final tp = TextPainter(
      text: TextSpan(
          text: '몸속',
          style: TextStyle(fontFamily: 'NanumPen', fontSize: 18, color: Riso.ink.withValues(alpha: 0.4))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));

    final fa = female ? -math.pi / 2 - 0.6 : math.pi - 0.2;
    _fatFace(c, _dir(fa) * (rMus(fa) + ft(fa) / 2), ft(fa) * (female ? 0.7 : 1), fat);
    if (ft(0.15) > 15) _fatFace(c, _dir(0.15) * (rMus(0.15) + ft(0.15) / 2), ft(0.15), fat, max: 0.9);
  }

  @override
  List<_Callout> callouts(Size s) => [
        _Callout('피하지방', const Offset(8, 6),
            _dir(-math.pi / 2 - 1.1) * (rMus(-math.pi / 2 - 1.1) + ft(-math.pi / 2 - 1.1) / 2)),
        _Callout('가슴 근육', const Offset(232, 6), ringAt(-math.pi / 2 + 0.75)),
        _Callout('등 근육', Offset(8, s.height - 26), ringAt(math.pi / 2 + 0.7)),
      ];
}

// =====================================================================
// 뱃살: 옆으로 긴 단면. 피부 → 노란 피하지방(배 앞·옆구리가 두껍고 배꼽 자리는 쏙) →
// 앞 복근 두 덩어리, 옆구리 근육, 뒤 허리 근육 → 안쪽 뱃속에 주황 내장지방 구름.
// 내장지방 레벨이 오르면 구름이 커지고 덩어리와 얼굴이 늘어난다.
// =====================================================================
class _BellySection extends _Section {
  final double level;
  _BellySection(super.fat, super.mus, this.level);

  double get lv => ((level - 1) / 19).clamp(0.0, 1.0);
  double rIn(double th) => _ell(76, math.sin(th) < 0 ? 46 : 40, th);
  double mT(double th) {
    final front = math.max(0.0, -math.sin(th)), back = math.max(0.0, math.sin(th));
    return (8 + 8 * mus) + (4 + 10 * mus) * front * front + (8 + 12 * mus) * back * back;
  }

  double rMus(double th) => rIn(th) + mT(th);
  double ft(double th) {
    final front = math.max(0.0, -math.sin(th));
    final side = math.cos(th) * math.cos(th);
    return (5 + 34 * fat) * (0.3 + 0.8 * front + 0.5 * side * (1 - 0.5 * math.max(0.0, math.sin(th))));
  }

  double _nav(double th) => ft(-math.pi / 2) * 0.6 * _g(th, -math.pi / 2, 0.05);
  double rF(double th) => rMus(th) + ft(th) - _nav(th);
  double rS(double th) => rF(th) + 3;
  Offset ringAt(double th) => _dir(th) * (rIn(th) + mT(th) / 2);

  static const _spots = [
    (0.0, 0.62, 0.6), (math.pi, 0.62, 0.6), // 옆구리
    (math.pi / 2 - 0.45, 0.42, 0.66), (math.pi / 2 + 0.45, 0.42, 0.66), // 허리
    (-math.pi / 2 - 0.3, 0.3, 0.68), (-math.pi / 2 + 0.3, 0.3, 0.68), // 복근
  ];

  /// 내장지방 구름을 이루는 동그라미들.
  List<(Offset, double)> get _puffs {
    final n = 3 + (lv * 7).round();
    final r = 10 + 16 * lv;
    final spread = 8 + 30 * lv;
    final rnd = math.Random(7);
    return [
      for (var i = 0; i < n; i++)
        (
          const Offset(0, 3) +
              Offset(math.cos(i * 2.4) * 1.4, math.sin(i * 2.4) * 0.85) * (spread * math.sqrt((i + 0.5) / n)),
          r * (0.85 + 0.3 * rnd.nextDouble()),
        ),
    ];
  }

  @override
  Rect box(Size s) => _trunkBox(s);

  @override
  Path outline() => _polar(rS, n: 360);

  @override
  void draw(Canvas c) {
    _piece(c, _polar(rS, n: 360), _skinInk, seed: 1, base: 0.5, spacing: 4.4, line: 1.8);
    _piece(c, _polar(rF, n: 360), _fatInk, seed: 2, base: 0.5, spacing: 4.2, angle: 0.6, line: 1.6);
    final musOut = _polar(rMus), inside = _polar(rIn);
    _piece(c, musOut, _coreInk, seed: 3, base: 0.7, spacing: 6, line: 1.6, hatchW: 1.6);
    _piece(c, inside, _cavityInk, seed: 4, base: 0.6, spacing: 6, line: 1.4, hatchW: 1.4);

    c.save();
    c.clipPath(_minus(musOut, inside));
    var i = 0;
    for (final (th, hw, hr) in _spots) {
      final r = rIn(th) + mT(th) / 2;
      _bundle(c, ringAt(th), hw * r, mT(th) * hr, th + math.pi / 2, 30 + i++, mus);
    }
    c.restore();
    Hand.outline(c, musOut, width: 1.6, amp: 0.5, seed: 8);

    // 내장지방 구름
    final puffs = _puffs;
    var cloud = Path();
    for (final (p, r) in puffs) {
      cloud = _plus(cloud, Path()..addOval(Rect.fromCircle(center: p, radius: r)));
    }
    cloud = _and(cloud, _polar((th) => rIn(th) - 3));
    _piece(c, cloud, _visceralInk, seed: 40, base: 0.5, spacing: 4, angle: 0.7, line: 1.6);
    _marker(c, cloud, 41);
    Hand.outline(c, inside, width: 1.4, amp: 0.5, seed: 9);

    final vm = level >= 10 ? BlobMood.angry : (level >= 5 ? BlobMood.normal : BlobMood.sleepy);
    final faces = lv < 0.25 ? 1 : (lv < 0.55 ? 2 : 3);
    final vs = (0.55 + 0.5 * lv).clamp(0.55, 1.05);
    // 얼굴은 서로 안 겹치게: 가운데, 오른쪽 끝, 왼쪽 끝 덩어리에
    final byX = [...puffs]..sort((a, b) => a.$1.dx.compareTo(b.$1.dx));
    final mid = puffs.reduce((a, b) => a.$1.distance < b.$1.distance ? a : b);
    final spots = [mid.$1, byX.last.$1 - Offset(byX.last.$2 * 0.25, 0), byX.first.$1 + Offset(byX.first.$2 * 0.25, 0)];
    for (final at in spots.take(faces)) {
      sketchFace(c, at, vm, s: vs);
    }

    const fa = -math.pi / 2 - 0.45;
    _fatFace(c, _dir(fa) * (rMus(fa) + ft(fa) / 2), ft(fa), fat);
    const fb = math.pi - 0.1;
    if (ft(fb) > 15) _fatFace(c, _dir(fb) * (rMus(fb) + ft(fb) / 2), ft(fb), fat, max: 0.95);
    const fc = 0.1;
    if (ft(fc) > 22) _fatFace(c, _dir(fc) * (rMus(fc) + ft(fc) / 2), ft(fc), fat, max: 0.95);
  }

  @override
  List<_Callout> callouts(Size s) {
    final p = _puffs.reduce((a, b) => a.$1.dx < b.$1.dx ? a : b);
    return [
      _Callout('피하지방', const Offset(8, 6),
          _dir(-math.pi / 2 - 0.9) * (rMus(-math.pi / 2 - 0.9) + ft(-math.pi / 2 - 0.9) / 2)),
      _Callout('근육', const Offset(284, 8), ringAt(-math.pi / 2 + 0.3)),
      _Callout('내장지방', Offset(6, s.height - 26), p.$1 - Offset(p.$2 * 0.5, -p.$2 * 0.3)),
    ];
  }
}

/// 손그림 얼굴: 동그라미 눈 + 큰 웃음.
void sketchFace(Canvas c, Offset at, BlobMood mood, {double s = 1}) {
  final line = Paint()
    ..color = Riso.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3 * s
    ..strokeCap = StrokeCap.round;
  final dot = Paint()..color = Riso.ink;
  for (final sx in [-1.0, 1.0]) {
    final e = at + Offset(sx * 5 * s, -2.5 * s);
    switch (mood) {
      case BlobMood.happy:
      case BlobMood.normal:
        c.drawCircle(e, 2.6 * s, line);
        c.drawCircle(e + Offset(0.5 * s, 0.4 * s), 1.2 * s, dot);
      case BlobMood.angry:
        c.drawCircle(e, 2.6 * s, line);
        c.drawCircle(e + Offset(0.3 * s, 0.6 * s), 1.2 * s, dot);
        // 찌푸린 눈썹: 안쪽이 내려간 사선
        c.drawLine(e + Offset(-3.2 * sx * s, -5.2 * s), e + Offset(3.0 * sx * s, -3.0 * s), line);
      case BlobMood.sleepy:
        c.drawArc(Rect.fromCenter(center: e, width: 5.6 * s, height: 4 * s), 0, math.pi, false, line);
      case BlobMood.struggling:
        c.drawLine(e + Offset(-2 * sx * s, -2 * s), e + Offset(2 * sx * s, 0), line);
        c.drawLine(e + Offset(2 * sx * s, 0), e + Offset(-2 * sx * s, 2 * s), line);
    }
  }
  final m = at + Offset(0, 3 * s);
  switch (mood) {
    case BlobMood.happy:
      c.drawArc(Rect.fromCenter(center: m, width: 16 * s, height: 9 * s), 0.25, math.pi - 0.5, false, line);
    case BlobMood.normal:
    case BlobMood.sleepy:
      c.drawLine(m + Offset(-3.5 * s, 1.5 * s), m + Offset(3.5 * s, 1.5 * s), line);
    case BlobMood.angry:
      // 이를 악문 입: 납작한 네모 + 송곳니
      final r = Rect.fromCenter(center: m + Offset(0, 2 * s), width: 11 * s, height: 4 * s);
      c.drawRect(r, line);
      c.drawLine(r.bottomLeft + Offset(2.5 * s, 0), r.bottomLeft + Offset(3.5 * s, 2.5 * s), line);
      c.drawLine(r.bottomRight - Offset(2.5 * s, 0), r.bottomRight + Offset(-3.5 * s, 2.5 * s), line);
    case BlobMood.struggling:
      c.drawArc(Rect.fromCenter(center: m + Offset(0, 4 * s), width: 10 * s, height: 6 * s),
          math.pi + 0.3, math.pi - 0.6, false, line);
  }
}



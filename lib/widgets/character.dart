// 전신 캐릭터: 3등신, 크레용 손그림, 속옷 차림.
// 몸은 실제 사람 비율의 뼈대(머리 하나 = 43, 약 7.75등신)로 만들고,
// 머리를 키우면서 몸을 옆으로 통통하게 눌러 3등신으로 바꾼다.
// 시안 생성기(character-concepts/crayon.js, fig.js)를 그대로 옮긴 것이라 숫자를 바꿀 땐 둘을 같이 본다.
// 화면에서는 CharacterView만 쓰고, 그리는 방식은 이 파일 안에 가둬 둔다.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/body_calc.dart';
import '../models/models.dart';
import '../theme.dart';
import 'riso_paint.dart';

// 단면 그림의 피부와 같은 크레용 색
const _skinInk = Color(0xFFF5C3A8);

class CharacterView extends StatelessWidget {
  final Gender gender;
  final BodyShape shape;
  final CharacterStyle style;
  final bool tired;
  final ValueChanged<BodyPart>? onPartTap; // 있으면 부위 이름표를 단다
  final double height;

  const CharacterView({
    super.key,
    required this.gender,
    required this.shape,
    required this.style,
    this.tired = false,
    this.onPartTap,
    this.height = 320,
  });

  static const _w = 200.0, _h = 360.0;

  Widget _figure(_Figure fig) => CustomPaint(
        size: Size(_w * height / _h, height),
        painter: _CharacterPainter(fig),
      );

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(end: Offset(shape.fatness, shape.muscle)),
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final fig = _Figure(
          female: gender == Gender.female,
          f: v.dx,
          mus: v.dy,
          hair: Color(style.hairColor),
          outfit: Color(style.outfitColor),
          tired: tired,
        );
        if (onPartTap == null) {
          return Semantics(
            image: true,
            label: '내 캐릭터',
            child: SizedBox(width: _w * height / _h, height: height, child: _figure(fig)),
          );
        }
        return LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final s = height / _h;
          final figW = _w * s;
          final figLeft = (w - figW) / 2;
          Offset screen(BodyPart p) {
            final a = fig.anchor(p);
            return Offset(figLeft + a.dx * s, a.dy * s);
          }

          const labelW = 76.0;
          const left = [BodyPart.chest, BodyPart.belly];
          const right = [BodyPart.arm, BodyPart.thigh];

          return SizedBox(
            width: w,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: figLeft, top: 0, child: _figure(fig)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _LeaderPainter([
                        for (final p in left) (screen(p), Offset(labelW, screen(p).dy)),
                        for (final p in right) (screen(p), Offset(w - labelW, screen(p).dy)),
                      ]),
                    ),
                  ),
                ),
                for (final p in [...left, ...right])
                  Positioned(
                    left: left.contains(p) ? 0 : w - labelW,
                    top: screen(p).dy - 22,
                    width: labelW,
                    height: 44,
                    child: _PartLabel(part: p, onTap: () => onPartTap!(p)),
                  ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _PartLabel extends StatelessWidget {
  final BodyPart part;
  final VoidCallback onTap;
  const _PartLabel({required this.part, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${part.label} 단면 보기',
        excludeSemantics: true,
        child: Center(
          child: Material(
            color: Riso.sheet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Riso.ink, width: 1.5),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 36,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        part == BodyPart.thigh ? '허벅지' : part.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Txt.label,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Riso.ink),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _LeaderPainter extends CustomPainter {
  final List<(Offset, Offset)> lines;
  _LeaderPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Riso.ink
      ..strokeWidth = 1.2;
    for (final (a, b) in lines) {
      canvas.drawLine(a, b, line);
      canvas.drawCircle(a, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(a, 3, Paint()..color = Riso.ink);
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter o) => true;
}

class _CharacterPainter extends CustomPainter {
  final _Figure fig;
  _CharacterPainter(this.fig);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 360);
    fig.paint(canvas);
  }

  @override
  bool shouldRepaint(_CharacterPainter o) => !fig.same(o.fig);
}

// ===================================================================
// 그리기 도구
// ===================================================================

double _lerp(double a, double b, double t) => a + (b - a) * t;
double _sstep(double t) {
  t = t.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

Offset _norm(Offset v) {
  final l = v.distance;
  return l == 0 ? Offset.zero : v / l;
}

/// 구간마다 부드럽게 이어지는 값 (키: (위치, 값)).
double _interp(List<(double, double)> keys, double t) {
  if (t <= keys.first.$1) return keys.first.$2;
  for (var i = 0; i < keys.length - 1; i++) {
    final (t0, v0) = keys[i];
    final (t1, v1) = keys[i + 1];
    if (t <= t1) return v0 + (v1 - v0) * _sstep((t - t0) / (t1 - t0));
  }
  return keys.last.$2;
}

List<double> _range(double a, double b, int n) => [for (var i = 0; i <= n; i++) _lerp(a, b, i / n)];

/// 윤곽 점. c가 true면 그 점에서 꺾인다.
class _Q {
  final Offset p;
  final bool c;
  const _Q(this.p, [this.c = false]);
  _Q map(Offset Function(Offset) t) => _Q(t(p), c);
}

/// 점들을 Catmull-Rom 곡선으로 촘촘하게 잇는다. 꺾이는 점에서는 구간을 끊는다.
List<Offset> _smooth(List<_Q> pts, {bool closed = true}) {
  final out = <Offset>[];
  void cr(Offset p0, Offset p1, Offset p2, Offset p3) {
    final n = math.max(2, ((p2 - p1).distance / 2.5).ceil());
    for (var k = 0; k < n; k++) {
      final t = k / n, t2 = t * t, t3 = t2 * t;
      double f(double a0, double a1, double a2, double a3) =>
          0.5 * (2 * a1 + (-a0 + a2) * t + (2 * a0 - 5 * a1 + 4 * a2 - a3) * t2 + (-a0 + 3 * a1 - 3 * a2 + a3) * t3);
      out.add(Offset(f(p0.dx, p1.dx, p2.dx, p3.dx), f(p0.dy, p1.dy, p2.dy, p3.dy)));
    }
  }

  final runs = <List<Offset>>[];
  if (closed) {
    final ci = pts.indexWhere((q) => q.c);
    if (ci < 0) {
      final n = pts.length;
      for (var i = 0; i < n; i++) {
        cr(pts[(i - 1 + n) % n].p, pts[i].p, pts[(i + 1) % n].p, pts[(i + 2) % n].p);
      }
      return out;
    }
    final r = [...pts.sublist(ci), ...pts.sublist(0, ci + 1)];
    var cur = <Offset>[r.first.p];
    for (var i = 1; i < r.length; i++) {
      cur.add(r[i].p);
      if (r[i].c) {
        runs.add(cur);
        cur = [r[i].p];
      }
    }
  } else {
    var cur = <Offset>[pts.first.p];
    for (var i = 1; i < pts.length; i++) {
      cur.add(pts[i].p);
      if (pts[i].c && i < pts.length - 1) {
        runs.add(cur);
        cur = [pts[i].p];
      }
    }
    runs.add(cur);
  }
  for (final q in runs) {
    final n = q.length;
    for (var i = 0; i < n - 1; i++) {
      cr(q[math.max(0, i - 1)], q[i], q[i + 1], q[math.min(n - 1, i + 2)]);
    }
  }
  if (!closed) out.add(pts.last.p);
  return out;
}

List<_Q> _qs(Iterable<Offset> pts) => [for (final p in pts) _Q(p)];

/// 끝 두 점만 꺾이는 점 목록
List<_Q> _wrap(List<Offset> pts) =>
    [for (var i = 0; i < pts.length; i++) _Q(pts[i], i == 0 || i == pts.length - 1)];

List<Offset> _ellipse(Offset c, double rx, double ry, [int n = 16]) => [
      for (var i = 0; i < n; i++)
        c + Offset(math.cos(i / n * 2 * math.pi) * rx, math.sin(i / n * 2 * math.pi) * ry)
    ];

/// 크레용으로 칠하고 먹선으로 따는 한 조각. 아래 조각이 비치지 않게 흰 밑칠을 먼저 깐다.
void _piece(Canvas c, List<_Q> pts, Color ink,
    {required int seed,
    double base = 0.42,
    double spacing = 3.6,
    double width = 2.4,
    double angle = -0.55,
    double lw = 1.6}) {
  final path = Path()..addPolygon(_smooth(pts), true);
  c.drawPath(path, Paint()..color = Riso.sheet);
  Hand.hatch(c, path, ink, angle: angle, spacing: spacing, width: width, base: base, seed: seed);
  Hand.outline(c, path, width: lw, amp: 0.7, seed: seed + 40, shift: const Offset(0.9, 0.55));
}

/// 몸 안쪽 결 선 (연한 먹)
void _line(Canvas c, List<Offset> pts,
    {double alpha = 0.5, double lw = 1.2, int seed = 3, double amp = 0.35, Color color = Riso.ink}) {
  final path = Path()..addPolygon(_smooth(_qs(pts), closed: false), false);
  c.drawPath(
    Hand.wobble(path, amp: amp, seed: seed, step: 3),
    Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

Offset? _segHit(Offset a, Offset b, Offset c, Offset d) {
  final r = b - a, q = d - c;
  final den = r.dx * q.dy - r.dy * q.dx;
  if (den.abs() < 1e-9) return null;
  final t = ((c.dx - a.dx) * q.dy - (c.dy - a.dy) * q.dx) / den;
  final u = ((c.dx - a.dx) * r.dy - (c.dy - a.dy) * r.dx) / den;
  return (t >= 0 && t <= 1 && u >= 0 && u <= 1) ? Offset.lerp(a, b, t) : null;
}

// ===================================================================
// 몸 치수 (뼈대 좌표, 반폭)
// ===================================================================

// 높이 기준(머리 단위): 턱 1, 목 밑 1.22, 어깨 1.36, 겨드랑이 1.68, 사타구니 3.98, 무릎 5.72, 발바닥 7.75
const _u = 43.0, _y0 = 12.0;
double _yl(double l) => _y0 + l * _u;
const _pit = 1.22, _sh = 1.36, _armpit = 1.68, _nip = 2.0, _ubust = 2.2;
const _navel = 3.0, _iliac = 3.2, _troch = 3.5, _crotch = 3.98, _knee = 5.72, _ankle = 7.42, _sole = 7.75;

class _Dims {
  final double f;
  final bool female;
  late final double neck, acro, trapDrop, chest, waist, iliac, hip, thigh, knee, calf, ankle;
  late final double uarm, farm, wrist, hand, belly;

  /// f: 마름 0 ~ 통통 1, mus: 근육 0 ~ 1 (0.5가 보통)
  _Dims(this.f, this.female, double mus) {
    double k(double a, double b, double c) => f < 0.5 ? _lerp(a, b, f * 2) : _lerp(b, c, (f - 0.5) * 2);
    final m = mus - 0.5;
    if (female) {
      neck = k(5.9, 6.4, 8.2);
      acro = k(28, 29, 31) + 2.5 * m;
      trapDrop = k(0.12, 0.14, 0.19);
      chest = k(23, 25, 31.5) + 1.5 * m;
      waist = k(19, 22, 32) - 1 * m;
      iliac = k(24.5, 27.5, 36.5);
      hip = k(28.5, 32, 41);
      thigh = k(22.5, 26.5, 36.5) + 2 * m;
      knee = k(13.5, 14.5, 18.5);
      calf = k(13.2, 15.4, 20.5) + 1.5 * m;
      ankle = k(7.2, 7.8, 9.6);
      uarm = k(9, 10.8, 16.8) + 2.5 * m;
      farm = k(7.8, 9, 12.2) + 1.2 * m;
      wrist = k(5.2, 5.6, 6.8);
      hand = k(7.2, 7.5, 8.4);
      belly = k(0, 0.12, 0.8);
    } else {
      neck = k(8.2, 9, 11.6);
      acro = k(33, 34, 36) + 4 * m;
      trapDrop = k(0.1, 0.12, 0.17);
      chest = k(28, 31, 37) + 3 * m;
      waist = k(23, 27, 38.5) - 1.5 * m;
      iliac = k(25, 28, 37.5);
      hip = k(27, 29.5, 36);
      thigh = k(23, 26.5, 34) + 2.5 * m;
      knee = k(15, 16, 19.5);
      calf = k(15, 17.2, 22) + 2 * m;
      ankle = k(8.5, 9, 10.8);
      uarm = k(11, 13.6, 18.4) + 3.5 * m;
      farm = k(9.8, 11.2, 13.6) + 1.8 * m;
      wrist = k(6.2, 6.6, 7.8);
      hand = k(8, 8.4, 9.4);
      belly = k(0, 0.15, 1);
    }
  }
}

class _LP {
  final Offset p;
  final int seg; // 0: 위쪽 뼈, 1: 아래쪽 뼈
  final double t;
  const _LP(this.p, this.seg, this.t);
}

class _Leg {
  final Offset h, k, a; // 엉덩관절, 무릎, 발목
  const _Leg(this.h, this.k, this.a);
}

class _Arm {
  final Offset sj, e, w; // 어깨, 팔꿈치, 손목
  const _Arm(this.sj, this.e, this.w);
}

// ===================================================================
// 캐릭터 한 명
// ===================================================================

class _Figure {
  final bool female, tired;
  final double f, mus;
  final Color hair, outfit;

  late final _Dims d;
  late final double waistLv, hj, thighT0, armT0;
  late final Offset neckPit, pelvis;
  late final Map<int, _Leg> legs;
  late final Map<int, _Arm> arms;

  // 3등신 변환
  static const top = 14.0, sole = 346.0, heads = 3.0;
  late final double hh, wh, chinY, sb, sxk, chibi, tl, syT, syL;

  _Figure({
    required this.female,
    required this.f,
    required this.mus,
    required this.hair,
    required this.outfit,
    required this.tired,
  }) {
    d = _Dims(f, female, mus);
    waistLv = female ? 2.72 : 2.86;
    neckPit = Offset(100, _yl(_pit));
    pelvis = Offset(100, _yl(_troch));
    hj = d.hip * (female ? 0.52 : 0.56);
    thighT0 = (_crotch - _troch) / (_knee - _troch);

    _Leg legAt(int s) {
      final h = pelvis + Offset(s * hj, 0);
      final a = Offset(100 + s * (d.ankle / 2 + 2.4 + f * 3.5) + s * 1.0, _yl(_ankle));
      final k0 = Offset.lerp(h, a, (_knee - _troch) / (_ankle - _troch))!;
      return _Leg(h, k0 - Offset(s * 1.5, 0), a);
    }

    legs = {-1: legAt(-1), 1: legAt(1)};

    const lu = 1.44 * _u, lf = 1.14 * _u;
    _Arm armAt(int s) {
      final sj = _shF(s, d.acro - d.uarm * 0.5 + 1, _sh - _pit + 0.04);
      final ab = (11 + f * 9 + (female ? 0 : 1.5)) * math.pi / 180;
      final e = sj + Offset(s * math.sin(ab) * lu, math.cos(ab) * lu);
      final ab2 = ab - 5 * math.pi / 180;
      return _Arm(sj, e, e + Offset(s * math.sin(ab2) * lf, math.cos(ab2) * lf));
    }

    arms = {-1: armAt(-1), 1: armAt(1)};
    armT0 = (_armpit - _sh) * _u / lu;

    final ht = sole - top;
    hh = ht / heads;
    chinY = top + hh;
    chibi = math.max(0.0, 6.5 - heads);
    sb = (ht - hh) / (_yl(_sole) - _yl(1));
    sxk = 1 + chibi * 0.16;
    final yc = _yl(1), ycr = _yl(_crotch), ys = _yl(_sole);
    tl = (ht - hh) * ((ycr - yc) / (ys - yc) + chibi * 0.012);
    syT = tl / (ycr - yc);
    syL = (ht - hh - tl) / (ys - ycr);
    wh = hh * ((female ? 0.8 : 0.83) + f * 0.07 + chibi * 0.035);
  }

  bool same(_Figure o) =>
      o.female == female && o.f == f && o.mus == mus && o.hair == hair && o.outfit == outfit && o.tired == tired;

  /// 뼈대 좌표 → 3등신 화면 좌표
  Offset t(Offset p) {
    final yc = _yl(1), ycr = _yl(_crotch);
    final y = p.dy <= ycr ? chinY + (p.dy - yc) * syT : chinY + tl + (p.dy - ycr) * syL;
    return Offset(100 + (p.dx - 100) * sb * sxk, y);
  }

  List<Offset> ts(Iterable<Offset> pts) => [for (final p in pts) t(p)];
  List<_Q> tq(Iterable<_Q> pts) => [for (final q in pts) q.map(t)];

  /// 머리 좌표: x는 머리 폭 배수(가운데 0), y는 머리 높이 배수(정수리 0, 턱 1)
  Offset hd(double x, double y) => Offset(100 + x * wh, top + y * hh);

  // ---------- 뼈대 ----------
  Offset _shF(int s, double w, double dl) => neckPit + Offset(s * w, dl * _u);
  Offset tp(double l, int s, double w) => Offset(100 + s * w, _yl(l));

  double torsoW(int s, double l, [double off = 0]) {
    final keys = female
        ? [
            (_armpit, d.chest * 0.96),
            (1.86, d.chest),
            (_nip, d.chest * 0.985),
            (_ubust, d.chest * 0.93),
            (waistLv, d.waist),
            (_navel, _lerp(d.waist, d.iliac, 0.45)),
            (_iliac, d.iliac),
            (3.38, _lerp(d.iliac, d.hip, 0.75)),
            (_troch, d.hip),
          ]
        : [
            (_armpit, d.chest),
            (1.98, d.chest * 0.985),
            (2.35, _lerp(d.chest, d.waist, 0.5)),
            (waistLv, d.waist),
            (_navel, d.waist + d.belly * 1.5),
            (_iliac, math.max(d.iliac, d.waist * 0.98)),
            (_troch, d.hip),
          ];
    return _interp(keys, l) + off;
  }

  Offset tw(double l, int s, [double off = 0]) => tp(l, s, torsoW(s, l, off));

  List<(Offset, double)> torsoSide(int s, double l0, double l1, [double off = 0, int n = 24]) =>
      [for (final l in _range(l0, l1, n)) (tw(l, s, off), l)];

  List<Offset> neckTrap(int s) => [
        for (final l in [0.86, 0.98, 1.1]) neckPit + Offset(s * (d.neck + (l - 0.86) * 4), (l - _pit) * _u),
        for (final u in _range(0, 1, 6))
          _shF(s, _lerp(d.neck + 2.6, d.acro, u), -0.02 + d.trapDrop * math.pow(u, 1.35).toDouble() + 0.02 * u),
      ];

  Offset _along(Offset p0, Offset p1, double t, double off, int s) {
    final dir = _norm(p1 - p0);
    return Offset.lerp(p0, p1, t)! + Offset(s * dir.dy, -s * dir.dx) * off;
  }

  List<_LP> legOuter(int s, [double off = 0]) {
    final g = legs[s]!;
    final hipEdge = torsoW(s, _troch);
    return [
      for (final t in _range(0.04, 1, 14))
        _LP(
            _along(g.h, g.k, t,
                _interp([(0, hipEdge - hj), (0.16, hipEdge - hj + 0.4), (0.45, d.thigh * 0.45), (0.78, d.knee * 0.6), (1, d.knee * 0.53)], t) + off,
                s),
            0,
            t),
      for (final t in _range(0.05, 1, 14))
        _LP(
            _along(g.k, g.a, t,
                _interp([(0, d.knee * 0.53), (0.1, d.knee * 0.5), (0.3, d.calf * 0.56), (0.62, d.calf * 0.42), (0.9, d.ankle * 0.58), (1, d.ankle * 0.52)], t) + off,
                s),
            1,
            t),
    ];
  }

  List<_LP> _legInnerRaw(int s, double off) {
    final g = legs[s]!;
    return [
      for (final t in _range(thighT0, 1, 12))
        _LP(
            _along(g.h, g.k, t, -(_interp([
                  (thighT0, (Offset.lerp(g.h, g.k, t)!.dx - pelvis.dx).abs() - 0.6),
                  (thighT0 + 0.14, d.thigh * 0.52),
                  (0.62, d.thigh * 0.41),
                  (0.9, d.knee * 0.56),
                  (1, d.knee * 0.5)
                ], t) + off), s),
            0,
            t),
      for (final t in _range(0.05, 1, 14))
        _LP(
            _along(g.k, g.a, t, -(_interp([(0, d.knee * 0.5), (0.16, d.knee * 0.5), (0.42, d.calf * 0.46), (0.72, d.calf * 0.33), (0.92, d.ankle * 0.6), (1, d.ankle * 0.5)], t) + off), s),
            1,
            t),
    ];
  }

  /// 안쪽 다리선. 허벅지가 맞닿으면 가운데로 모은다.
  Map<int, List<_LP>> legInners([double off = 0]) {
    final l = _legInnerRaw(-1, off), r = _legInnerRaw(1, off);
    for (var i = 0; i < l.length; i++) {
      final a = l[i].p, b = r[i].p;
      if (a.dx > b.dx - 0.7) {
        final m = (a.dx + b.dx) / 2;
        l[i] = _LP(Offset(m - 0.35, a.dy), l[i].seg, l[i].t);
        r[i] = _LP(Offset(m + 0.35, b.dy), r[i].seg, r[i].t);
      }
    }
    return {-1: l, 1: r};
  }

  List<Offset> armOuter(int s) {
    final g = arms[s]!;
    return [
      for (final t in _range(0, 1, 14))
        _along(g.sj, g.e, t, _interp([(0, d.uarm * 0.5), (0.12, d.uarm * 0.6), (0.24, d.uarm * 0.6), (0.5, d.uarm * 0.5), (0.85, d.uarm * 0.44), (1, d.uarm * 0.42)], t), s),
      for (final t in _range(0.06, 1, 12))
        _along(g.e, g.w, t, _interp([(0, d.uarm * 0.42), (0.2, d.farm * 0.57), (0.55, d.farm * 0.44), (1, d.wrist * 0.5)], t), s),
    ];
  }

  List<Offset> armInner(int s) {
    final g = arms[s]!;
    final sag = f > 0.5 ? (f - 0.5) * 2 * d.uarm * 0.1 : 0.0;
    return [
      for (final t in _range(armT0, 1, 10))
        _along(g.sj, g.e, t, -_interp([(armT0, d.uarm * 0.4), (0.45, d.uarm * 0.52 + sag), (0.75, d.uarm * 0.46), (1, d.farm * 0.5)], t), s),
      for (final t in _range(0.06, 1, 12))
        _along(g.e, g.w, t, -_interp([(0, d.farm * 0.5), (0.3, d.farm * 0.54), (0.7, d.farm * 0.4), (1, d.wrist * 0.5)], t), s),
    ];
  }

  /// 둥근 벙어리장갑 손: (윤곽, 손가락 결 선들)
  (List<Offset>, List<List<Offset>>) mitt(int s) {
    final g = arms[s]!;
    final dir = _norm(g.w - g.e), n = Offset(s * dir.dy, -s * dir.dx);
    final lh = 0.68 * _u, hw = d.hand * 0.86, wr = d.wrist * 0.5;
    Offset q(double a, double b) => g.w + dir * (a * lh) + n * b;
    return (
      [q(0, wr), q(0.22, hw * 0.66), q(0.5, hw * 0.7), q(0.78, hw * 0.58), q(0.95, hw * 0.3), q(1, 0), q(0.95, -hw * 0.32), q(0.8, -hw * 0.55), q(0.56, -hw * 0.6), q(0.42, -hw * 0.68), q(0.3, -hw * 0.9), q(0.17, -hw * 0.86), q(0.07, -hw * 0.66), q(0, -wr)],
      [
        [q(0.5, -hw * 0.42), q(0.3, -hw * 0.56)],
        [q(0.74, hw * 0.16), q(0.96, hw * 0.1)],
        [q(0.72, -hw * 0.16), q(0.94, -hw * 0.2)],
      ],
    );
  }

  List<Offset> foot(int s) {
    final a = legs[s]!.a, aw = d.ankle * 1.15, so = _yl(_sole), o = s * 1.4;
    return [
      Offset(a.dx + s * aw * 0.66, a.dy + 3.5),
      Offset(a.dx + s * aw * 0.92 + o * 0.5, so - 5.5),
      Offset(a.dx + s * aw * 1.02 + o, so - 1.8),
      Offset(a.dx + s * aw * 0.66 + o, so + 0.5),
      Offset(a.dx + s * aw * 0.05 + o, so + 0.9),
      Offset(a.dx - s * aw * 0.46 + o * 0.6, so + 0.5),
      Offset(a.dx - s * aw * 0.72, so - 1.8),
      Offset(a.dx - s * aw * 0.7, so - 6),
      Offset(a.dx - s * aw * 0.56, a.dy + 3),
    ];
  }

  /// 부위 이름표가 가리키는 점 (그림 좌표 200×360)
  Offset anchor(BodyPart p) => switch (p) {
        BodyPart.chest => t(Offset(100, _yl(female ? 1.8 : 1.85))),
        BodyPart.belly => t(Offset(100, _yl(_navel + 0.02))),
        BodyPart.arm => t(Offset.lerp(arms[1]!.sj, arms[1]!.e, 0.5)!),
        BodyPart.thigh => t(Offset.lerp(legs[1]!.h, legs[1]!.k, 0.5)!),
      };

  // ---------- 머리 ----------
  List<(double, double)> get _prof => female
      ? [(0, 0), (0.05, 0.5), (0.16, 0.84), (0.36, 1), (0.54, 0.99), (0.68, 0.92 + f * 0.03), (0.8, 0.77 + f * 0.07), (0.9, 0.55 + f * 0.08), (0.97, 0.27 + f * 0.06), (1, 0)]
      : [(0, 0), (0.05, 0.52), (0.16, 0.86), (0.36, 1), (0.55, 0.99), (0.7, 0.94 + f * 0.03), (0.82, 0.81 + f * 0.07), (0.92, 0.6 + f * 0.08), (0.98, 0.32 + f * 0.06), (1, 0)];

  double _hw(double y) {
    y = y.clamp(0.0, 1.0);
    final p = _prof;
    for (var i = 0; i < p.length - 1; i++) {
      final (l0, w0) = p[i];
      final (l1, w1) = p[i + 1];
      if (y <= l1) return (w0 + (w1 - w0) * (y - l0) / (l1 - l0)) / 2;
    }
    return 0;
  }

  /// 머리 윤곽을 따라 왼쪽 yL → 정수리 → 오른쪽 yR, 바깥으로 vol(px)만큼 띄운 점들
  List<Offset> _cap(double vol, double yL, double yR, [double? volTop]) {
    final vt = volTop ?? vol, c = hd(0, 0.5);
    Offset out(Offset p, double v) => p + _norm(p - c) * v;
    const n = 12;
    return [
      for (var k = 0; k <= n; k++)
        () {
          final u = k / n, y = yL * (1 - u) * (1 - u);
          return out(hd(-_hw(y), y), vol + (vt - vol) * (1 - y / yL));
        }(),
      for (var k = 1; k <= n; k++)
        () {
          final u = k / n, y = yR * u * u;
          return out(hd(_hw(y), y), vol + (vt - vol) * (1 - y / yR));
        }(),
    ];
  }

  List<_Q> _hp(List<(double, double, bool)> pts) => [for (final (x, y, c) in pts) _Q(hd(x, y), c)];

  /// 오른쪽 반만 주면 좌우 대칭으로 닫는다
  List<_Q> _sym(List<(double, double, bool)> r) => [
        ..._hp(r),
        for (final (x, y, c) in r.sublist(1).reversed) _Q(hd(-x, y), c),
      ];

  // ===================================================================
  void paint(Canvas c) {
    final dark = Color.lerp(outfit, Riso.ink, 0.38)!;
    final hairOpt = (base: 0.62, spacing: 3.0, width: 2.1, angle: 1.2, lw: 1.5);
    void hairPiece(List<_Q> q, int seed) => _piece(c, q, hair,
        seed: seed, base: hairOpt.base, spacing: hairOpt.spacing, width: hairOpt.width, angle: hairOpt.angle, lw: hairOpt.lw);

    // 발밑 그림자
    final shadow = Path()..addPolygon(_ellipse(const Offset(100, sole + 2), (46 + 16 * f) * sxk, 6, 24), true);
    Hand.hatch(c, shadow, Riso.ink.withValues(alpha: 0.22), angle: -0.3, spacing: 3, width: 1.4, base: 0, seed: 2);

    // ---------- 뒷머리 ----------
    if (female) {
      hairPiece(
          _sym([(0, -0.045, false), (0.3, -0.03, false), (0.49, 0.09, false), (0.6, 0.27, false), (0.62, 0.48, false), (0.63, 0.7, false), (0.65, 0.88, false), (0.62, 1.01, true), (0.5, 1.04, false), (0.38, 1.02, true), (0.33, 0.88, false), (0.3, 0.7, false)]),
          27);
    }

    // ---------- 몸 (목+몸통+팔+다리 한 덩어리) ----------
    final inners = legInners();
    final overlap = <int, List<Offset>>{};
    List<_Q> side(int s) {
      final nt = neckTrap(s);
      final ao = armOuter(s);
      var ai = armInner(s).reversed.toList();
      final tsAll = torsoSide(s, _armpit - 0.12, _troch);
      var tsp = [for (final e in tsAll) e.$1];
      // 겨드랑이: 팔 안쪽 선과 몸통 옆선이 만나는 점에서 자른다
      Offset? hit;
      var hi = 0, hj2 = 0;
      for (var i = 0; i < ai.length - 1 && hit == null; i++) {
        for (var j = 0; j < tsp.length - 1 && hit == null; j++) {
          final x = _segHit(ai[i], ai[i + 1], tsp[j], tsp[j + 1]);
          if (x != null) {
            hit = x;
            hi = i;
            hj2 = j;
          }
        }
      }
      final List<_Q> torso;
      if (hit != null) {
        overlap[s] = [hit, ...ai.sublist(hi + 1)];
        ai = [...ai.sublist(0, hi + 1), hit];
        torso = _qs(tsp.sublist(hj2 + 1));
      } else {
        final rest = [for (final e in tsAll) if (e.$2 >= _armpit + 0.02) e.$1];
        torso = [for (var i = 0; i < rest.length; i++) _Q(rest[i], i == 0)];
      }
      final aiQ = [for (var i = 0; i < ai.length; i++) _Q(ai[i], i == ai.length - 1)];
      final li = inners[s]!.reversed.toList();
      return [
        ..._qs(nt.sublist(0, nt.length - 1)),
        ..._qs(ao.sublist(1)),
        ..._qs(mitt(s).$1),
        ...aiQ,
        ...torso,
        ..._qs(legOuter(s).map((e) => e.p)),
        ..._qs(foot(s)),
        for (var i = 0; i < li.length; i++) _Q(li[i].p, i == li.length - 1),
      ];
    }

    final body = [...side(-1), ...side(1).reversed];
    _piece(c, tq(body), _skinInk, seed: 11);
    // 팔이 몸통 앞에 겹친 부분의 팔 안쪽 선
    for (final o in overlap.values) {
      if (o.length < 2) continue;
      final path = Path()..addPolygon(_smooth(_qs(ts(o)), closed: false), false);
      c.drawPath(
        Hand.wobble(path, amp: 0.6, seed: 90, step: 5).shift(const Offset(0.9, 0.55)),
        Paint()
          ..color = Riso.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ---------- 몸 결 선 ----------
    double yT(double l) => t(Offset(100, _yl(l))).dy;
    for (final s in [-1, 1]) {
      _line(c, ts([Offset(100 + s * (d.neck + 1.5), _yl(1.27)), Offset(100 + s * (d.neck + 7), _yl(1.3)), Offset(100 + s * d.acro * 0.66, _yl(1.27))]),
          alpha: 0.35, lw: 1.1, seed: 5 + s);
    }
    {
      final y = yT(_navel + 0.02), w = 1.1 + f * 0.8;
      _line(c, [Offset(100 - w * 0.4, y - 1.8), Offset(100 + w * 0.5, y), Offset(100 - w * 0.2, y + 1.9)], alpha: 0.65, lw: 1.2, seed: 9);
    }
    if (f > 0.55) {
      final k = (f - 0.55) / 0.45, y0 = yT(female ? 3.03 : 3.0), w = torsoW(1, 3.05) * sb * (0.62 + 0.12 * k);
      _line(c, [Offset(100 - w, y0 - 2), Offset(100 - w * 0.5, y0 + 3 + 3 * k), Offset(100, y0 + 4 + 4 * k), Offset(100 + w * 0.5, y0 + 3 + 3 * k), Offset(100 + w, y0 - 2)],
          alpha: 0.4 + 0.2 * k, lw: 1.3, seed: 13);
    }
    if (!female) {
      final drop = f * 0.1, a = (0.3 + 0.25 * mus).clamp(0.3, 0.55);
      for (final s in [-1, 1]) {
        _line(c, ts([Offset(100 + s * 1.5, _yl(2.04 + drop)), Offset(100 + s * d.chest * 0.5, _yl(2.08 + drop)), Offset(100 + s * d.chest * 0.82, _yl(1.94 + drop * 0.6)), Offset(100 + s * d.chest * 0.9, _yl(1.8))]),
            alpha: a, lw: 1.2, seed: 21 + s);
      }
    }
    for (final s in [-1, 1]) {
      final k = legs[s]!.k;
      _line(c, ts([Offset(k.dx - s * d.knee * 0.35, k.dy - 3), Offset(k.dx - s * d.knee * 0.05, k.dy + 1), Offset(k.dx + s * d.knee * 0.25, k.dy - 1)]),
          alpha: 0.32, lw: 1.1, seed: 31 + s);
      for (final fl in mitt(s).$2) {
        _line(c, ts(fl), alpha: 0.45, lw: 1, seed: 41 + s);
      }
      final a = legs[s]!.a, so = _yl(_sole);
      _line(c, ts([Offset(a.dx - s * d.ankle * 0.1, so - 3.2), Offset(a.dx - s * d.ankle * 0.14, so + 0.4)]), alpha: 0.4, lw: 1, seed: 45 + s);
    }

    // ---------- 속옷 ----------
    void cloth(List<_Q> q, Color ink, int seed, {double angle = 0.5, bool band = false}) => _piece(c, tq(q), ink,
        seed: seed, base: band ? 0.6 : 0.5, spacing: band ? 2.8 : 3.2, width: band ? 1.9 : 2.2, angle: angle, lw: band ? 1.3 : 1.5);
    List<_Q> bandAt(double l, double mid, double h, double off) => [
          _Q(tw(l, -1, off), true),
          _Q(Offset(100, _yl(mid))),
          _Q(tw(l, 1, off), true),
          _Q(tw(l + h, 1, off), true),
          _Q(Offset(100, _yl(mid + h))),
          _Q(tw(l + h, -1, off), true),
        ];

    if (female) {
      // 팬티 (허리선은 배꼽 아래)
      const wl = 3.13, wc = 3.16, sl = 3.45;
      final lp = inners[-1]!, rp = inners[1]!;
      final il = Offset.lerp(lp[0].p, lp[1].p, 0.45)!, ir = Offset.lerp(rp[0].p, rp[1].p, 0.45)!;
      Offset sideAt(int s) => tw(sl, s, 0.7);
      Offset mid(int s, Offset i) => Offset(_lerp(sideAt(s).dx, i.dx, 0.6), _lerp(sideAt(s).dy, i.dy, 0.36));
      cloth([
        _Q(tw(wl, -1, 0.7), true), _Q(Offset(100, _yl(wc))), _Q(tw(wl, 1, 0.7), true),
        _Q(tw(3.3, 1, 0.7)), _Q(sideAt(1), true), _Q(mid(1, ir)), _Q(Offset(ir.dx + 0.6, ir.dy + 1), true),
        _Q(Offset(100, ir.dy + 1.8)),
        _Q(Offset(il.dx - 0.6, il.dy + 1), true), _Q(mid(-1, il)), _Q(sideAt(-1), true), _Q(tw(3.3, -1, 0.7)),
      ], outfit, 15);
      cloth(bandAt(wl, wc, 0.075, 0.7), dark, 16, band: true);

      // 스포츠 브라
      Offset trap(int s, double u) =>
          _shF(s, _lerp(d.neck + 2.6, d.acro, u), -0.02 + d.trapDrop * math.pow(u, 1.35).toDouble() + 0.02 * u) + const Offset(0, 0.4);
      const bb = _ubust + 0.09;
      List<_Q> half(int s) => [
            _Q(trap(s, 0.2), true),
            _Q(trap(s, 0.5), true),
            _Q(tp(1.52, s, d.chest * 0.8)),
            _Q(tw(_armpit + 0.05, s, 0.7)),
            _Q(tw(1.95, s, 0.7)),
            _Q(tw(bb, s, 0.7), true),
          ];
      List<_Q> neckline(int s) => [_Q(tp(1.5, s, d.neck + 5.5)), _Q(tp(1.68, s, d.chest * 0.42))];
      cloth([
        ...half(-1),
        _Q(Offset(100, _yl(bb + 0.012))),
        ...half(1).reversed,
        ...neckline(1),
        _Q(Offset(100, _yl(1.77))),
        ...neckline(-1).reversed,
      ], outfit, 17, angle: -0.55);
      cloth(bandAt(_ubust - 0.03, _ubust - 0.03 + 0.012, 0.12, 0.7), dark, 18, angle: -0.55, band: true);
      for (final s in [-1, 1]) {
        _line(c, ts([Offset(100 + s * 1.2, _yl(1.86)), Offset(100 + s * d.chest * 0.32, _yl(2.08)), Offset(100 + s * d.chest * 0.72, _yl(2.03))]),
            alpha: 0.32, lw: 1.1, seed: 51 + s);
      }
    } else {
      // 드로즈
      const wl = 3.11, wc = 3.14, o = 0.7;
      const hemLv = _crotch + 0.4;
      final ht = (hemLv - _troch) / (_knee - _troch);
      final inn = legInners(o);
      Offset hemOut(int s) {
        final g = legs[s]!, dir = _norm(g.k - g.h), n = Offset(s * dir.dy, -s * dir.dx);
        final ow = _interp([(0, torsoW(s, _troch) - hj), (0.16, torsoW(s, _troch) - hj + 0.4), (0.45, d.thigh * 0.45), (0.78, d.knee * 0.6)], ht);
        return Offset.lerp(g.h, g.k, ht)! + n * (ow + o);
      }

      Offset hemIn(int s) {
        final g = legs[s]!, dir = _norm(g.k - g.h), n = Offset(s * dir.dy, -s * dir.dx);
        final ow = _interp([(thighT0 + 0.14, d.thigh * 0.52), (0.62, d.thigh * 0.41)], ht);
        return Offset.lerp(g.h, g.k, ht)! + n * -(ow + o);
      }

      List<Offset> outerTo(int s) => [for (final e in legOuter(s, o)) if (e.seg == 0 && e.t <= ht) e.p];
      List<Offset> innerTo(int s) => [for (final e in inn[s]!) if (e.seg == 0 && e.t <= ht) e.p];
      final sl = [for (final e in torsoSide(-1, wl, _troch, o, 8)) e.$1];
      final sr = [for (final e in torsoSide(1, wl, _troch, o, 8)) e.$1];
      Offset hemMid(int s) => Offset.lerp(hemOut(s), hemIn(s), 0.5)! + const Offset(0, 0.8);
      final li = innerTo(-1), ri = innerTo(1);
      cloth([
        _Q(sl.first, true), _Q(Offset(100, _yl(wc))), _Q(sr.first, true), ..._qs(sr.sublist(1)),
        ..._qs(outerTo(1)), _Q(hemOut(1), true), _Q(hemMid(1)), _Q(hemIn(1), true), ..._qs(ri.reversed),
        for (var i = 0; i < li.length; i++) _Q(li[i], i == 0),
        _Q(hemIn(-1), true), _Q(hemMid(-1)), _Q(hemOut(-1), true), ..._qs(outerTo(-1).reversed),
        ..._qs(sl.sublist(1).reversed),
      ], outfit, 15);
      cloth(bandAt(wl, wc, 0.1, o), dark, 16, band: true);
      _line(c, ts([Offset(98.5, _yl(wc + 0.12)), Offset(97.8, _yl(3.55)), Offset(99.5, _yl(3.82)), Offset(103, _yl(3.9))]), alpha: 0.45, lw: 1.1, seed: 61);
      for (final s in [-1, 1]) {
        final up = Offset(0, -2.6 / sb);
        _line(c, ts([hemOut(s) + up, hemMid(s) + up, hemIn(s) + up]), alpha: 0.45, lw: 1.1, seed: 63);
      }
    }

    // ---------- 귀, 얼굴 ----------
    if (!female) {
      for (final s in [-1, 1]) {
        _piece(c, _qs(_ellipse(hd(s * 0.525, 0.585), hh * 0.085, hh * 0.13, 14)), _skinInk,
            seed: 70 + s, spacing: 3.2, width: 2, lw: 1.4);
      }
    }
    final prof = _prof;
    final head = [
      for (final (l, w) in prof) hd(w / 2, l),
      for (final (l, w) in prof.sublist(1, prof.length - 1).reversed) hd(-w / 2, l),
    ];
    _piece(c, _qs(head), _skinInk, seed: 29, base: 0.4, spacing: 4, width: 2.4);

    // 볼
    for (final s in [-1, 1]) {
      final cheek = Path()
        ..addOval(Rect.fromCenter(
            center: hd(s * 0.3, 0.7 + chibi * 0.008), width: hh * (0.095 + f * 0.012) * 2, height: hh * (0.06 + f * 0.008) * 2));
      Hand.hatch(c, cheek, Riso.pink.withValues(alpha: 0.75), angle: -0.7, spacing: 2, width: 1.3, base: 0.25, seed: 80 + s);
    }
    // 눈
    final ek = 1 + chibi * 0.06, ey = 0.565 + chibi * 0.008;
    final ink = Paint()..color = Riso.ink;
    final pen = Paint()
      ..color = Riso.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in [-1, 1]) {
      final e = hd(s * 0.205, ey);
      if (tired) {
        final r = hh * 0.05;
        c.drawPath(
            Path()
              ..moveTo(e.dx - s * r, e.dy - r * 0.7)
              ..lineTo(e.dx + s * r * 0.8, e.dy)
              ..lineTo(e.dx - s * r, e.dy + r * 0.7),
            pen);
      } else {
        c.drawOval(Rect.fromCenter(center: e, width: hh * 0.047 * ek * 2, height: hh * 0.063 * ek * 2), ink);
        c.drawCircle(e + Offset(hh * 0.017 * ek, -hh * 0.028 * ek), hh * 0.018 * ek, Paint()..color = Colors.white);
      }
    }
    // 눈썹: 여자는 가늘고 둥글게, 남자는 굵고 일자에 가깝게. 지치면 안쪽이 올라간다
    {
      final by = ey - 0.063 * ek - 0.075;
      final lw = hh * (female ? 0.021 : 0.03), arch = female ? 0.022 : 0.014;
      final browInk = Color.lerp(hair, Riso.ink, 0.5)!;
      for (final s in [-1, 1]) {
        final xi = s * (0.205 - 0.068), xo = s * (0.205 + 0.07);
        _line(c, [
          for (final u in [0.0, 0.5, 1.0])
            hd(xi + (xo - xi) * u, by + 0.008 * u - arch * math.sin(math.pi * u) + (tired ? -0.03 * (1 - u) : 0)),
        ], alpha: 0.95, lw: lw, seed: 90 + s, amp: 0.15, color: browInk);
      }
    }
    // 입
    {
      final y = top + hh * (0.745 + chibi * 0.007), w = hh * 0.07;
      if (tired) {
        final m = Path()
          ..moveTo(100 - w, y + hh * 0.02)
          ..quadraticBezierTo(100 - w / 2, y - hh * 0.02, 100, y + hh * 0.02)
          ..quadraticBezierTo(100 + w / 2, y + hh * 0.06, 100 + w, y + hh * 0.02);
        c.drawPath(m, pen..strokeWidth = 1.5);
      } else {
        _line(c, [Offset(100 - w, y), Offset(100, y + hh * 0.05), Offset(100 + w, y)], alpha: 1, lw: 1.5, seed: 35, amp: 0.25);
      }
    }

    // ---------- 앞머리 ----------
    if (female) {
      hairPiece([
        ..._wrap(_cap(2.5, 0.62, 0.62)),
        ..._hp([(0.47, 0.48, false), (0.38, 0.35, false), (0.22, 0.27, false), (0.04, 0.25, true), (-0.04, 0.3, false), (-0.2, 0.28, false), (-0.38, 0.35, false), (-0.47, 0.48, false)]),
      ], 31);
    } else {
      hairPiece([
        ..._wrap(_cap(3.5, 0.52, 0.52, 4.5)),
        ..._hp([(0.49, 0.5, false), (0.47, 0.36, false), (0.41, 0.27, false), (0.22, 0.21, false), (0.0, 0.24, true), (-0.16, 0.17, false), (-0.36, 0.23, false), (-0.46, 0.33, false), (-0.49, 0.5, false)]),
      ], 31);
    }

    // 지쳤을 때 땀방울
    if (tired) {
      final p = hd(0.62, 0.12), r = hh * 0.06;
      final drop = Path()
        ..moveTo(p.dx, p.dy - r * 1.6)
        ..quadraticBezierTo(p.dx + r * 1.1, p.dy, p.dx, p.dy + r * 0.6)
        ..quadraticBezierTo(p.dx - r * 1.1, p.dy, p.dx, p.dy - r * 1.6);
      c.drawPath(drop, Paint()..color = Riso.sheet);
      Hand.hatch(c, drop, Riso.blue, angle: -0.55, spacing: 2.4, width: 1.6, base: 0.4, seed: 33);
      Hand.outline(c, drop, width: 1.3, amp: 0.3, seed: 34, shift: const Offset(0.6, 0.4));
    }
  }
}

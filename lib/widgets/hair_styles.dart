// 머리 스타일. 시안 생성기(character-concepts/hair.js)를 그대로 옮긴 것.
// 좌표는 머리 단위: x는 머리 폭 배수(가운데 0), y는 머리 높이 배수(정수리 0, 턱 1).
// 층: back(몸보다 먼저), mid(몸 다음·얼굴 전), top(얼굴 다음, 똥머리 등), front(앞머리), over(머리끈), lines(결 선)
part of 'character.dart';

/// 꾸미기에서 고르는 머리 스타일 목록. 여자는 한국 20대가 많이 하는 스타일 10개.
class HairStyles {
  static const female = [
    ('bob', '보브 단발'),
    ('ccurl', '단발 C컬'),
    ('hush', '허쉬컷'),
    ('layered', '레이어드컷'),
    ('long', '시스루뱅 생머리'),
    ('wave', '긴 웨이브'),
    ('hime', '히메컷'),
    ('pony', '포니테일'),
    ('bun', '똥머리'),
    ('pixie', '숏컷'),
  ];
  static const male = [
    ('crop', '기본 짧은 머리'),
    ('twoblock', '투블럭'),
    ('part', '가르마펌'),
    ('dandy', '댄디컷'),
    ('buzz', '버즈컷'),
    ('comma', '쉼표머리'),
    ('slick', '올백'),
    ('perm', '곱슬 파마'),
    ('long', '장발'),
    ('spiky', '세운 머리'),
  ];

  static List<(String, String)> of(Gender g) => g == Gender.female ? female : male;

  /// 성별에 없는 스타일이면 기본값으로
  static String resolve(Gender g, String? id) {
    final list = of(g);
    return list.any((e) => e.$1 == id) ? id! : list.first.$1;
  }

  static String label(Gender g, String? id) {
    final r = resolve(g, id);
    return of(g).firstWhere((e) => e.$1 == r).$2;
  }
}

enum _HK { hair, tie, short }

class _HP {
  final List<_Q> pts;
  final _HK kind;
  const _HP(this.pts) : kind = _HK.hair;
  const _HP.tie(this.pts) : kind = _HK.tie;
  const _HP.short(this.pts) : kind = _HK.short;
}

class _HL {
  final List<Offset> pts;
  final double alpha;
  const _HL(this.pts, this.alpha);
}

class _HairSet {
  final back = <_HP>[], mid = <_HP>[], top = <_HP>[], front = <_HP>[], over = <_HP>[];
  final lines = <_HL>[];
  bool ears = false;
}

List<(double, double, bool)> _mx(List<(double, double, bool)> pts, double sd) =>
    [for (final (x, y, c) in pts) (x * sd, y, c)];

List<Offset> _resample(List<Offset> pts, int n) {
  final cum = <double>[0];
  for (var i = 1; i < pts.length; i++) {
    cum.add(cum[i - 1] + (pts[i] - pts[i - 1]).distance);
  }
  final total = cum.last;
  final res = <Offset>[];
  var j = 0;
  for (var k = 0; k <= n; k++) {
    final d = total * k / n;
    while (j < pts.length - 2 && cum[j + 1] < d) {
      j++;
    }
    final seg = cum[j + 1] - cum[j];
    final t = seg == 0 ? 0.0 : (d - cum[j]) / seg;
    res.add(Offset.lerp(pts[j], pts[j + 1], t)!);
  }
  return res;
}

extension _HairKit on _Figure {
  List<_Q> _fringe(double vol, double yL, double yR, List<(double, double, bool)> edge, [double? volTop]) =>
      [..._wrap(_cap(vol, yL, yR, volTop)), ..._hp(edge)];

  List<Offset> _el(Offset c, double rx, double ry, double rot, int n) => [
        for (var i = 0; i < n; i++)
          () {
            final a = i / n * 2 * math.pi, x = math.cos(a) * rx, y = math.sin(a) * ry;
            return c + Offset(x * math.cos(rot) - y * math.sin(rot), x * math.sin(rot) + y * math.cos(rot));
          }(),
      ];

  _HL _hl(List<(double, double, bool)> pts, double alpha) => _HL([for (final (x, y, _) in pts) hd(x, y)], alpha);

  /// 뽀글뽀글 테두리: 이음점은 꺾이고 가운데가 바깥으로 볼록
  List<_Q> _scallop(List<Offset> pts, int n, double amp, [Offset? from]) {
    final o = from ?? hd(0, 0.5);
    final r = _resample(pts, n);
    return [
      for (var k = 0; k < n; k++) ...[
        _Q(r[k], true),
        () {
          final m = (r[k] + r[k + 1]) / 2;
          return _Q(m + _norm(m - o) * amp);
        }(),
      ],
      _Q(r[n], true),
    ];
  }

  /// 뾰족뾰족: 골과 끝 모두 꺾임
  List<_Q> _spikes(List<Offset> pts, int n, double amp) {
    final o = hd(0, 0.5);
    final r = _resample(pts, n);
    return [
      for (var k = 0; k < n; k++) ...[
        _Q(r[k], true),
        () {
          final m = (r[k] + r[k + 1]) / 2;
          return _Q(m + _norm(m - o) * amp, true);
        }(),
      ],
      _Q(r[n], true),
    ];
  }

  _HairSet _hairSet(String id) {
    final s = _HairSet();
    if (female) {
      switch (id) {
        case 'bob':
          s.back.add(_HP(_sym([
            (0, -0.045, false),
            (0.3, -0.03, false),
            (0.49, 0.09, false),
            (0.6, 0.27, false),
            (0.62, 0.48, false),
            (0.63, 0.7, false),
            (0.65, 0.88, false),
            (0.62, 1.01, true),
            (0.5, 1.04, false),
            (0.38, 1.02, true),
            (0.33, 0.88, false),
            (0.3, 0.7, false)
          ])));
          s.front.add(_HP(_fringe(2.5, 0.62, 0.62, [
            (0.47, 0.48, false),
            (0.38, 0.35, false),
            (0.22, 0.27, false),
            (0.04, 0.25, true),
            (-0.04, 0.3, false),
            (-0.2, 0.28, false),
            (-0.38, 0.35, false),
            (-0.47, 0.48, false)
          ])));
        case 'long':
          s.back.add(_HP(_sym([
            (0, -0.05, false),
            (0.3, -0.03, false),
            (0.5, 0.1, false),
            (0.58, 0.3, false),
            (0.6, 0.6, false),
            (0.62, 0.95, false),
            (0.66, 1.3, false),
            (0.7, 1.58, false),
            (0.68, 1.66, true),
            (0.5, 1.7, false),
            (0.32, 1.64, true),
            (0.3, 1.2, false),
            (0.28, 0.8, false)
          ])));
          s.front.add(_HP(_fringe(2.5, 0.64, 0.64, [
            (0.48, 0.58, false),
            (0.45, 0.42, false),
            (0.38, 0.36, true),
            (0.32, 0.28, false),
            (0.25, 0.37, true),
            (0.18, 0.28, false),
            (0.1, 0.38, true),
            (0.03, 0.29, false),
            (-0.05, 0.38, true),
            (-0.12, 0.28, false),
            (-0.2, 0.37, true),
            (-0.28, 0.28, false),
            (-0.36, 0.36, true),
            (-0.45, 0.42, false),
            (-0.48, 0.58, false)
          ])));
        case 'hush':
          s.back.add(_HP(_sym([
            (0, -0.08, false),
            (0.33, -0.06, false),
            (0.55, 0.1, false),
            (0.65, 0.3, false),
            (0.68, 0.5, false),
            (0.73, 0.64, true),
            (0.68, 0.7, false),
            (0.71, 0.88, false),
            (0.77, 1.0, true),
            (0.71, 1.04, false),
            (0.72, 1.16, false),
            (0.74, 1.26, true),
            (0.64, 1.22, false),
            (0.56, 1.28, true),
            (0.48, 1.2, false),
            (0.41, 1.23, true),
            (0.35, 1.04, false),
            (0.31, 0.78, false)
          ])));
          s.front.add(_HP(_fringe(
              3.5,
              0.6,
              0.6,
              [
                (0.5, 0.6, false),
                (0.45, 0.42, false),
                (0.34, 0.27, false),
                (0.16, 0.2, false),
                (0.03, 0.14, true),
                (-0.03, 0.14, false),
                (-0.16, 0.2, false),
                (-0.34, 0.27, false),
                (-0.45, 0.42, false),
                (-0.5, 0.6, false)
              ],
              5)));
          for (final sd in [-1.0, 1.0]) {
            s.front.add(_HP(_hp(_mx([
              (0.44, 0.42, false),
              (0.51, 0.56, false),
              (0.53, 0.72, false),
              (0.5, 0.9, true),
              (0.45, 0.74, false),
              (0.41, 0.56, false)
            ], sd))));
          }
          s.lines.add(_hl([(0.03, 0.14, false), (0.12, 0.04, false), (0.2, -0.02, false)], 0.4));
          s.lines.add(_hl([(0.62, 0.34, false), (0.66, 0.5, false), (0.72, 0.62, false)], 0.4));
          s.lines.add(_hl([(-0.62, 0.34, false), (-0.66, 0.5, false), (-0.72, 0.62, false)], 0.4));
        case 'layered':
          s.back.add(_HP(_sym([
            (0, -0.06, false),
            (0.32, -0.04, false),
            (0.52, 0.1, false),
            (0.6, 0.3, false),
            (0.62, 0.55, false),
            (0.64, 0.8, false),
            (0.73, 0.98, true),
            (0.65, 1.0, false),
            (0.67, 1.2, false),
            (0.71, 1.42, false),
            (0.81, 1.6, true),
            (0.67, 1.6, false),
            (0.53, 1.66, false),
            (0.4, 1.6, true),
            (0.34, 1.25, false),
            (0.3, 0.85, false)
          ])));
          s.front.add(_HP(_fringe(2.5, 0.64, 0.64, [
            (0.48, 0.6, false),
            (0.44, 0.44, false),
            (0.36, 0.3, false),
            (0.2, 0.2, false),
            (0.06, 0.13, true),
            (-0.06, 0.18, false),
            (-0.24, 0.26, false),
            (-0.38, 0.38, false),
            (-0.48, 0.6, false)
          ])));
          for (final sd in [-1.0, 1.0]) {
            s.front.add(_HP(_hp(_mx([
              (0.46, 0.5, false),
              (0.53, 0.66, false),
              (0.56, 0.84, false),
              (0.63, 0.99, true),
              (0.51, 0.93, false),
              (0.45, 0.76, false),
              (0.42, 0.6, false)
            ], sd))));
          }
          s.lines.add(_hl([(0.5, 1.1, false), (0.52, 1.3, false), (0.58, 1.48, false)], 0.4));
          s.lines.add(_hl([(-0.5, 1.1, false), (-0.52, 1.3, false), (-0.58, 1.48, false)], 0.4));
        case 'hime':
          s.back.add(_HP(_sym([
            (0, -0.05, false),
            (0.3, -0.03, false),
            (0.5, 0.1, false),
            (0.58, 0.3, false),
            (0.6, 0.6, false),
            (0.61, 1.0, false),
            (0.62, 1.4, false),
            (0.63, 1.62, true),
            (0.31, 1.62, true),
            (0.29, 1.2, false),
            (0.28, 0.8, false)
          ])));
          for (final sd in [-1.0, 1.0]) {
            s.front.add(_HP(_hp(_mx([
              (0.41, 0.34, false),
              (0.49, 0.38, false),
              (0.54, 0.5, false),
              (0.56, 0.75, false),
              (0.57, 0.97, true),
              (0.39, 0.97, true),
              (0.4, 0.72, false),
              (0.39, 0.5, false)
            ], sd))));
          }
          s.front.add(_HP(_fringe(2.5, 0.6, 0.6, [
            (0.48, 0.5, false),
            (0.47, 0.38, false),
            (0.44, 0.34, true),
            (0.22, 0.345, false),
            (0, 0.34, false),
            (-0.22, 0.345, false),
            (-0.44, 0.34, true),
            (-0.47, 0.38, false),
            (-0.48, 0.5, false)
          ])));
        case 'pony':
          s.ears = true;
          s.back.add(_HP(_hp([
            (0.1, -0.06, false),
            (0.28, -0.17, false),
            (0.5, -0.15, false),
            (0.68, 0.02, false),
            (0.78, 0.3, false),
            (0.77, 0.6, false),
            (0.7, 0.86, false),
            (0.6, 1.02, true),
            (0.62, 0.78, false),
            (0.63, 0.52, false),
            (0.57, 0.27, false),
            (0.43, 0.08, false),
            (0.25, 0.02, false)
          ])));
          s.back.add(_HP.tie(_qs(_el(hd(0.22, -0.085), wh * 0.075, hh * 0.05, -0.5, 12))));
          s.front.add(_HP(_fringe(
              1.6,
              0.52,
              0.52,
              [
                (0.47, 0.46, false),
                (0.4, 0.27, false),
                (0.22, 0.19, false),
                (0.02, 0.24, false),
                (-0.18, 0.32, false),
                (-0.34, 0.38, false),
                (-0.42, 0.44, true),
                (-0.47, 0.52, false)
              ],
              2.2)));
          s.lines.add(_hl([(0.3, 0.06, false), (0.12, 0.1, false), (-0.08, 0.17, false)], 0.4));
        case 'bun':
          s.ears = true;
          s.top.add(_HP(_qs(_el(hd(0, -0.13), wh * 0.21, hh * 0.165, 0, 18))));
          s.over.add(_HP.tie(_qs(_el(hd(0, -0.01), wh * 0.14, hh * 0.032, 0, 12))));
          s.front.add(_HP(_fringe(
              1.4,
              0.5,
              0.5,
              [
                (0.47, 0.46, false),
                (0.43, 0.3, false),
                (0.3, 0.2, false),
                (0.1, 0.17, false),
                (-0.1, 0.17, false),
                (-0.3, 0.2, false),
                (-0.43, 0.3, false),
                (-0.47, 0.46, false)
              ],
              2)));
          s.lines.add(_hl([
            (-0.1, -0.2, false),
            (0.04, -0.24, false),
            (0.13, -0.14, false),
            (0.02, -0.06, false),
            (-0.08, -0.12, false)
          ], 0.45));
          s.lines.add(_hl([(0.46, 0.5, false), (0.5, 0.58, false), (0.47, 0.66, false)], 0.5));
          s.lines.add(_hl([(-0.46, 0.5, false), (-0.5, 0.58, false), (-0.47, 0.66, false)], 0.5));
        case 'pixie':
          s.ears = true;
          s.back.add(_HP(_sym([
            (0, -0.06, false),
            (0.32, -0.04, false),
            (0.5, 0.1, false),
            (0.56, 0.32, false),
            (0.55, 0.55, false),
            (0.5, 0.72, true),
            (0.4, 0.66, false)
          ])));
          s.front.add(_HP(_fringe(
              3,
              0.6,
              0.52,
              [
                (0.47, 0.52, false),
                (0.45, 0.4, false),
                (0.38, 0.29, false),
                (0.2, 0.24, false),
                (0.02, 0.28, false),
                (-0.16, 0.36, false),
                (-0.3, 0.42, false),
                (-0.4, 0.47, true),
                (-0.42, 0.54, false),
                (-0.48, 0.6, false)
              ],
              4)));
        case 'wave':
          final r = <(double, double, bool)>[
            (0, -0.06, false),
            (0.32, -0.04, false),
            (0.52, 0.1, false),
            (0.6, 0.3, false),
            (0.64, 0.5, false),
            (0.6, 0.66, false),
            (0.69, 0.84, false),
            (0.63, 1.02, false),
            (0.73, 1.18, false),
            (0.67, 1.34, false),
            (0.75, 1.5, false),
            (0.67, 1.64, true),
            (0.57, 1.6, false),
            (0.47, 1.66, false),
            (0.36, 1.58, true),
            (0.32, 1.2, false),
            (0.3, 0.8, false)
          ];
          s.back.add(_HP(_sym(r)));
          s.front.add(_HP(_fringe(
              3,
              0.66,
              0.6,
              [
                (0.5, 0.56, false),
                (0.43, 0.33, false),
                (0.3, 0.18, false),
                (0.16, 0.1, true),
                (0.0, 0.2, false),
                (-0.2, 0.3, false),
                (-0.38, 0.43, false),
                (-0.5, 0.64, false)
              ],
              3.5)));
          s.lines.add(_hl([(0.16, 0.1, false), (0.24, 0.02, false), (0.3, -0.03, false)], 0.4));
        case 'ccurl':
          s.back.add(_HP(_sym([
            (0, -0.05, false),
            (0.3, -0.03, false),
            (0.5, 0.1, false),
            (0.6, 0.3, false),
            (0.63, 0.55, false),
            (0.66, 0.8, false),
            (0.68, 0.98, false),
            (0.65, 1.1, false),
            (0.56, 1.16, false),
            (0.44, 1.11, true),
            (0.37, 0.92, false),
            (0.31, 0.72, false)
          ])));
          s.lines.add(_hl([(0.6, 0.86, false), (0.6, 1.0, false), (0.53, 1.08, false)], 0.4));
          s.lines.add(_hl([(-0.6, 0.86, false), (-0.6, 1.0, false), (-0.53, 1.08, false)], 0.4));
          s.front.add(_HP(_fringe(2.5, 0.64, 0.64, [
            (0.48, 0.58, false),
            (0.42, 0.36, false),
            (0.26, 0.18, false),
            (0.07, 0.11, false),
            (0, 0.14, true),
            (-0.07, 0.11, false),
            (-0.26, 0.18, false),
            (-0.42, 0.36, false),
            (-0.48, 0.58, false)
          ])));
      }
    } else {
      switch (id) {
        case 'crop':
          s.ears = true;
          s.front.add(_HP(_fringe(
              3.5,
              0.52,
              0.52,
              [
                (0.49, 0.5, false),
                (0.47, 0.36, false),
                (0.41, 0.27, false),
                (0.22, 0.21, false),
                (0.0, 0.24, true),
                (-0.16, 0.17, false),
                (-0.36, 0.23, false),
                (-0.46, 0.33, false),
                (-0.49, 0.5, false)
              ],
              4.5)));
        case 'twoblock':
          s.ears = true;
          s.front.add(_HP.short(_fringe(
              1.2, 0.56, 0.56, [(0.48, 0.5, false), (0.47, 0.4, false), (-0.47, 0.4, false), (-0.48, 0.5, false)])));
          s.front.add(_HP(_fringe(
              5,
              0.42,
              0.42,
              [
                (0.54, 0.43, false),
                (0.47, 0.34, false),
                (0.3, 0.31, false),
                (0.12, 0.33, false),
                (-0.04, 0.29, true),
                (-0.22, 0.33, false),
                (-0.4, 0.31, false),
                (-0.54, 0.42, false)
              ],
              6)));
        case 'part':
          s.ears = true;
          s.front.add(_HP(_fringe(
              3.5,
              0.5,
              0.5,
              [
                (0.49, 0.5, false),
                (0.47, 0.36, false),
                (0.42, 0.26, false),
                (0.3, 0.2, false),
                (0.18, 0.12, true),
                (0.05, 0.2, false),
                (-0.1, 0.3, false),
                (-0.24, 0.34, false),
                (-0.34, 0.31, false),
                (-0.38, 0.27, true),
                (-0.44, 0.33, false),
                (-0.49, 0.5, false)
              ],
              6)));
          s.lines.add(_hl([(0.18, 0.12, false), (0.2, 0.05, false), (0.21, 0.0, false)], 0.45));
          s.lines.add(_hl([(0.06, 0.08, false), (-0.12, 0.14, false), (-0.28, 0.24, false)], 0.35));
        case 'dandy':
          s.ears = true;
          s.front.add(_HP(_fringe(
              3.5,
              0.56,
              0.56,
              [
                (0.5, 0.56, false),
                (0.47, 0.43, false),
                (0.38, 0.37, false),
                (0.2, 0.38, false),
                (0, 0.36, false),
                (-0.2, 0.38, false),
                (-0.38, 0.37, false),
                (-0.47, 0.43, false),
                (-0.5, 0.56, false)
              ],
              5.5)));
          s.lines.add(_hl([(0.12, 0.2, false), (0.14, 0.34, false)], 0.35));
          s.lines.add(_hl([(-0.1, 0.2, false), (-0.12, 0.33, false)], 0.35));
        case 'buzz':
          s.ears = true;
          s.front.add(_HP.short(_fringe(
              1.0,
              0.46,
              0.46,
              [
                (0.47, 0.46, false),
                (0.44, 0.32, false),
                (0.34, 0.22, false),
                (0.15, 0.18, false),
                (-0.15, 0.18, false),
                (-0.34, 0.22, false),
                (-0.44, 0.32, false),
                (-0.47, 0.46, false)
              ],
              1.6)));
        case 'comma':
          s.ears = true;
          s.front.add(_HP(_fringe(
              4,
              0.5,
              0.52,
              [
                (0.5, 0.52, false),
                (0.46, 0.38, false),
                (0.36, 0.3, false),
                (0.22, 0.31, false),
                (0.1, 0.35, false),
                (0.0, 0.38, false),
                (-0.1, 0.41, false),
                (-0.2, 0.39, false),
                (-0.25, 0.32, false),
                (-0.22, 0.25, false),
                (-0.16, 0.26, true),
                (-0.24, 0.2, false),
                (-0.37, 0.24, false),
                (-0.46, 0.34, false),
                (-0.5, 0.5, false)
              ],
              5.5)));
        case 'slick':
          s.ears = true;
          s.front.add(_HP(_fringe(
              2.5,
              0.48,
              0.48,
              [
                (0.47, 0.48, false),
                (0.45, 0.34, false),
                (0.38, 0.2, false),
                (0.22, 0.13, false),
                (0, 0.11, false),
                (-0.22, 0.13, false),
                (-0.38, 0.2, false),
                (-0.45, 0.34, false),
                (-0.47, 0.48, false)
              ],
              6.5)));
          for (final x in [-0.24, -0.08, 0.08, 0.24]) {
            s.lines.add(_hl([(x, 0.12, false), (x * 1.08, 0.05, false), (x * 1.14, -0.01, false)], 0.38));
          }
        case 'perm':
          s.ears = true;
          final fr = _scallop(_cap(4.5, 0.5, 0.5, 7, 16), 11, hh * 0.045);
          final edge = _scallop([
            for (final q in _hp([
              (0.5, 0.48, false),
              (0.4, 0.3, false),
              (0.15, 0.27, false),
              (-0.15, 0.27, false),
              (-0.4, 0.3, false),
              (-0.5, 0.48, false)
            ]))
              q.p
          ], 6, hh * 0.04, hd(0, 0.1));
          s.front.add(_HP([...fr, ...edge.sublist(1, edge.length - 1)]));
        case 'long':
          s.back.add(_HP(_sym([
            (0, -0.06, false),
            (0.32, -0.04, false),
            (0.52, 0.1, false),
            (0.58, 0.3, false),
            (0.6, 0.55, false),
            (0.61, 0.8, false),
            (0.59, 1.0, true),
            (0.47, 1.03, false),
            (0.38, 0.97, true),
            (0.34, 0.8, false),
            (0.3, 0.6, false)
          ])));
          s.front.add(_HP(_fringe(
              3,
              0.6,
              0.6,
              [
                (0.48, 0.58, false),
                (0.42, 0.4, false),
                (0.28, 0.24, false),
                (0.08, 0.16, false),
                (0.02, 0.18, true),
                (-0.06, 0.16, false),
                (-0.28, 0.24, false),
                (-0.42, 0.4, false),
                (-0.48, 0.58, false)
              ],
              3.5)));
        case 'spiky':
          s.ears = true;
          final sp = _spikes(_cap(3, 0.46, 0.46, 5, 16), 9, hh * 0.09);
          s.front.add(_HP([
            ...sp,
            ..._hp([
              (0.46, 0.4, false),
              (0.4, 0.28, false),
              (0.3, 0.22, true),
              (0.22, 0.13, true),
              (0.14, 0.22, true),
              (0.04, 0.12, true),
              (-0.04, 0.22, true),
              (-0.14, 0.13, true),
              (-0.22, 0.22, true),
              (-0.38, 0.25, false),
              (-0.46, 0.36, false)
            ])
          ]));
      }
    }
    return s;
  }
}

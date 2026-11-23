// 리소그래프 인쇄 느낌을 내는 그리기 도구.
// 잉크는 multiply로 겹쳐 찍어서 겹친 곳에 새 색이 생기고,
// 판을 살짝 어긋나게(shift) 찍고, 종이 결(stipple)과 망점(halftone)을 얹는다.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class RisoPaint {
  /// 잉크 면 한 판 찍기.
  static void fill(
    Canvas c,
    Path p,
    Color ink, {
    Offset shift = Offset.zero,
    double grain = 0.5,
    int seed = 1,
  }) {
    final path = shift == Offset.zero ? p : p.shift(shift);
    c.drawPath(path, Paint()..color = ink..blendMode = BlendMode.multiply);
    if (grain > 0) {
      // 잉크가 덜 묻은 자리: 종이가 비쳐 보이는 흰 점
      stipple(c, path, Colors.white.withValues(alpha: 0.75), density: grain, seed: seed);
    }
  }

  /// 무작위 점 (종이 결, 잉크 얼룩).
  static void stipple(
    Canvas c,
    Path p,
    Color color, {
    double density = 0.5,
    int seed = 1,
    double size = 1.0,
  }) {
    final b = p.getBounds();
    if (b.isEmpty) return;
    final n = (b.width * b.height * density / 12).round().clamp(0, 5000);
    final r = math.Random(seed);
    final pts = Float32List(n * 2);
    for (var i = 0; i < n; i++) {
      pts[i * 2] = b.left + r.nextDouble() * b.width;
      pts[i * 2 + 1] = b.top + r.nextDouble() * b.height;
    }
    c.save();
    c.clipPath(p);
    c.drawRawPoints(
      ui.PointMode.points,
      pts,
      Paint()
        ..color = color
        ..strokeWidth = size
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// 망점 그림자. [shade] 쪽에서 가장 크고 반대쪽으로 갈수록 작아진다.
  static void halftone(
    Canvas c,
    Path p,
    Color color, {
    Alignment shade = Alignment.centerLeft,
    double spacing = 4,
    double maxR = 1.5,
    double reach = 0.6, // 0~1, 그림자가 퍼지는 정도
  }) {
    final b = p.getBounds();
    if (b.isEmpty) return;
    final from = shade.withinRect(b);
    final to = (-shade).withinRect(b);
    final axis = to - from;
    final len2 = axis.distanceSquared;
    if (len2 == 0) return;

    c.save();
    c.clipPath(p);
    final paint = Paint()
      ..color = color
      ..blendMode = BlendMode.multiply;
    var row = 0;
    for (var y = b.top; y <= b.bottom + spacing; y += spacing * 0.87, row++) {
      final dx = row.isOdd ? spacing / 2 : 0.0;
      for (var x = b.left - spacing + dx; x <= b.right + spacing; x += spacing) {
        final v = Offset(x, y) - from;
        final t = ((v.dx * axis.dx + v.dy * axis.dy) / len2).clamp(0.0, 1.0);
        final k = (1 - t / reach).clamp(0.0, 1.0);
        final rr = maxR * k;
        if (rr > 0.3) c.drawCircle(Offset(x, y), rr, paint);
      }
    }
    c.restore();
  }

  /// 두께 있는 선을 둥근 끝 캡슐 모양 Path로.
  static Path capsule(Offset a, Offset b, double width) {
    final d = b - a;
    final len = d.distance;
    final angle = math.atan2(d.dy, d.dx);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2, -width / 2, len + width, width),
        Radius.circular(width / 2),
      ));
    final m = Matrix4.identity()
      ..translate(a.dx, a.dy)
      ..rotateZ(angle);
    return path.transform(m.storage);
  }
}

/// 손그림 느낌 도구: 떨리는 선, 크레용 빗금.
class Hand {
  /// 경로를 따라가며 살짝 떨리게 다시 그린다.
  static Path wobble(Path src, {double amp = 1.2, int seed = 1, double step = 5}) {
    final out = Path();
    final r = math.Random(seed);
    final p1 = r.nextDouble() * 6.28, p2 = r.nextDouble() * 6.28;
    for (final m in src.computeMetrics()) {
      final n = math.max(2, (m.length / step).ceil());
      for (var i = 0; i <= n; i++) {
        final d = m.length * i / n;
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        final normal = Offset(-t.vector.dy, t.vector.dx);
        final k = amp * (math.sin(d * 0.045 + p1) * 0.7 + math.sin(d * 0.13 + p2) * 0.3);
        final pt = t.position + normal * k;
        if (i == 0) {
          out.moveTo(pt.dx, pt.dy);
        } else {
          out.lineTo(pt.dx, pt.dy);
        }
      }
      if (m.isClosed) out.close();
    }
    return out;
  }

  /// 떨리는 먹선.
  static void outline(Canvas c, Path p, {Color color = const Color(0xFF1E2346), double width = 1.6, int seed = 1, double amp = 1.2, Offset shift = Offset.zero}) {
    c.drawPath(
      wobble(p, amp: amp, seed: seed).shift(shift),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// 크레용 빗금 칠하기. 연한 바탕 + 비스듬한 굵은 획.
  static void hatch(
    Canvas c,
    Path p,
    Color color, {
    double angle = -0.6,
    double spacing = 4.5,
    double width = 3,
    double base = 0.35,
    int seed = 1,
  }) {
    final b = p.getBounds();
    if (b.isEmpty) return;
    c.save();
    c.clipPath(p);
    if (base > 0) {
      c.drawRect(b, Paint()..color = color.withValues(alpha: color.a * base));
    }
    final r = math.Random(seed);
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * 0.75)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.multiply;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final nrm = Offset(-dir.dy, dir.dx);
    final center = b.center;
    final half = b.longestSide;
    for (var s = -half; s <= half; s += spacing) {
      final mid = center + nrm * (s + (r.nextDouble() - 0.5) * spacing * 0.5);
      final len = half * (0.8 + r.nextDouble() * 0.4);
      final a = mid - dir * len, z = mid + dir * len;
      c.drawLine(a, z, paint..strokeWidth = width * (0.75 + r.nextDouble() * 0.5));
    }
    c.restore();
  }
}

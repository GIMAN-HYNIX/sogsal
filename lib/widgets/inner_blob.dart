// 몸속 친구들(피하지방이·근육이·내장지방이)과 얼굴 그리기. 리소 스타일 임시 그림.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'riso_paint.dart';

enum BlobKind { fat, visceral, muscle }

enum BlobMood { happy, normal, sleepy, struggling, angry }

extension BlobKindInk on BlobKind {
  Color get ink => switch (this) {
        BlobKind.fat => Riso.yellow,
        BlobKind.visceral => Riso.orange,
        BlobKind.muscle => Riso.pink,
      };
}

/// 점 눈 얼굴. [s]는 크기 배율(1 = 눈 간격 8px).
void drawFace(Canvas c, Offset at, BlobMood mood, {double s = 1}) {
  final ink = Paint()..color = Riso.ink;
  final line = Paint()
    ..color = Riso.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6 * s
    ..strokeCap = StrokeCap.round;
  final dx = 4.0 * s;
  for (final sx in [-1.0, 1.0]) {
    final e = at + Offset(sx * dx, 0);
    switch (mood) {
      case BlobMood.normal:
      case BlobMood.angry:
        c.drawCircle(e, 1.6 * s, ink);
      case BlobMood.happy:
        c.drawArc(Rect.fromCenter(center: e + Offset(0, 1 * s), width: 4.4 * s, height: 4 * s),
            math.pi, math.pi, false, line);
      case BlobMood.sleepy:
        c.drawArc(Rect.fromCenter(center: e - Offset(0, 0.6 * s), width: 4.4 * s, height: 3.2 * s),
            0, math.pi, false, line);
      case BlobMood.struggling:
        c.drawLine(e + Offset(-1.8 * sx * s, -1.6 * s), e + Offset(1.6 * sx * s, 0), line);
        c.drawLine(e + Offset(1.6 * sx * s, 0), e + Offset(-1.8 * sx * s, 1.6 * s), line);
    }
  }
  final m = at + Offset(0, 4 * s);
  if (mood == BlobMood.struggling) {
    c.drawArc(Rect.fromCenter(center: m + Offset(0, 1 * s), width: 4.4 * s, height: 3 * s),
        math.pi, math.pi, false, line);
  } else {
    c.drawArc(Rect.fromCenter(center: m, width: 4 * s, height: 3 * s), 0.3, math.pi - 0.6,
        false, line);
  }
}

/// 범례·작은 자리에 쓰는 속 친구 아이콘.
class InnerBlob extends StatelessWidget {
  final BlobKind kind;
  final BlobMood mood;
  final double size;

  const InnerBlob({super.key, required this.kind, this.mood = BlobMood.normal, this.size = 32});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BlobPainter(kind, mood)),
      );
}

class _BlobPainter extends CustomPainter {
  final BlobKind kind;
  final BlobMood mood;
  _BlobPainter(this.kind, this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40);
    final Path body;
    if (kind == BlobKind.muscle) {
      body = Path()
        ..addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTRB(5, 9, 35, 35), const Radius.circular(12)));
    } else {
      body = Path()
        ..moveTo(20, 4)
        ..cubicTo(34, 6, 38, 22, 35, 29)
        ..cubicTo(32, 37, 8, 37, 5, 29)
        ..cubicTo(2, 22, 6, 6, 20, 4)
        ..close();
    }
    RisoPaint.fill(canvas, body, kind.ink, shift: const Offset(0.8, 0.5), grain: 0.6, seed: kind.index + 2);
    if (kind == BlobKind.muscle) {
      // 근섬유 결
      final fiber = Paint()
        ..color = Riso.ink.withValues(alpha: 0.28)
        ..strokeWidth = 1.2;
      for (var x = 10.0; x <= 30; x += 5) {
        canvas.drawLine(Offset(x, 12), Offset(x, 16), fiber);
        canvas.drawLine(Offset(x, 30), Offset(x, 33), fiber);
      }
    } else {
      RisoPaint.halftone(canvas, body, Riso.orange.withValues(alpha: 0.7),
          shade: Alignment.bottomRight, spacing: 2.6, maxR: 0.9, reach: 0.6);
    }
    drawFace(canvas, const Offset(20, 21), mood, s: 1.1);
  }

  @override
  bool shouldRepaint(_BlobPainter o) => o.kind != kind || o.mood != mood;
}

// 공통 UI 조각. 모양 원칙은 DESIGN.md 참고.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'riso_paint.dart';

/// 종이 바탕 (결 텍스처).
class Paper extends StatelessWidget {
  final Widget child;
  const Paper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Riso.paper,
          image: DecorationImage(
            image: AssetImage('assets/textures/grain.png'),
            repeat: ImageRepeat.repeat,
            scale: 2,
          ),
        ),
        child: child,
      );
}

/// 화면 머리: 도현체 제목 + 오른쪽 보조 정보.
class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget? leading;
  const ScreenHeader({super.key, required this.title, this.trailing, this.leading});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(leading == null ? 0 : 0, 12, 0, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) leading!,
            Expanded(child: Text(title, style: Txt.h2)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// 추정값 표시. 형광펜으로 그은 듯한 노란 바탕.
class EstimateTag extends StatelessWidget {
  final String text;
  const EstimateTag({super.key, this.text = '추정'});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(5, 1, 5, 2),
        color: Riso.yellow,
        child: Text(text,
            style: const TextStyle(
                fontFamily: Txt.body,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Riso.ink)),
      );
}

const estimateNotice = '추정치예요. 인바디로 재면 더 정확해져요.';

// ---------------------------------------------------------------------------
// 체성분표: 식품 영양성분표 모양의 표
// ---------------------------------------------------------------------------

class LabelRow {
  final String label;
  final String value;
  final String? unit;
  final String? sub; // 값 옆 작은 글씨 (예: 비율)
  final bool strong;
  final bool indent;
  final Color? swatch;
  final Color? valueColor;

  const LabelRow(
    this.label,
    this.value, {
    this.unit,
    this.sub,
    this.strong = false,
    this.indent = false,
    this.swatch,
    this.valueColor,
  });
}

class LabelTable extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<LabelRow> rows;
  final String? footnote;
  final Widget? footer;

  /// true면 검은 머리띠 없이 제목은 표 위에, 표는 가는 테두리 목록으로.
  /// 체성분 숫자가 아닌 표(목표, 내 정보)는 이걸 써서 영양성분표 모양이 남발되지 않게 한다.
  final bool plain;

  const LabelTable({
    super.key,
    required this.title,
    required this.rows,
    this.trailing,
    this.footnote,
    this.footer,
    this.plain = false,
  });

  Widget _plain() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text(title, style: Txt.h3)),
                if (trailing != null) DefaultTextStyle(style: Txt.secondary, child: trailing!),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Riso.sheet,
              border: Border.all(color: Riso.line),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      color: Riso.line,
                      margin: EdgeInsets.only(left: rows[i].indent ? 28 : 0),
                    ),
                  _row(rows[i]),
                ],
              ],
            ),
          ),
          if (footnote != null || footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: footer ?? Text(footnote!, style: Txt.meta),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (plain) return _plain();
    return Container(
      decoration: BoxDecoration(
        color: Riso.sheet,
        border: Border.all(color: Riso.ink, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Riso.ink,
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
            child: Row(
              children: [
                Expanded(
                    child: Text(title, style: Txt.h3.copyWith(color: Colors.white))),
                if (trailing != null)
                  DefaultTextStyle(
                    style: Txt.meta.copyWith(color: Colors.white),
                    child: trailing!,
                  ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                height: rows[i].strong ? 3 : 1,
                color: rows[i].strong ? Riso.ink : Riso.line,
                margin: EdgeInsets.only(left: rows[i].indent ? 28 : 0),
              ),
            _row(rows[i]),
          ],
          if (footnote != null || footer != null) ...[
            Container(height: 3, color: Riso.ink),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: footer ?? Text(footnote!, style: Txt.meta),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(LabelRow r) => Padding(
        padding: EdgeInsets.fromLTRB(r.indent ? 28 : 14, 11, 14, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (r.swatch != null) ...[
              Container(width: 12, height: 12, color: r.swatch),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                r.label,
                style: TextStyle(
                  fontFamily: Txt.body,
                  fontSize: r.indent ? 14 : 16,
                  height: 1.4,
                  fontWeight: r.strong ? FontWeight.w600 : FontWeight.w400,
                  color: r.indent ? Riso.sub : Riso.ink,
                ),
              ),
            ),
            if (r.sub != null) ...[
              Text(r.sub!, style: Txt.secondary),
              const SizedBox(width: 10),
            ],
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: r.value,
                  style: Txt.num.copyWith(
                    fontSize: r.strong ? 24 : 20,
                    color: r.valueColor ?? Riso.ink,
                  ),
                ),
                if (r.unit != null)
                  TextSpan(
                    text: r.unit,
                    style: Txt.secondary.copyWith(color: r.valueColor ?? Riso.ink),
                  ),
              ]),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// 버튼, 선택, 입력
// ---------------------------------------------------------------------------

class InkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final IconData? icon;

  const InkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? (outlined ? Riso.ink : Colors.white) : Riso.faint;
    final bg = outlined ? Riso.sheet : (enabled ? Riso.ink : const Color(0xFFDDDFE6));
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: outlined
              ? BorderSide(color: enabled ? Riso.ink : Riso.lineStrong, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: TextStyle(
                        fontFamily: Txt.body,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 여러 개 중 하나 고르기. 먹 테두리로 이어 붙인 칸.
class ChoiceGroup<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const ChoiceGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: Riso.sheet,
          border: Border.all(color: Riso.ink, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) Container(width: 1.5, color: Riso.ink),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: options[i].$1 == selected,
                    child: Material(
                      color: options[i].$1 == selected ? Riso.ink : Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(options[i].$1),
                        child: Center(
                          child: Text(
                            options[i].$2,
                            style: TextStyle(
                              fontFamily: Txt.body,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: options[i].$1 == selected ? Colors.white : Riso.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class InkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final String? hint;
  final String? helper;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool integer;

  const InkField({
    super.key,
    required this.controller,
    required this.label,
    required this.unit,
    this.hint,
    this.helper,
    this.errorText,
    this.onChanged,
    this.integer = false,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Txt.label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.numberWithOptions(decimal: !integer),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(integer ? r'[0-9]' : r'[0-9.]')),
            ],
            style: Txt.bodyText,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Riso.sheet,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintText: hint,
              hintStyle: Txt.bodyText.copyWith(color: Riso.faint),
              suffixText: unit,
              suffixStyle: Txt.secondary,
              helperText: helper,
              helperStyle: Txt.meta,
              helperMaxLines: 2,
              errorText: errorText,
              errorStyle: Txt.meta.copyWith(color: Riso.error),
              errorMaxLines: 2,
              enabledBorder: border(Riso.lineStrong, 1.5),
              focusedBorder: border(Riso.ink, 2),
              errorBorder: border(Riso.error, 1.5),
              focusedErrorBorder: border(Riso.error, 2),
            ),
          ),
        ],
      ),
    );
  }
}

double? parseNum(TextEditingController c) => double.tryParse(c.text.trim());

/// 도판: 파란 모눈 종이 위에 그림을 올린다.
class GridPlate extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Widget? caption;

  const GridPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 20, 12, 12),
    this.caption,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Riso.sheet,
          border: Border.all(color: Riso.line),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                if (caption != null) ...[
                  const SizedBox(height: 8),
                  DefaultTextStyle(style: Txt.meta, child: caption!),
                ],
              ],
            ),
          ),
        ),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = Riso.blue.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = Riso.blue.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    const step = 12.0;
    var i = 0;
    for (var x = step; x < size.width; x += step, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 4 == 3 ? major : minor);
    }
    i = 0;
    for (var y = step; y < size.height; y += step, i++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 4 == 3 ? major : minor);
    }
  }

  @override
  bool shouldRepaint(_GridPainter o) => false;
}

/// 섹션 제목 (도현체, 아래 굵은 선 없이).
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(text, style: Txt.h3)),
          if (trailing != null) trailing!,
        ]),
      );
}

/// 하단 시트 공통 틀.
Future<T?> showInkSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: builder(ctx),
      ),
    );

/// 손으로 그린 말풍선. 꼬리는 아래 가운데(캐릭터 쪽)를 가리킨다.
class SpeechBubble extends StatelessWidget {
  final String text;
  final bool warn;
  const SpeechBubble({super.key, required this.text, this.warn = false});

  static const tail = 12.0;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BubblePainter(warn ? Riso.error : Riso.ink),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12 + tail),
          child: Text(text, style: Txt.bodyText, textAlign: TextAlign.center),
        ),
      );
}

class _BubblePainter extends CustomPainter {
  final Color ink;
  _BubblePainter(this.ink);

  @override
  void paint(Canvas c, Size s) {
    const t = SpeechBubble.tail;
    final bottom = s.height - t - 2;
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(1, 1, s.width - 2, bottom), const Radius.circular(16)));
    final cx = s.width / 2;
    final tailPath = Path()
      ..moveTo(cx - 10, bottom - 1)
      ..quadraticBezierTo(cx - 5, bottom + 5, cx - 12, s.height - 1)
      ..quadraticBezierTo(cx + 4, bottom + 4, cx + 9, bottom - 1)
      ..close();
    final shape = Path.combine(PathOperation.union, body, tailPath);
    c.drawPath(shape, Paint()..color = Riso.sheet);
    Hand.outline(c, shape, color: ink, width: 1.6, amp: 0.7, seed: 7, shift: const Offset(0.8, 0.5));
  }

  @override
  bool shouldRepaint(_BubblePainter o) => o.ink != ink;
}

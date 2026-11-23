// 디자인 토큰. 방향은 DESIGN.md("리소 해부 도감") 참고.
import 'package:flutter/material.dart';

class Riso {
  static const paper = Color(0xFFF4F5F7);
  static const sheet = Colors.white;
  static const ink = Color(0xFF1E2346); // 먹
  static const sub = Color(0xFF5E6380); // 보조 글자
  static const faint = Color(0xFF9A9DB2); // 비활성
  static const line = Color(0x241E2346); // 가는 선 (먹 14%)
  static const lineStrong = Color(0x591E2346); // 입력칸 테두리 (먹 35%)

  static const pink = Color(0xFFFF4FA3); // 근육
  static const yellow = Color(0xFFFFCF33); // 피하지방
  static const orange = Color(0xFFFFA62B); // 내장지방 (진노랑)
  static const blue = Color(0xFF3A6FD8); // 도판 모눈

  static const error = Color(0xFFC9302C);
  static const good = Color(0xFF1F8A5B);
}

class Txt {
  static const display = 'DoHyeon';
  static const body = 'Pretendard';

  static const h1 = TextStyle(fontFamily: display, fontSize: 40, height: 1.1, color: Riso.ink);
  static const h2 = TextStyle(fontFamily: display, fontSize: 28, height: 1.15, color: Riso.ink);
  static const h3 = TextStyle(fontFamily: display, fontSize: 20, height: 1.2, color: Riso.ink);
  static const num = TextStyle(fontFamily: display, fontSize: 20, height: 1.1, color: Riso.ink);

  static const bodyText = TextStyle(fontFamily: body, fontSize: 16, height: 1.55, color: Riso.ink);
  static const secondary = TextStyle(fontFamily: body, fontSize: 14, height: 1.5, color: Riso.sub);
  static const meta = TextStyle(fontFamily: body, fontSize: 12, height: 1.4, color: Riso.sub);
  static const label = TextStyle(
      fontFamily: body, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500, color: Riso.ink);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Riso.ink,
    primary: Riso.ink,
    onPrimary: Colors.white,
    surface: Riso.paper,
    onSurface: Riso.ink,
    error: Riso.error,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: Txt.body,
    colorScheme: scheme,
    scaffoldBackgroundColor: Riso.paper,
    splashFactory: InkRipple.splashFactory,
    textTheme: Typography.blackMountainView.apply(
      fontFamily: Txt.body,
      bodyColor: Riso.ink,
      displayColor: Riso.ink,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Riso.ink),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Riso.sheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      dragHandleColor: Riso.line,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Riso.sheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Riso.ink, width: 1.5),
      ),
      titleTextStyle: Txt.h3,
      contentTextStyle: Txt.secondary,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Riso.ink,
      contentTextStyle: TextStyle(fontFamily: Txt.body, fontSize: 14, color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Riso.ink,
        textStyle: const TextStyle(fontFamily: Txt.body, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

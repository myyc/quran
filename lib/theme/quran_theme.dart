import 'package:flutter/material.dart';

class QColors {
  QColors._();

  static const surface = Color(0xFF000000);
  static const panel = Color(0xFF0D0D0D);
  static const ink = Color(0xFFFFFFFF);
  static const accent = Color(0xFF009E49);
  static const accentBright = Color(0xFF2CC36B);
  static const dim = Color(0x80FFFFFF);
  static const ghost = Color(0x33FFFFFF);
  static const rule = Color(0x26FFFFFF);
}

class QTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: QColors.surface,
    canvasColor: QColors.surface,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      surface: QColors.surface,
      onSurface: QColors.ink,
      primary: QColors.accent,
      onPrimary: QColors.ink,
      secondary: QColors.accent,
      onSecondary: QColors.ink,
      outline: QColors.rule,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: QColors.surface,
      foregroundColor: QColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    iconTheme: const IconThemeData(color: QColors.dim, size: 20),
    dividerTheme: const DividerThemeData(
      color: QColors.rule,
      thickness: 1,
      space: 1,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: QColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: QColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: QColors.ink,
      contentTextStyle: TextStyle(color: QColors.surface, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: QColors.ink,
      unselectedLabelColor: QColors.dim,
      indicatorColor: QColors.accent,
      dividerColor: QColors.rule,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: QColors.accent,
      thumbColor: QColors.accent,
      inactiveTrackColor: QColors.rule,
      overlayColor: Color(0x22009E49),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: QColors.accent,
      selectionColor: Color(0x55009E49),
      selectionHandleColor: QColors.accent,
    ),
  );
}

TextStyle capsStyle({double size = 11, Color color = QColors.dim}) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  fontWeight: FontWeight.w700,
  letterSpacing: size * 0.16,
  color: color,
);

TextStyle kufiStyle(double size, {Color color = QColors.ink}) => TextStyle(
  fontFamily: 'ReemKufi',
  fontSize: size,
  fontWeight: FontWeight.w500,
  height: 1.6,
  color: color,
);

TextStyle arabicStyle(
  double size, {
  Color color = QColors.ink,
  bool quranFont = true,
}) => TextStyle(
  fontFamily: quranFont ? 'AmiriQuran' : 'Amiri',
  fontSize: size,
  height: 1.9,
  color: color,
);

import 'package:flutter/material.dart';

abstract final class McSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double page = 32;
}

ThemeData mcTheme(Brightness brightness, {bool highContrast = false}) {
  final dark = brightness == Brightness.dark;
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff7363d8),
        brightness: brightness,
      ).copyWith(
        surface: dark ? const Color(0xff191d28) : Colors.white,
        onSurface: dark ? const Color(0xffe6e9f2) : const Color(0xff252b3b),
        onSurfaceVariant: dark
            ? const Color(0xff9ba5b9)
            : const Color(0xff667086),
        primary: highContrast
            ? dark
                  ? const Color(0xffd6ceff)
                  : const Color(0xff49349f)
            : dark
            ? const Color(0xffb8acff)
            : const Color(0xff6551bd),
        outlineVariant: dark
            ? highContrast
                  ? const Color(0xffaeb7ca)
                  : const Color(0xff303646)
            : highContrast
            ? const Color(0xff4f586c)
            : const Color(0xffe3e6ee),
      );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    fontFamily: 'packages/mc_ui_foundation/Roboto',
    scaffoldBackgroundColor: dark
        ? const Color(0xff121620)
        : const Color(0xfff3f5fa),
    dividerColor: colors.outlineVariant,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -.6,
        color: colors.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: colors.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: shape,
        side: BorderSide(color: colors.outlineVariant),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 450),
    ),
    focusColor: highContrast ? colors.primary.withValues(alpha: .34) : null,
  );
}

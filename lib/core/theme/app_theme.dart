import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Thème principal ──────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: infoBlue,
          error: dangerRed,
          surface: surfaceWhite,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
          onSurface: textDark,
        ),

        // ── Scaffold ──────────────────────────────────────────────────
        scaffoldBackgroundColor: background,

        // ── AppBar ────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),

        // ── Cards ─────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: surfaceWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── ElevatedButton ────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── OutlinedButton ────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: primaryBlue),
          ),
        ),

        // ── TextButton ────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue,
          ),
        ),

        // ── InputDecoration ───────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: dangerRed),
          ),
          labelStyle: const TextStyle(color: textGrey),
          hintStyle: const TextStyle(color: textLight),
        ),

        // ── Chip ──────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: borderLight,
          selectedColor: primaryBlue.withValues(alpha: 0.12),
          labelStyle: const TextStyle(fontSize: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        ),

        // ── Divider ───────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        // ── ListTile ──────────────────────────────────────────────────
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),

        // ── BottomSheet ───────────────────────────────────────────────
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),

        // ── SnackBar ──────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        ),

        // ── FloatingActionButton ──────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // ── Typography ────────────────────────────────────────────────
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
          displayMedium: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
          displaySmall: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
          headlineLarge: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
          headlineMedium: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: textDark),
          headlineSmall: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
          titleLarge: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
          titleMedium: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
          titleSmall: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: textMedium),
          bodyLarge: TextStyle(
              fontSize: 15, fontWeight: FontWeight.normal, color: textDark),
          bodyMedium: TextStyle(
              fontSize: 13, fontWeight: FontWeight.normal, color: textMedium),
          bodySmall: TextStyle(
              fontSize: 12, fontWeight: FontWeight.normal, color: textGrey),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
          labelMedium: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: textGrey),
          labelSmall: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: textLight),
        ),
      );
}

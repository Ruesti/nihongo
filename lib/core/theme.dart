import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const paper = Color(0xFFF4EDE0);
  static const paper2 = Color(0xFFEDE4D3);
  static const ink = Color(0xFF1A1410);
  static const ink2 = Color(0xFF6B5F52);
  static const red = Color(0xFFB5191C);
  static const red2 = Color(0xFF8A1315);
  static const green = Color(0xFF2D6A4F);
  static const amber = Color(0xFF92400E);
  static const card = Color(0xFFFAF6EE);
  static const border = Color(0xFFD6C9B5);
  static const surface = Color(0xFFFFFBF5);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          surface: AppColors.surface,
          primary: AppColors.red,
          onPrimary: Colors.white,
          secondary: AppColors.amber,
          onSecondary: Colors.white,
          onSurface: AppColors.ink,
          outline: AppColors.border,
        ),
        scaffoldBackgroundColor: AppColors.paper,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.epilogue(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.red, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.epilogue(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.02,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink2,
            textStyle: GoogleFonts.epilogue(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.shipporiMinchoB1(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          displayMedium: GoogleFonts.shipporiMinchoB1(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          headlineLarge: GoogleFonts.epilogue(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          headlineMedium: GoogleFonts.epilogue(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          headlineSmall: GoogleFonts.epilogue(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.epilogue(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
          ),
          bodyMedium: GoogleFonts.epilogue(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
          ),
          bodySmall: GoogleFonts.epilogue(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.ink2,
          ),
          labelLarge: GoogleFonts.epilogue(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0.02,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.card,
          indicatorColor: AppColors.red.withOpacity(0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.red, size: 22);
            }
            return const IconThemeData(color: AppColors.ink2, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red);
            }
            return GoogleFonts.epilogue(
                fontSize: 11, color: AppColors.ink2);
          }),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: GoogleFonts.epilogue(
            color: Colors.white,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static TextStyle get jpLarge => const TextStyle(
        fontFamily: 'NotoSerifJP',
        fontSize: 64,
        color: AppColors.ink,
        height: 1.2,
      );

  static TextStyle get jpMedium => const TextStyle(
        fontFamily: 'NotoSerifJP',
        fontSize: 32,
        color: AppColors.ink,
        height: 1.3,
      );

  static TextStyle get jpSmall => const TextStyle(
        fontFamily: 'NotoSerifJP',
        fontSize: 20,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get jpBody => const TextStyle(
        fontFamily: 'NotoSerifJP',
        fontSize: 16,
        color: AppColors.ink,
        height: 1.6,
      );

  static TextStyle get furigana => const TextStyle(
        fontFamily: 'NotoSerifJP',
        fontSize: 10,
        color: AppColors.ink2,
      );
}

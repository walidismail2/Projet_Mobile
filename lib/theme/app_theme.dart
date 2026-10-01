import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF7A45);
  static const primaryDark = Color(0xFFE85D2A);
  static const primaryLight = Color(0xFFFFE8DD);

  static const navy = Color(0xFF1F2A44);
  static const textSecondary = Color(0xFF7A8199);
  static const background = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE8EAF2);

  static const health = Color(0xFF2EBD85);
  static const vet = Color(0xFF4C7CF6);
  static const food = Color(0xFFFFA928);
  static const reminder = Color(0xFFE9546B);
  static const purple = Color(0xFF8B5CF6);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 1.2),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.navy),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.navy),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        labelStyle: const TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_constants.dart';

/// Centralized typography for the app. Provides a `TextTheme` and helpers
/// using `flutter_screenutil` for responsive sizing.
class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'SFProText';
  static const String fontFamily = _fontFamily;

  static final TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 40.sp,
      fontWeight: FontWeight.bold,
      color: AppColors.textprimaryDark,
    ),
    displayMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 30.sp,
      fontWeight: FontWeight.w700,
      color: AppColors.textprimaryDark,
    ),
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textprimaryDark,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textprimaryDark,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 20.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textprimaryDark,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 18.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textprimaryDark,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16.sp,
      color: AppColors.textprimaryDark,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14.sp,
      color: AppColors.textprimaryDark,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12.sp,
      color: AppColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 11.sp,
      color: AppColors.textSecondary,
    ),
  );

  // Optional direct helpers
  static TextStyle display() => textTheme.displayMedium!;
  static TextStyle headline() => textTheme.headlineLarge!;
  static TextStyle title() => textTheme.titleLarge!;
  static TextStyle body() => textTheme.bodyLarge!;
  static TextStyle label() => textTheme.labelSmall!;

  static TextStyle button() => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textprimaryDark,
  );
}

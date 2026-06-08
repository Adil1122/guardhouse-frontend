import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized app constants: colors, strings and helpers for responsive sizes.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF155EFC);
  static const Color strokemedium = Color(0xFFEAEAEA);
  static const Color accent = Color(0xFF26A69A);
  static const Color background = Color(0xFFF9FAFB);
  static const Color card = Colors.white;
  static const Color textprimaryDark = Color(0xFF161028);
  static const Color textSecondary = Color(0xFF6A7282);

  // Worker dashboard
  static const Color dashboardBackground = Color(0xFFF3F4F6);
  static const Color headerBlue = Color(0xFF155EFC);
  static const Color headerBlueLight = Color(0xFF2563FF);
  static const Color textOnPrimary = Colors.white;
  static const Color subTextOnPrimary = Color(0xFFD7E4FF);

  static const Color geofenceBackground = Color(0xFFFDECEF);
  static const Color geofenceBorder = Color(0xFFFF3B30);
  static const Color geofenceIcon = Color(0xFFFF2D20);

  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color neutralIconBackground = Color(0xFFF3F4F6);
  static const Color infoBackground = Color(0xFFEAF2FF);
  static const Color infoBorder = Color(0xFF2B6BFF);
  static const Color actionButtonBackground = Color(0xFFE8EEFB);
  static const Color successBackground = Color(0xFFE8F7EE);
  static const Color successBorder = Color(0xFF34C759);
  static const Color successText = Color(0xFF1F9E55);
  static const Color warningBackground = Color(0xFFFFF7DF);
  static const Color warningBorder = Color(0xFFF4C542);
  static const Color warningText = Color(0xFFB78A08);
  static const Color danger = Color(0xFFFD0000);
  static const Color error = Color(0xFFE53E3E);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF161028);
  static const Color errorBackground = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color divider = Color(0xFFE6EAF2);
  static const Color darkOverlay = Color(0x66000000);
  static const Color timelineTrack = Color(0xFFE3E8F2);
}

class AppStrings {
  AppStrings._();
  static const String appName = 'ShiftMate';
  static const String appSubtitle = 'Workforce Management';
  static const String apiBaseUrl = 'https://aquilastech.com/guardhouse/api/';
}

class AppSizes {
  AppSizes._();

  // Base spacing (use .w when using ScreenUtil)
  static double padding = 16.0;
  static double radius = 12.0;
  static double icon = 24.0;

  // Helper to get responsive width-based value after ScreenUtil is initialized.
  static double w(double value) => value.w;
  static double h(double value) => value.h;
  static double sp(double value) => value.sp;
}

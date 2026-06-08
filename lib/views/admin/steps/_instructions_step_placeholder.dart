import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/typography.dart';

// Note: Instructions step is part of Site Details
// No longer a separate step in the current version

class SiteInstructionsStep extends StatelessWidget {
  const SiteInstructionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64.sp,
              color: const Color(0xFFD1D5DB),
            ),
            SizedBox(height: 16.h),
            Text(
              'Instructions',
              style: AppTypography.title().copyWith(
                fontSize: 18.sp,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Site instructions are managed\nas part of the Site Details',
              textAlign: TextAlign.center,
              style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

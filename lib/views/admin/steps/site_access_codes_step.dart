import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/typography.dart';

// Note: Access Codes step is deprecated in the current version
// Use Site Documents instead for security-related files and codes

class SiteAccessCodesStep extends StatelessWidget {
  const SiteAccessCodesStep({super.key});

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
              'Access Codes Management',
              style: AppTypography.title().copyWith(
                fontSize: 18.sp,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please use the Documents section to manage\nsecurity-related files and access information',
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/typography.dart';

class SiteClockInQuestionnairesStep extends StatefulWidget {
  const SiteClockInQuestionnairesStep({super.key});

  @override
  State<SiteClockInQuestionnairesStep> createState() =>
      _SiteClockInQuestionnairesStepState();
}

class _SiteClockInQuestionnairesStepState
    extends State<SiteClockInQuestionnairesStep> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _fieldDecoration(int index) {
    return InputDecoration(
      labelText: 'Question $index (Optional)',
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      hintText: 'Enter question $index',
      hintStyle: AppTypography.body().copyWith(
        fontSize: 14.sp,
        color: const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F1F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(5, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: TextField(
                controller: _controllers[i],
                decoration: _fieldDecoration(i + 1),
                style: AppTypography.body().copyWith(fontSize: 14.sp),
              ),
            );
          }),
        ],
      ),
    );
  }
}

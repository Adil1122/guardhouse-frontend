import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';

class PasswordResetLinkSentView extends StatefulWidget {
  const PasswordResetLinkSentView({
    super.key,
    this.email = 'you@gmail.com',
    this.onReturnToSignIn,
  });

  final String email;
  final VoidCallback? onReturnToSignIn;

  @override
  State<PasswordResetLinkSentView> createState() =>
      _PasswordResetLinkSentViewState();
}

class _PasswordResetLinkSentViewState extends State<PasswordResetLinkSentView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // icon tile
                Container(
                  width: 64.sp,
                  height: 62.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 30.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 22.h),

                Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.display().fontSize,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  'We sent reset instructions to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCDDCFE),
                    fontSize: AppTypography.body().fontSize,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.email.isEmpty ? 'your email address' : widget.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCDDCFE),
                    fontSize: AppTypography.body().fontSize,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 34.h),

                // button
                SizedBox(
                  width: double.infinity,
                  height: 74.sp,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go(Routes.login);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF111827),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 24.sp),
                        SizedBox(width: 12.w),
                        Text(
                          'Return to Sign In',
                          style: TextStyle(
                            fontSize: AppTypography.body().fontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

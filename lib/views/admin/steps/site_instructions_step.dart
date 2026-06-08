import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/typography.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/site_creation_provider.dart';

// Instructions step for Site Creation
class SiteInstructionsStep extends StatefulWidget {
  const SiteInstructionsStep({super.key});

  @override
  State<SiteInstructionsStep> createState() => _SiteInstructionsStepState();
}

class _SiteInstructionsStepState extends State<SiteInstructionsStep> {
  late final TextEditingController _instructionsController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final provider = context.read<SiteCreationProvider>();
    _instructionsController = TextEditingController(
      text: provider.instructions ?? '',
    );

    _instructionsController.addListener(_updateInstructions);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateInstructions() {
    final provider = context.read<SiteCreationProvider>();
    provider.updateInstructions(
      _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );
  }

  void _clearInstructions() {
    _instructionsController.clear();
    _updateInstructions();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SiteCreationProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with info

                // Instructions input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Column(
                    children: [
                      // Toolbar
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(12.r),
                          ),
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Instructions for Staff',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF374151),
                              ),
                            ),
                            const Spacer(),
                            if (_instructionsController.text.isNotEmpty)
                              TextButton.icon(
                                onPressed: _clearInstructions,
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _instructionsController.text.isEmpty
                                    ? const Color(0xFFE5E7EB)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${_instructionsController.text.length} chars',
                                style: AppTypography.body().copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _instructionsController.text.isEmpty
                                      ? const Color(0xFF6B7280)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Text area
                      Container(
                        height: 300.h,
                        child: TextField(
                          controller: _instructionsController,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText:
                                'Enter detailed instructions for staff members working at this site...\n\n'
                                'Example:\n'
                                '• Check all entry points every 2 hours\n'
                                '• Report any suspicious activity immediately\n'
                                '• Maintain visitor log at reception\n'
                                '• Emergency contacts are posted at the main desk',
                            hintStyle: AppTypography.body().copyWith(
                              fontSize: 14.sp,
                              color: const Color(0xFF9CA3AF),
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.w),
                          ),
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xFF111827),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Quick tips
                if (_instructionsController.text.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Tips for good instructions:',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _buildTip(
                          '• Be specific about patrol routes and timing',
                        ),
                        _buildTip('• Include emergency contact information'),
                        _buildTip('• Mention any special security protocols'),
                        _buildTip('• Add details about access restrictions'),
                        _buildTip('• Include reporting procedures'),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Instructions added successfully. Staff will be able to view these when they clock in at this site.',
                            style: AppTypography.body().copyWith(
                              fontSize: 14.sp,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: AppTypography.body().copyWith(
          fontSize: 13.sp,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

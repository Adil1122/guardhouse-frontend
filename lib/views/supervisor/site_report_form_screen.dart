import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../widgets/supervisor_panel_components.dart';

class SiteReportFormScreen extends StatefulWidget {
  const SiteReportFormScreen({super.key});

  @override
  State<SiteReportFormScreen> createState() => _SiteReportFormScreenState();
}

class _SiteReportFormScreenState extends State<SiteReportFormScreen> {
  String _selectedCondition = 'Excellent';
  final Map<String, String?> _attendanceStatus = {};
  String _complianceState = 'Compliant';

  final List<String> _conditions = ['Excellent', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    // Pre-set some attendance statuses matching the screenshot
    _attendanceStatus['John Doe'] = 'present';
    _attendanceStatus['John Doe 2'] = 'present';
    _attendanceStatus['John Doe 3'] = 'late';
  }

  @override
  Widget build(BuildContext context) {
    final supervisorViewModel = context.watch<SupervisorViewModel>();
    final workers = supervisorViewModel.workers;

    // Use mock data if no workers loaded
    final workerNames = workers.isNotEmpty
        ? workers.map((w) => w['name']?.toString() ?? 'Unknown').toList()
        : ['John Doe', 'John Doe 2', 'John Doe 3', 'John Doe 4'];

    return SupervisorPanelScaffold(
      title: 'Site Report Form',
      subtitle: 'Dynamic submission',
      bottomBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SupervisorActionButton(
          label: 'Submit Report',
          icon: Icons.check,
          onPressed: () async {
            final reportId = await supervisorViewModel.submitReport(
              siteId: '1',
              reportType: 'inspection',
              title: 'Site Report',
              description: 'Site condition: $_selectedCondition',
              priority: 'medium',
            );
            if (!mounted) return;
            await _showReportSubmittedPopup(reportId ?? 'RPT-12345678');
          },
        ),
      ),
      body: supervisorViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Site Condition Status
                  Text(
                    'Site Condition Status',
                    style: AppTypography.title().copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildConditionSection(),
                  SizedBox(height: 16.h),

                  // Workers Attendance Validation
                  _buildAttendanceSection(workerNames),
                  SizedBox(height: 16.h),

                  // Compliance Checklist
                  _buildComplianceSection(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
    );
  }

  Widget _buildConditionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Condition Status',
            style: AppTypography.title().copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _conditions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2.5,
            ),
            itemBuilder: (context, index) {
              final condition = _conditions[index];
              final isSelected = _selectedCondition == condition;
              return GestureDetector(
                onTap: () => setState(() => _selectedCondition = condition),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      condition,
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textprimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(List<String> workerNames) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workers Attendance Validation',
            style: AppTypography.title().copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          ...workerNames.map((name) => _buildWorkerAttendanceCard(name)),
        ],
      ),
    );
  }

  Widget _buildWorkerAttendanceCard(String name) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTypography.title().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _attendanceButton(
                  name,
                  'Present',
                  'present',
                  const Color(0xFF0CA82E),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _attendanceButton(
                  name,
                  'Late',
                  'late',
                  const Color(0xFFBE9800),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _attendanceButton(
                  name,
                  'Absent',
                  'absent',
                  const Color(0xFFFF1616),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceButton(
    String name,
    String label,
    String value,
    Color selectedColor,
  ) {
    final isSelected = _attendanceStatus[name] == value;
    return GestureDetector(
      onTap: () => setState(() => _attendanceStatus[name] = value),
      child: Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.cardBorder,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: isSelected ? Colors.white : AppColors.textprimaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Checklist',
            style: AppTypography.title().copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _complianceState = 'Compliant'),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _complianceState == 'Compliant'
                          ? AppColors.primary
                          : const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        'Compliant',
                        style: AppTypography.body().copyWith(
                          color: _complianceState == 'Compliant'
                              ? Colors.white
                              : AppColors.textprimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _complianceState = 'Minor Issues'),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _complianceState == 'Minor Issues'
                          ? const Color(0xFFBE9800)
                          : const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        'Minor Issues',
                        style: AppTypography.body().copyWith(
                          color: _complianceState == 'Minor Issues'
                              ? Colors.white
                              : AppColors.textprimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showReportSubmittedPopup(String reportId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF12B339),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: const Color(0xFF12B339),
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Report Submitted!',
                  style: AppTypography.title().copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your site report has been successfully\nsubmitted and recorded in the system.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _popupRow('Submitted at:', _formatNowTime()),
                      SizedBox(height: 6.h),
                      _popupRow('Report ID:', reportId),
                      SizedBox(height: 6.h),
                      _popupRow('Status:', 'Confirmed'),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go(Routes.supervisorSiteVisitOff);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Back to Active Site',
                      style: AppTypography.title().copyWith(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _popupRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: AppColors.textprimaryDark,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.body().copyWith(
            fontSize: 12.sp,
            color: AppColors.textprimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNowTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute:$second $period';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';
import 'package:security_app/widgets/supervisor_panel_components.dart';

class SupervisorOfficersScreen extends StatelessWidget {
  const SupervisorOfficersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final officers = context.watch<SupervisorViewModel>().allOfficers;

    return WorkerPanelScaffold(
      title: 'Officers Details',
      body: officers.isEmpty
          ? Center(
              child: Text(
                'No officers found',
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              itemCount: officers.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => _OfficerCard(officer: officers[i]),
            ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  const _OfficerCard({required this.officer});

  final Map<String, dynamic> officer;

  void _sendCheckCall(BuildContext context) async {
    final id = officer['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final vm = context.read<SupervisorViewModel>();
    final ok = await vm.sendCheckCall(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Check call sent' : 'Failed to send check call'),
        backgroundColor: ok ? AppColors.successText : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = officer['name']?.toString() ?? 'Unknown';
    final role = officer['role']?.toString() ?? '';
    final site = officer['site']?.toString() ?? '';
    final siteAddress = officer['siteAddress']?.toString() ?? '';
    final onDuty = officer['clockedIn'] == true;
    final shiftStart = officer['shiftStart']?.toString() ?? '';
    final shiftEnd = officer['shiftEnd']?.toString() ?? '';
    final initials = name
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.sp,
            height: 44.sp,
            decoration: BoxDecoration(
              color: AppColors.actionButtonBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.title().copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textprimaryDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: onDuty
                            ? AppColors.successBackground
                            : AppColors.neutralIconBackground,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        onDuty ? 'On Duty' : 'Off Duty',
                        style: AppTypography.body().copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: onDuty
                              ? AppColors.successText
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  role,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (site.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Divider(height: 1, color: AppColors.cardBorder),
                  SizedBox(height: 6.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 13.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          site,
                          style: AppTypography.body().copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textprimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (siteAddress.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            siteAddress,
                            style: AppTypography.body().copyWith(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (shiftStart.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$shiftStart – $shiftEnd',
                          style: AppTypography.body().copyWith(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (onDuty) ...[
                  SizedBox(height: 10.h),
                  Divider(height: 1, color: AppColors.cardBorder),
                  SizedBox(height: 10.h),
                  SupervisorActionButton(
                    label: 'Send Check Call',
                    icon: Icons.health_and_safety_outlined,
                    isOutlined: true,
                    onPressed: () => _sendCheckCall(context),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

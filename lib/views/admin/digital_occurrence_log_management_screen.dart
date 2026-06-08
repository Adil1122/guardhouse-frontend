import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/digital_occurrence_log_viewmodel.dart';
import '../../models/digital_occurrence_log_model.dart';
import '../../viewmodels/auth_viewmodel.dart';

class DigitalOccurrenceLogManagementScreen extends StatefulWidget {
  const DigitalOccurrenceLogManagementScreen({super.key});

  @override
  State<DigitalOccurrenceLogManagementScreen> createState() =>
      _DigitalOccurrenceLogManagementScreenState();
}

class _DigitalOccurrenceLogManagementScreenState
    extends State<DigitalOccurrenceLogManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DigitalOccurrenceLogViewModel>().loadLogs();
    });
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('occurrence_log', action);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalOccurrenceLogViewModel>(
      builder: (context, viewModel, child) {
        final logs = viewModel.logs;

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                //  Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Occurrence Logs',
                              style: AppTypography.title().copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                //  Body
                Expanded(
                  child: viewModel.isLoading && logs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadLogs(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              24.h,
                            ),
                            children: [
                              //  Occurrence Log List
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Occurrence Log List',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${logs.length} record${logs.length == 1 ? "" : "s"} found',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (logs.isNotEmpty)
                                    Tooltip(
                                      message: 'Download All PDFs',
                                      child: InkWell(
                                        onTap: () async {
                                          for (final log in logs) {
                                            await viewModel.downloadPdf(log.id);
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'All ${logs.length} PDFs downloaded',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                backgroundColor:
                                                    AppColors.primary,
                                              ),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14.w,
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 28.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              if (logs.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 36.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No occurrence logs found',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...logs.map(
                                  (log) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _buildLogCard(log, viewModel),
                                  ),
                                ),
                            ],
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

  //  Occurrence Log Card
  Widget _buildLogCard(
    DigitalOccurrenceLog log,
    DigitalOccurrenceLogViewModel viewModel,
  ) {
    final dateStr = DateFormat('dd MMM yyyy').format(log.date);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Row 1: Date + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13.sp,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    dateStr,
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _statusColor(log.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  log.status.displayName,
                  style: AppTypography.body().copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(log.status),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 14.h, color: const Color(0xFFE5E7EB)),

          //  Row 2: Customer / Site / Staff
          Row(
            children: [
              Expanded(
                child: _infoCell(
                  Icons.business_outlined,
                  'Customer',
                  log.customerName,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _infoCell(
                  Icons.location_on_outlined,
                  'Site',
                  log.siteName,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _infoCell(Icons.person_outline_rounded, 'Staff', log.staffName),

          SizedBox(height: 12.h),

          //  Row 3: Show to Customer toggle
          GestureDetector(
            onTap: _hasPrivilege('update') ? () => viewModel.toggleShowToCustomer(log.id) : null,
            child: Container(
              height: 38.h,
              decoration: BoxDecoration(
                color: log.showToCustomer
                    ? const Color(0xFFDEF7EC)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: log.showToCustomer
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    log.showToCustomer
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 15.sp,
                    color: log.showToCustomer
                        ? const Color(0xFF065F46)
                        : const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    log.showToCustomer ? 'Visible' : 'Hidden',
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: log.showToCustomer
                          ? const Color(0xFF065F46)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13.sp, color: const Color(0xFF9CA3AF)),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.body().copyWith(
                  fontSize: 10.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              Text(
                value,
                style: AppTypography.body().copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(DigitalOccurrenceStatus status) {
    switch (status) {
      case DigitalOccurrenceStatus.draft:
        return const Color(0xFF6B7280);
      case DigitalOccurrenceStatus.submitted:
        return const Color(0xFF0E45BA);
      case DigitalOccurrenceStatus.reviewed:
        return const Color(0xFFF59E0B);
      case DigitalOccurrenceStatus.closed:
        return const Color(0xFF10B981);
    }
  }
}

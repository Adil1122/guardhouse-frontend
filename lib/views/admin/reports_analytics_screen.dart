import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';

import '../../widgets/ultimate_mobile_widgets.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen> {
  String _selectedTab = 'Weekly';
  String _selectedDate = '16/01/2026';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadReports();
    });
  }

  List<_MetricItem> _buildMetrics(List<Map<String, dynamic>> reports) {
    final total = reports.length;
    final reviewed = reports.where((report) {
      final status = (report['status'] ?? '').toString().toLowerCase();
      return status == 'reviewed' || status == 'approved' || status == 'closed';
    }).length;
    final pending = reports.where((report) {
      final status = (report['status'] ?? '').toString().toLowerCase();
      return status == 'pending' || status == 'submitted' || status == 'draft';
    }).length;
    final incidents = reports.where((report) {
      final type = (report['type'] ?? report['category'] ?? '')
          .toString()
          .toLowerCase();
      return type.contains('incident') ||
          type.contains('breach') ||
          type.contains('security');
    }).length;

    return [
      _MetricItem(
        title: 'Total Reports',
        value: '$total',
        trend: 'All periods',
        trendColor: const Color(0xFF6B7280),
        icon: Icons.description_outlined,
        iconBox: const Color(0xFFE5E7EB),
        iconColor: const Color(0xFF6B7280),
      ),
      _MetricItem(
        title: 'Reviewed',
        value: '$reviewed',
        trend: 'Completed workflow',
        trendColor: const Color(0xFF16A34A),
        icon: Icons.verified,
        iconBox: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _MetricItem(
        title: 'Pending',
        value: '$pending',
        trend: 'Needs action',
        trendColor: const Color(0xFFCA8A04),
        icon: Icons.pending_actions,
        iconBox: const Color(0xFFFDE68A),
        iconColor: const Color(0xFFCA8A04),
      ),
      _MetricItem(
        title: 'Incidents',
        value: '$incidents',
        trend: 'Security critical',
        trendColor: const Color(0xFFEF4444),
        icon: Icons.report_problem,
        iconBox: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFEF4444),
      ),
    ];
  }

  List<_ActivityItem> _buildWeeklyActivity(List<Map<String, dynamic>> reports) {
    const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final groupedReports = <String, int>{for (final day in order) day: 0};
    final groupedWorkers = <String, Set<String>>{
      for (final day in order) day: <String>{},
    };

    for (final report in reports) {
      final parsedDate = _parseReportDate(report);
      if (parsedDate == null) continue;
      final day = order[parsedDate.weekday - 1];
      groupedReports[day] = (groupedReports[day] ?? 0) + 1;
      final worker =
          (report['createdBy'] ??
                  report['created_by'] ??
                  report['staffName'] ??
                  '')
              .toString();
      if (worker.trim().isNotEmpty) {
        groupedWorkers[day]!.add(worker.trim());
      }
    }

    return order
        .map(
          (day) => _ActivityItem(
            day: day,
            workers: groupedWorkers[day]!.length,
            hours: groupedReports[day] ?? 0,
          ),
        )
        .toList();
  }

  DateTime? _parseReportDate(Map<String, dynamic> report) {
    final raw = report['date'] ?? report['created_at'] ?? report['createdAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Future<void> _pickDate() async {
    final parsed = _selectedDate.split('/');
    final now = DateTime.now();
    final initial = parsed.length == 3
        ? DateTime(
            int.tryParse(parsed[2]) ?? now.year,
            int.tryParse(parsed[1]) ?? now.month,
            int.tryParse(parsed[0]) ?? now.day,
          )
        : now;

    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _export(String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$type export started')));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final metrics = _buildMetrics(viewModel.reports);
        final weekly = _buildWeeklyActivity(viewModel.reports);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                  'Report & Analytics',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 21.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Performance & compliance data',
                                  style: AppTypography.body().copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          _TabButton(
                            label: 'Daily',
                            selected: _selectedTab == 'Daily',
                            onTap: () => setState(() => _selectedTab = 'Daily'),
                          ),
                          SizedBox(width: 10.w),
                          _TabButton(
                            label: 'Weekly',
                            selected: _selectedTab == 'Weekly',
                            onTap: () =>
                                setState(() => _selectedTab = 'Weekly'),
                          ),
                          SizedBox(width: 10.w),
                          _TabButton(
                            label: 'Monthly',
                            selected: _selectedTab == 'Monthly',
                            onTap: () =>
                                setState(() => _selectedTab = 'Monthly'),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: double.infinity,
                          height: 56.h,
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E46CE),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate,
                                  style: AppTypography.body().copyWith(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && viewModel.reports.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadReports(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              14.h,
                              16.w,
                              18.h,
                            ),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ExportButton(
                                      label: 'Excel',
                                      onTap: () => _export('Excel'),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _ExportButton(
                                      label: 'PDF',
                                      onTap: () => _export('PDF'),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 14.h),
                              GridView.builder(
                                itemCount: metrics.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12.w,
                                      mainAxisSpacing: 12.h,
                                      childAspectRatio: 1.03,
                                    ),
                                itemBuilder: (context, index) =>
                                    _MetricCard(item: metrics[index]),
                              ),
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.fromLTRB(
                                  14.w,
                                  14.h,
                                  14.w,
                                  10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.bar_chart,
                                          size: 18.sp,
                                          color: const Color(0xFF111827),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          'Weekly Activity',
                                          style: AppTypography.body().copyWith(
                                            fontSize: 16.sp,
                                            color: const Color(0xFF1F2937),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    ...weekly.map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.only(bottom: 12.h),
                                        child: _WeeklyRow(
                                          item: entry,
                                          maxHours: weekly
                                              .map((e) => e.hours)
                                              .reduce((a, b) => a > b ? a : b),
                                        ),
                                      ),
                                    ),
                                  ],
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
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDCE6F9) : const Color(0xFF0E46CE),
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: selected ? const Color(0xFF155EFC) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExportButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3A74E9),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        minimumSize: Size.fromHeight(40.h),
        elevation: 0,
      ),
      icon: Icon(Icons.download, size: 16.sp),
      label: Text(
        label,
        style: AppTypography.body().copyWith(
          fontSize: 12.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36.h,
            width: 36.h,
            decoration: BoxDecoration(
              color: item.iconBox,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            item.value,
            style: AppTypography.title().copyWith(
              fontSize: 20.sp,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            item.title,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            item.trend,
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              color: item.trendColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyRow extends StatelessWidget {
  final _ActivityItem item;
  final int maxHours;

  const _WeeklyRow({required this.item, required this.maxHours});

  @override
  Widget build(BuildContext context) {
    final progress = maxHours == 0
        ? 0.0
        : (item.hours / maxHours).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.day,
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Text(
              '${item.workers} workers',
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              '${item.hours} reports',
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Stack(
          children: [
            Container(
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 12.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricItem {
  final String title;
  final String value;
  final String trend;
  final Color trendColor;
  final IconData icon;
  final Color iconBox;
  final Color iconColor;

  const _MetricItem({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.icon,
    required this.iconBox,
    required this.iconColor,
  });
}

class _ActivityItem {
  final String day;
  final int workers;
  final int hours;

  const _ActivityItem({
    required this.day,
    required this.workers,
    required this.hours,
  });
}

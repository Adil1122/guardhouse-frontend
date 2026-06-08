import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';

class LiveOperationsScreen extends StatefulWidget {
  const LiveOperationsScreen({super.key});

  @override
  State<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends State<LiveOperationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadShifts();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh shifts when app resumes (user comes back to the screen)
      context.read<AdminViewModel>().loadShifts();
    }
  }

  String _siteName(Map<String, dynamic> shift) {
    final value = (shift['siteName'] ?? '').toString().trim();
    return value.isEmpty ? 'Unknown Site' : value;
  }

  String _officerName(Map<String, dynamic> shift) {
    final value = (shift['securityOfficerName'] ?? '').toString().trim();
    return value.isEmpty ? 'Unassigned' : value;
  }

  String _status(Map<String, dynamic> shift) {
    return (shift['status'] ?? 'Unknown').toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return const Color(0xFF6366F1);
      case 'offered':
        return const Color(0xFF8B5CF6);
      case 'confirmed':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'awaiting':
      case 'scheduled':
        return const Color(0xFFF59E0B);
      case 'checking-welfare':
        return const Color(0xFFF97316);
      case 'clocked-in':
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'clocked-out':
      case 'completed':
        return const Color(0xFF14B8A6);
      case 'clocked-out-offsite':
        return const Color(0xFF06B6D4);
      case 'missed-alert':
        return const Color(0xFFDC2626);
      case 'missed-clock-in':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'clocked-in':
      case 'in progress':
        return 'CLOCKED IN\nON SITE';
      case 'checking-welfare':
        return 'CHECKING\nWELFARE';
      case 'clocked-out':
      case 'completed':
        return 'CLOCKED\nOUT';
      case 'clocked-out-offsite':
        return 'CLOCKED OUT\nOFFSITE';
      case 'awaiting':
      case 'scheduled':
        return 'AWAITING';
      case 'missed-alert':
        return 'MISSED\nALERT';
      case 'missed-clock-in':
        return 'MISSED\nCLOCK-IN';
      case 'confirmed':
        return 'CONFIRMED';
      case 'created':
        return 'CREATED';
      case 'offered':
        return 'OFFERED';
      case 'rejected':
        return 'REJECTED';
      default:
        return status.toUpperCase();
    }
  }

  String _shiftDateFormatted(Map<String, dynamic> shift) {
    try {
      final dateStr = (shift['date']?.toString() ?? '').split('T')[0];
      if (dateStr.isNotEmpty) {
        return DateFormat('EEE MMMM d').format(DateTime.parse(dateStr));
      }
    } catch (_) {}
    return DateFormat('EEE MMMM d').format(DateTime.now());
  }

  String _startTimeFormatted(Map<String, dynamic> shift) {
    final startTime = shift['startTime'];
    if (startTime == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(startTime.toString()));
    } catch (_) {
      final str = startTime.toString();
      if (str.contains('T')) return str.split('T')[1].substring(0, 5);
      return str.contains(':') ? str.substring(0, 5) : str;
    }
  }

  String _endTimeFormatted(Map<String, dynamic> shift) {
    final endTime = shift['endTime'];
    if (endTime == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(endTime.toString()));
    } catch (_) {
      final str = endTime.toString();
      if (str.contains('T')) return str.split('T')[1].substring(0, 5);
      return str.contains(':') ? str.substring(0, 5) : str;
    }
  }

  List<Map<String, dynamic>> _getTodaysShifts(
    List<Map<String, dynamic>> allShifts,
  ) {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    return allShifts.where((shift) {
      final shiftDate = shift['date'];
      if (shiftDate == null) return false;
      try {
        final parsedDate = DateTime.parse(shiftDate);
        final shiftDateString = DateFormat('yyyy-MM-dd').format(parsedDate);
        return shiftDateString == todayString;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupShiftsByStatus(
    List<Map<String, dynamic>> shifts,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final shift in shifts) {
      final status = _status(shift).toLowerCase();
      // Map to the categories mentioned
      String category;
      switch (status) {
        case 'awaiting':
        case 'scheduled': // Map scheduled shifts to awaiting
          category = 'Awaiting';
          break;
        case 'clocked-in':
        case 'in progress': // Map in progress to clocked in
          category = 'Clocked in';
          break;
        case 'missed-alert':
        case 'missed-clock-in':
          category = 'Missed beeps';
          break;
        case 'checking-welfare':
          category = 'Checking welfare';
          break;
        case 'clocked-out':
        case 'completed': // Map completed to clocked out
          category = 'Clocked out';
          break;
        default:
          category = 'Awaiting'; // Default to awaiting for unknown statuses
      }

      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(shift);
    }

    return grouped;
  }

  List<Map<String, dynamic>> _getMockShifts() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return [
      // Awaiting (using Scheduled status)
      {
        'siteName': 'Downtown Mall',
        'securityOfficerName': 'John Smith',
        'date': today,
        'startTime': '2026-04-09T08:00:00',
        'endTime': '2026-04-09T16:00:00',
        'status': 'Scheduled',
      },
      {
        'siteName': 'Central Bank',
        'securityOfficerName': 'Sarah Johnson',
        'date': today,
        'startTime': '2026-04-09T09:00:00',
        'endTime': '2026-04-09T17:00:00',
        'status': 'Scheduled',
      },
      // Clocked in (using In Progress status)
      {
        'siteName': 'Tech Park Building A',
        'securityOfficerName': 'Mike Davis',
        'date': today,
        'startTime': '2026-04-09T06:00:00',
        'endTime': '2026-04-09T14:00:00',
        'status': 'In Progress',
      },
      {
        'siteName': 'Hospital Complex',
        'securityOfficerName': 'Emma Wilson',
        'date': today,
        'startTime': '2026-04-09T14:00:00',
        'endTime': '2026-04-09T22:00:00',
        'status': 'In Progress',
      },
      {
        'siteName': 'Shopping Center',
        'securityOfficerName': 'David Brown',
        'date': today,
        'startTime': '2026-04-09T10:00:00',
        'endTime': '2026-04-09T18:00:00',
        'status': 'In Progress',
      },
      // Missed beeps
      {
        'siteName': 'Industrial Park',
        'securityOfficerName': 'Lisa Garcia',
        'date': today,
        'startTime': '2026-04-09T07:00:00',
        'endTime': '2026-04-09T15:00:00',
        'status': 'missed-alert',
      },
      {
        'siteName': 'Office Tower',
        'securityOfficerName': 'Robert Miller',
        'date': today,
        'startTime': '2026-04-09T08:30:00',
        'endTime': '2026-04-09T16:30:00',
        'status': 'missed-clock-in',
      },
      // Checking welfare
      {
        'siteName': 'Residential Complex',
        'securityOfficerName': 'Jennifer Lee',
        'date': today,
        'startTime': '2026-04-09T12:00:00',
        'endTime': '2026-04-09T20:00:00',
        'status': 'checking-welfare',
      },
      // Clocked out (using Completed status)
      {
        'siteName': 'Airport Terminal',
        'securityOfficerName': 'James Taylor',
        'date': today,
        'startTime': '2026-04-09T04:00:00',
        'endTime': '2026-04-09T12:00:00',
        'status': 'Completed',
      },
      {
        'siteName': 'Stadium',
        'securityOfficerName': 'Maria Rodriguez',
        'date': today,
        'startTime': '2026-04-09T16:00:00',
        'endTime': '2026-04-09T00:00:00',
        'status': 'Completed',
      },
      {
        'siteName': 'University Campus',
        'securityOfficerName': 'Kevin Anderson',
        'date': today,
        'startTime': '2026-04-09T18:00:00',
        'endTime': '2026-04-09T02:00:00',
        'status': 'Completed',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allShifts = viewModel.shifts;

        // If shifts haven't been loaded yet, load them
        if (allShifts.isEmpty && !viewModel.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminViewModel>().loadShifts();
          });
        }

        final todaysShifts = _getTodaysShifts(allShifts);

        // Combine real shifts with mock data for demonstration
        final mockShifts = _getMockShifts();
        final combinedShifts = [...todaysShifts, ...mockShifts];

        final groupedShifts = _groupShiftsByStatus(combinedShifts);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
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
                                  'Live Operations',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${combinedShifts.length} shifts today',
                                  style: AppTypography.label().copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && allShifts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadShifts(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              24.h,
                            ),
                            children: [
                              if (groupedShifts.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No shifts for today',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...groupedShifts.entries.map((entry) {
                                  final category = entry.key;
                                  final shifts = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 24.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style: AppTypography.title().copyWith(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textprimaryDark,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        ...shifts.map(
                                          (shift) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 8.h,
                                            ),
                                            child: _ShiftCard(
                                              siteName: _siteName(shift),
                                              officerName: _officerName(shift),
                                              shiftDate: _shiftDateFormatted(
                                                shift,
                                              ),
                                              startTime: _startTimeFormatted(
                                                shift,
                                              ),
                                              endTime: _endTimeFormatted(shift),
                                              status: _status(shift),
                                              statusLabel: _statusLabel(
                                                _status(shift),
                                              ),
                                              statusColor: _statusColor(
                                                _status(shift),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
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

class _ShiftCard extends StatelessWidget {
  final String siteName;
  final String officerName;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final String status;
  final String statusLabel;
  final Color statusColor;

  const _ShiftCard({
    required this.siteName,
    required this.officerName,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left status panel
            Container(
              width: 82.w,
              color: statusColor,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.h),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                  height: 1.4,
                ),
              ),
            ),
            // Right detail panel
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            siteName,
                            style: AppTypography.title().copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      officerName,
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      shiftDate,
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Start : $startTime (My time : $startTime)',
                      style: AppTypography.body().copyWith(
                        fontSize: 11.sp,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'End : $endTime (My time : $endTime)',
                      style: AppTypography.body().copyWith(
                        fontSize: 11.sp,
                        color: const Color(0xFF374151),
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
  }
}

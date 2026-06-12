import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCalendarView = false;
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedCalendarDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadShifts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _customerName(Map<String, dynamic> shift) {
    final value = (shift['customerName'] ?? shift['customer_name'] ?? '').toString().trim();
    return value.isEmpty ? 'Unknown Customer' : value;
  }

  String _siteName(Map<String, dynamic> shift) {
    final value = (shift['siteName'] ?? shift['site']?['name'] ?? '').toString().trim();
    return value.isEmpty ? 'Unknown Site' : value;
  }

  String _officerName(Map<String, dynamic> shift) {
    final value = (shift['securityOfficerName'] ?? shift['assigned_to']?['name'] ?? '').toString().trim();
    return value.isEmpty ? 'Unassigned' : value;
  }

  String _serviceType(Map<String, dynamic> shift) {
    final value = (shift['serviceType'] ?? shift['service_type'] ?? '').toString().trim();
    return value.isEmpty ? 'Guard' : value;
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dateTime = DateTime(2000, 1, 1, hour, minute);
        return DateFormat('h:mm a').format(dateTime);
      }
    } catch (_) {}
    return time;
  }

  String _shiftTime(Map<String, dynamic> shift) {
    final start = shift['startTime'] ?? shift['start_time'] ?? '';
    final end = shift['endTime'] ?? shift['end_time'] ?? '';
    
    final startFormatted = _formatTime(start.toString());
    final endFormatted = _formatTime(end.toString());
    
    return '$startFormatted - $endFormatted';
  }

  String _date(Map<String, dynamic> shift) {
    final dateStr = (shift['date'] ?? shift['start_date'])?.toString() ?? '';
    if (dateStr.isEmpty) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _status(Map<String, dynamic> shift) {
    final value = (shift['status'] ?? '').toString().trim();
    return value.isEmpty ? 'Scheduled' : value;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return const Color(0xFF6366F1); // Indigo
      case 'offered':
        return const Color(0xFF8B5CF6); // Purple
      case 'confirmed':
        return const Color(0xFF10B981); // Green
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'awaiting':
        return const Color(0xFFF59E0B); // Amber
      case 'checking-welfare':
        return const Color(0xFFF97316); // Orange
      case 'clocked-in':
        return const Color(0xFF3B82F6); // Blue
      case 'clocked-out':
        return const Color(0xFF14B8A6); // Teal
      case 'clocked-out-offsite':
        return const Color(0xFF06B6D4); // Cyan
      case 'missed-alert':
        return const Color(0xFFDC2626); // Dark red
      case 'missed-clock-in':
        return const Color(0xFFEC4899); // Pink
      // legacy
      case 'completed':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'scheduled':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return const Color(0xFFEEF2FF);
      case 'offered':
        return const Color(0xFFF5F3FF);
      case 'confirmed':
        return const Color(0xFFECFDF5);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'awaiting':
        return const Color(0xFFFEF3C7);
      case 'checking-welfare':
        return const Color(0xFFFFF7ED);
      case 'clocked-in':
        return const Color(0xFFEFF6FF);
      case 'clocked-out':
        return const Color(0xFFF0FDFA);
      case 'clocked-out-offsite':
        return const Color(0xFFECFEFF);
      case 'missed-alert':
        return const Color(0xFFFEE2E2);
      case 'missed-clock-in':
        return const Color(0xFFFCE7F3);
      // legacy
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'in progress':
        return const Color(0xFFEFF6FF);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'scheduled':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _showShiftSheet({Map<String, dynamic>? shift}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _ShiftFormSheet(isEdit: shift != null, shift: shift),
    );

    if (result == true && mounted) {
      context.read<AdminViewModel>().loadShifts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shift == null
                ? 'Shift created successfully'
                : 'Shift updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> shift) async {
    final shiftId = shift['id'];
    if (shiftId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shift'),
        content: Text(
          'Are you sure you want to delete this shift for ${_customerName(shift)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AdminViewModel>().deleteShift(
        shiftId.toString(),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allShifts = viewModel.shifts;
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? allShifts
            : allShifts.where((shift) {
                return _customerName(shift).toLowerCase().contains(query) ||
                    _siteName(shift).toLowerCase().contains(query) ||
                    _officerName(shift).toLowerCase().contains(query) ||
                    _serviceType(shift).toLowerCase().contains(query);
              }).toList();

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
                                  'Shift Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${allShifts.length} total shifts',
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
                      SizedBox(height: 14.h),
                      Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A43C7),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 22.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: AppTypography.body().copyWith(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search shifts...',
                                  hintStyle: AppTypography.body().copyWith(
                                    fontSize: 15.sp,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && allShifts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadShifts(),
                          child: _buildListView(filtered),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> shifts) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: () => _showShiftSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B122),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.add, size: 27.sp),
            label: Text(
              'Add Shift',
              style: AppTypography.body().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        if (shifts.isEmpty)
          Container(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            alignment: Alignment.center,
            child: Text(
              'No shifts found',
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          )
        else
          ...shifts.map(
            (shift) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _ShiftCard(
                customerName: _customerName(shift),
                siteName: _siteName(shift),
                officerName: _officerName(shift),
                serviceType: _serviceType(shift),
                shiftTime: _shiftTime(shift),
                date: _date(shift),
                status: _status(shift),
                statusColor: _statusColor(_status(shift)),
                statusBackgroundColor: _statusBackgroundColor(_status(shift)),
                onDelete: () => _confirmDelete(shift),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarView(List<Map<String, dynamic>> allShifts) {
    final shiftsByDate = <String, List<Map<String, dynamic>>>{};
    for (final shift in allShifts) {
      final dateValue = shift['date'] ?? shift['start_date'];
      final dateStr = (dateValue?.toString() ?? '').split('T')[0];
      if (dateStr.isNotEmpty) {
        shiftsByDate.putIfAbsent(dateStr, () => []).add(shift);
      }
    }

    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    ).day;
    final startOffset = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6

    final selectedDateKey = _selectedCalendarDate == null
        ? null
        : '${_selectedCalendarDate!.year}-'
              '${_selectedCalendarDate!.month.toString().padLeft(2, '0')}-'
              '${_selectedCalendarDate!.day.toString().padLeft(2, '0')}';
    final selectedShifts = selectedDateKey != null
        ? (shiftsByDate[selectedDateKey] ?? <Map<String, dynamic>>[])
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewToggle(),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton.icon(
              onPressed: () => _showShiftSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B122),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.add, size: 27.sp),
              label: Text(
                'Add Shift',
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                        );
                        _selectedCalendarDate = null;
                      }),
                      icon: Icon(
                        Icons.chevron_left,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_calendarMonth),
                      style: AppTypography.body().copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                        );
                        _selectedCalendarDate = null;
                      }),
                      icon: Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Day of week labels
                Row(
                  children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: AppTypography.body().copyWith(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 4.h),
                // Calendar grid
                ...List.generate(
                  ((startOffset + daysInMonth) / 7).ceil(),
                  (weekIndex) => Row(
                    children: List.generate(7, (dayIndex) {
                      final cellIndex = weekIndex * 7 + dayIndex;
                      final day = cellIndex - startOffset + 1;
                      if (day < 1 || day > daysInMonth) {
                        return Expanded(child: SizedBox(height: 52.h));
                      }
                      final dateKey =
                          '${_calendarMonth.year}-'
                          '${_calendarMonth.month.toString().padLeft(2, '0')}-'
                          '${day.toString().padLeft(2, '0')}';
                      final dayShifts = shiftsByDate[dateKey] ?? [];
                      final isSelected =
                          _selectedCalendarDate?.day == day &&
                          _selectedCalendarDate?.month ==
                              _calendarMonth.month &&
                          _selectedCalendarDate?.year == _calendarMonth.year;
                      final today = DateTime.now();
                      final isToday =
                          today.day == day &&
                          today.month == _calendarMonth.month &&
                          today.year == _calendarMonth.year;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedCalendarDate = isSelected
                                ? null
                                : DateTime(
                                    _calendarMonth.year,
                                    _calendarMonth.month,
                                    day,
                                  );
                          }),
                          child: Container(
                            height: 52.h,
                            margin: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: AppTypography.body().copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                        ? AppColors.primary
                                        : const Color(0xFF374151),
                                  ),
                                ),
                                if (dayShifts.isNotEmpty) ...[
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: dayShifts
                                        .take(3)
                                        .map(
                                          (s) => Container(
                                            width: 5.w,
                                            height: 5.w,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 1.w,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white
                                                  : _statusColor(_status(s)),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Legend
          Wrap(
            spacing: 10.w,
            runSpacing: 6.h,
            children: [
              _LegendDot(label: 'created', color: const Color(0xFF6366F1)),
              _LegendDot(label: 'offered', color: const Color(0xFF8B5CF6)),
              _LegendDot(label: 'confirmed', color: const Color(0xFF10B981)),
              _LegendDot(label: 'rejected', color: const Color(0xFFEF4444)),
              _LegendDot(label: 'awaiting', color: const Color(0xFFF59E0B)),
              _LegendDot(
                label: 'checking-welfare',
                color: const Color(0xFFF97316),
              ),
              _LegendDot(label: 'clocked-in', color: const Color(0xFF3B82F6)),
              _LegendDot(label: 'clocked-out', color: const Color(0xFF14B8A6)),
              _LegendDot(
                label: 'clocked-out-offsite',
                color: const Color(0xFF06B6D4),
              ),
              _LegendDot(label: 'missed-alert', color: const Color(0xFFDC2626)),
              _LegendDot(
                label: 'missed-clock-in',
                color: const Color(0xFFEC4899),
              ),
            ],
          ),
          if (_selectedCalendarDate != null) ...[
            SizedBox(height: 16.h),
            Text(
              selectedShifts.isEmpty
                  ? 'No shifts on ${DateFormat('MMM d, yyyy').format(_selectedCalendarDate!)}'
                  : '${selectedShifts.length} shift${selectedShifts.length == 1 ? '' : 's'} on ${DateFormat('MMM d, yyyy').format(_selectedCalendarDate!)}',
              style: AppTypography.body().copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            SizedBox(height: 8.h),
            ...selectedShifts.map(
              (shift) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ShiftCard(
                  customerName: _customerName(shift),
                  siteName: _siteName(shift),
                  officerName: _officerName(shift),
                  serviceType: _serviceType(shift),
                  shiftTime: _shiftTime(shift),
                  date: _date(shift),
                  status: _status(shift),
                  statusColor: _statusColor(_status(shift)),
                  statusBackgroundColor: _statusBackgroundColor(_status(shift)),
                  onDelete: () => _confirmDelete(shift),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCalendarView = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: !_isCalendarView ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: !_isCalendarView
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      size: 16.sp,
                      color: !_isCalendarView
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'List View',
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        fontWeight: !_isCalendarView
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: !_isCalendarView
                            ? AppColors.primary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCalendarView = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: _isCalendarView ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: _isCalendarView
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16.sp,
                      color: _isCalendarView
                          ? AppColors.primary
                          : const Color(0xFF9CA3AF),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Calendar View',
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        fontWeight: _isCalendarView
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _isCalendarView
                            ? AppColors.primary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9.w,
          height: 9.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 10.sp,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final String customerName;
  final String siteName;
  final String officerName;
  final String serviceType;
  final String shiftTime;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBackgroundColor;
  final VoidCallback onDelete;

  const _ShiftCard({
    required this.customerName,
    required this.siteName,
    required this.officerName,
    required this.serviceType,
    required this.shiftTime,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.onDelete,
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: AppTypography.body().copyWith(
                    fontSize: 16.sp,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusBackgroundColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  status,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            siteName,
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '$officerName • $serviceType',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _InfoBox(label: 'Date', value: date),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _InfoBox(label: 'Time', value: shiftTime),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 38.h,
            child: ElevatedButton(
              onPressed: onDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7CDD1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text(
                'Delete',
                style: AppTypography.body().copyWith(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftFormSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? shift;

  const _ShiftFormSheet({required this.isEdit, this.shift});

  @override
  State<_ShiftFormSheet> createState() => _ShiftFormSheetState();
}

class _ShiftFormSheetState extends State<_ShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerPOController;
  late final TextEditingController _mealBreakController;

  final List<String> _serviceTypes = ['Guard', 'Patrol'];
  final List<String> _noteTypes = ['Internal', 'External'];

  final List<String> _timezones = [
    // Africa
    'Africa/Abidjan',
    'Africa/Accra',
    'Africa/Addis_Ababa',
    'Africa/Cairo',
    'Africa/Johannesburg',
    'Africa/Lagos',
    'Africa/Nairobi',
    // America
    'America/Anchorage',
    'America/Bogota',
    'America/Buenos_Aires',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Mexico_City',
    'America/New_York',
    'America/Phoenix',
    'America/Sao_Paulo',
    'America/Toronto',
    'America/Vancouver',
    // Asia
    'Asia/Bangkok',
    'Asia/Colombo',
    'Asia/Dhaka',
    'Asia/Dubai',
    'Asia/Hong_Kong',
    'Asia/Jakarta',
    'Asia/Karachi',
    'Asia/Kathmandu',
    'Asia/Kolkata',
    'Asia/Kuala_Lumpur',
    'Asia/Manila',
    'Asia/Riyadh',
    'Asia/Seoul',
    'Asia/Shanghai',
    'Asia/Singapore',
    'Asia/Taipei',
    'Asia/Tehran',
    'Asia/Tokyo',
    // Atlantic
    'Atlantic/Azores',
    'Atlantic/Cape_Verde',
    // Australia
    'Australia/Adelaide',
    'Australia/Brisbane',
    'Australia/Darwin',
    'Australia/Melbourne',
    'Australia/Perth',
    'Australia/Sydney',
    // Europe
    'Europe/Amsterdam',
    'Europe/Athens',
    'Europe/Berlin',
    'Europe/Brussels',
    'Europe/Budapest',
    'Europe/Copenhagen',
    'Europe/Dublin',
    'Europe/Helsinki',
    'Europe/Istanbul',
    'Europe/Kyiv',
    'Europe/Lisbon',
    'Europe/London',
    'Europe/Madrid',
    'Europe/Moscow',
    'Europe/Oslo',
    'Europe/Paris',
    'Europe/Prague',
    'Europe/Rome',
    'Europe/Stockholm',
    'Europe/Vienna',
    'Europe/Warsaw',
    'Europe/Zurich',
    // Pacific
    'Pacific/Auckland',
    'Pacific/Fiji',
    'Pacific/Guam',
    'Pacific/Honolulu',
    'Pacific/Midway',
    // UTC
    'UTC',
  ];

  int _currentTabIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  String? _selectedNoteType;

  bool _isSubmitting = false;
  String? _selectedTimezone;
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedSite;
  String? _selectedServiceType;
  Map<String, dynamic>? _selectedOfficer;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Map<String, dynamic>? _selectedServiceGroup;
  Map<String, dynamic>? _selectedPayGroup;
  Map<String, dynamic>? _selectedQuestionnaire;
  DateTime? _endDate;

  bool _hasDateError = false;
  bool _hasStartTimeError = false;
  bool _hasEndTimeError = false;

  List<Map<String, dynamic>> _customerSites = [];

  @override
  void initState() {
    super.initState();
    final shift = widget.shift;

    _customerPOController = TextEditingController(
      text: (shift?['customerPO'] ?? '').toString(),
    );
    _mealBreakController = TextEditingController(
      text: (shift?['mealBreakDuration'] ?? '').toString(),
    );

    if (shift != null) {
      _selectedServiceType = (shift['service_type'] ?? shift['serviceType'])?.toString();
      // Map backend values back to UI labels if needed
      if (_selectedServiceType == 'static-guard') _selectedServiceType = 'Guard';
      if (_selectedServiceType == 'mobile-patrol') _selectedServiceType = 'Patrol';

      _selectedTimezone = (shift['timezone'] ?? shift['timezone'])?.toString();

      // Parse date
      final dateStr = (shift['start_date'] ?? shift['date'])?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(dateStr);
        } catch (e) {
          _selectedDate = null;
        }
      }

      // Parse end date
      final endDateStr = (shift['end_date'] ?? shift['endDate'])?.toString();
      if (endDateStr != null && endDateStr.isNotEmpty) {
        try {
          _endDate = DateTime.parse(endDateStr);
        } catch (e) {
          _endDate = null;
        }
      }

      // Parse times
      final startTimeStr = (shift['start_time'] ?? shift['startTime'])?.toString();
      if (startTimeStr != null && startTimeStr.isNotEmpty) {
        try {
          final parts = startTimeStr.split(':');
          _startTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          _startTime = null;
        }
      }

      final endTimeStr = (shift['end_time'] ?? shift['endTime'])?.toString();
      if (endTimeStr != null && endTimeStr.isNotEmpty) {
        try {
          final parts = endTimeStr.split(':');
          _endTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          _endTime = null;
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final viewModel = context.read<AdminViewModel>();
    if (viewModel.customers.isNotEmpty && widget.shift != null) {
      final customerId = (widget.shift!['customer_id'] ?? widget.shift!['customerId']);
      _selectedCustomer = viewModel.customers.firstWhere(
        (c) => (c['profile_id'] ?? c['id'])?.toString() == customerId?.toString(),
        orElse: () => {},
      );
      if (_selectedCustomer != null && _selectedCustomer!.isNotEmpty) {
        _loadCustomerSites((_selectedCustomer!['profile_id'] ?? _selectedCustomer!['id']).toString());
      }
    }
  }

  Future<void> _loadCustomerSites(String customerId) async {
    try {
      final viewModel = context.read<AdminViewModel>();
      final sites = await viewModel.getCustomerSites(customerId);
      setState(() {
        _customerSites = sites;
        if (widget.shift != null) {
          final siteId = widget.shift!['siteId'];
          _selectedSite = sites.firstWhere(
            (s) => s['id'] == siteId,
            orElse: () => {},
          );
        }
      });
    } catch (e) {
      // Handle error silently or show user-friendly message
      setState(() {
        _customerSites = [];
      });
    }
  }

  @override
  void dispose() {
    _customerPOController.dispose();
    _mealBreakController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await UltimateMobileTimePicker.show(
      context,
      initialTime: isStart
          ? _startTime ?? TimeOfDay.now()
          : _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _hasStartTimeError = false;
        } else {
          _endTime = picked;
          _hasEndTimeError = false;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '00:00:00';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final shiftPayload = {
      if (widget.isEdit) 'id': widget.shift?['id'],
      'site_id': _selectedSite?['id'],
      'service_type': _selectedServiceType == 'Guard' ? 'static-guard' : 'mobile-patrol',
      'assigned_to': _selectedOfficer?['user_id'] ?? _selectedOfficer?['id'],
      'start_date': _selectedDate?.toIso8601String().split('T')[0],
      'end_date': _endDate?.toIso8601String().split('T')[0],
      'start_time': _formatTime(_startTime),
      'end_time': _formatTime(_endTime),
      'break_duration': int.tryParse(_mealBreakController.text.trim()) ?? 0,
      'service_group_id': _selectedServiceGroup?['id'],
      'pay_group_id': _selectedPayGroup?['id'],
      'customer_po': _customerPOController.text.trim(),
      'questionnaire': (_selectedQuestionnaire?['name']?.toString().toLowerCase().contains('site') ?? false) ? 'site' : 'global',
      'timezone': _selectedTimezone,
      'status': 'created',
    };

    final viewModel = context.read<AdminViewModel>();
    final success = widget.isEdit
        ? await viewModel.updateShift(shiftPayload)
        : await viewModel.createShift(shiftPayload);

    if (mounted) {
      if (success) {
        final noteText = _notesController.text.trim();
        if (noteText.isNotEmpty) {
          final shiftId = widget.isEdit
              ? (widget.shift?['id'])
              : (viewModel.shifts.isNotEmpty
                    ? viewModel.shifts.last['id']
                    : null);
          if (shiftId != null) {
            await viewModel.createShiftNote({
              'type': (_selectedNoteType ?? 'Internal').toLowerCase(),
              'note': noteText,
              'shiftId': shiftId,
              'createdBy': 'Admin',
              'createdDate': DateTime.now().toIso8601String().split('T').first,
            });
          }
        }
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to save shift'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobile UI fix: Force controller text and dropdown values to sync on each build
    if (widget.isEdit && widget.shift != null && _selectedCustomer == null) {
      final shift = widget.shift!;
      final vm = context.read<AdminViewModel>();
      
      _selectedServiceType = (shift['service_type'] ?? shift['serviceType'])?.toString();
      if (_selectedServiceType == 'static-guard') _selectedServiceType = 'Guard';
      if (_selectedServiceType == 'mobile-patrol') _selectedServiceType = 'Patrol';

      _selectedTimezone = (shift['timezone'] ?? shift['timezone'])?.toString();
      
      if (vm.customers.isNotEmpty) {
        final customerId = (shift['customer_id'] ?? shift['customerId']);
        _selectedCustomer = vm.customers.firstWhere(
          (c) => (c['profile_id'] ?? c['id'])?.toString() == customerId?.toString(),
          orElse: () => {},
        );
        if (_selectedCustomer!.isNotEmpty) {
          _loadCustomerSites((_selectedCustomer!['profile_id'] ?? _selectedCustomer!['id']).toString());
        }
      }
      
      if (vm.securityOfficers.isNotEmpty) {
        _selectedOfficer = vm.securityOfficers.firstWhere(
          (o) => o['id']?.toString() == shift['officerId']?.toString(),
          orElse: () => {},
        );
      }
    }
    
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final currentCustomerId = (_selectedCustomer?['profile_id'] ?? _selectedCustomer?['id'])?.toString();
        final validCustomerId = (currentCustomerId != null && viewModel.customers.any((c) => (c['profile_id'] ?? c['id'])?.toString() == currentCustomerId)) ? currentCustomerId : null;

        final currentSiteId = _selectedSite?['id']?.toString();
        final validSiteId = (currentSiteId != null && viewModel.sites.any((s) => s['id']?.toString() == currentSiteId)) ? currentSiteId : null;

        final currentOfficerId = _selectedOfficer?['id']?.toString();
        final validOfficerId = (currentOfficerId != null && viewModel.securityOfficers.any((o) => o['id']?.toString() == currentOfficerId)) ? currentOfficerId : null;

        final currentServiceGroupId = _selectedServiceGroup?['id']?.toString();
        final validServiceGroupId = (currentServiceGroupId != null && viewModel.serviceGroups.any((g) => g['id']?.toString() == currentServiceGroupId)) ? currentServiceGroupId : null;

        final currentPayGroupId = _selectedPayGroup?['id']?.toString();
        final validPayGroupId = (currentPayGroupId != null && viewModel.payGroups.any((g) => g['id']?.toString() == currentPayGroupId)) ? currentPayGroupId : null;

        final currentQuestionnaireId = _selectedQuestionnaire?['id']?.toString();
        final validQuestionnaireId = (currentQuestionnaireId != null && viewModel.clockInQuestionnaires.any((q) => q['id']?.toString() == currentQuestionnaireId)) ? currentQuestionnaireId : null;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: Column(
                  children: [
                    Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      widget.isEdit ? 'Edit Shift' : 'Add Shift',
                      style: AppTypography.title().copyWith(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomPadding),
                  child: Column(
                    children: [
                      Offstage(
                        offstage: _currentTabIndex != 0,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer Dropdown
                               UltimateMobileDropdown<String>(
                                 value: validCustomerId,
                                 decoration: _inputDecoration(
                                   'Choose Customer *',
                                 ),
                                 items: viewModel.customers
                                     .map(
                                       (customer) => DropdownMenuItem(
                                         value: (customer['profile_id'] ?? customer['id'])?.toString(),
                                         child: Text(
                                           '${customer['first_name'] ?? customer['firstName'] ?? ''} ${customer['last_name'] ?? customer['lastName'] ?? ''}',
                                         ),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (id) {
                                   setState(() {
                                     _selectedCustomer = viewModel.customers.firstWhere(
                                       (c) => (c['profile_id'] ?? c['id'])?.toString() == id,
                                       orElse: () => {},
                                     );
                                     _selectedSite = null;
                                   });
                                   if (id != null) {
                                     _loadCustomerSites(id);
                                   }
                                 },
                                 validator: (value) => value == null
                                     ? 'Customer is required'
                                     : null,
                               ),
                              SizedBox(height: 12.h),

                               // Site Dropdown
                               UltimateMobileDropdown<String>(
                                 value: validSiteId,
                                 decoration: _inputDecoration('Choose Site *'),
                                 items: viewModel.sites
                                     .map(
                                       (site) => DropdownMenuItem(
                                         value: site['id']?.toString(),
                                         child: Text(site['name'] ?? ''),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (id) =>
                                     setState(() => _selectedSite = viewModel.sites.firstWhere(
                                       (s) => s['id']?.toString() == id,
                                       orElse: () => {},
                                     )),
                                 validator: (value) =>
                                     value == null ? 'Site is required' : null,
                               ),
                              SizedBox(height: 12.h),

                              // Service Type Dropdown
                               UltimateMobileDropdown<String>(
                                 value: (_serviceTypes.contains(_selectedServiceType))
                                     ? _selectedServiceType
                                     : null,
                                 decoration: _inputDecoration(
                                   'Choose Service Type *',
                                 ),
                                 items: _serviceTypes
                                     .map(
                                       (type) => DropdownMenuItem(
                                         value: type,
                                         child: Text(type),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (value) => setState(
                                   () => _selectedServiceType = value,
                                 ),
                                 validator: (value) => value == null
                                     ? 'Service type is required'
                                     : null,
                               ),
                              SizedBox(height: 12.h),

                              // Security Officer Dropdown
                               UltimateMobileDropdown<String>(
                                 value: validOfficerId,
                                 decoration: _inputDecoration(
                                   'Choose Security Officer *',
                                 ),
                                 items: viewModel.securityOfficers
                                     .map(
                                       (officer) => DropdownMenuItem(
                                         value: (officer['user_id'] ?? officer['id'])?.toString(),
                                         child: Text(
                                           '${officer['firstName'] ?? officer['first_name'] ?? officer['name'] ?? ''} ${officer['lastName'] ?? officer['last_name'] ?? ''}'.trim(),
                                         ),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (id) =>
                                     setState(() => _selectedOfficer = viewModel.securityOfficers.firstWhere(
                                       (o) => (o['user_id'] ?? o['id'])?.toString() == id,
                                       orElse: () => {},
                                     )),
                                 validator: (value) => value == null
                                     ? 'Security officer is required'
                                     : null,
                               ),
                              SizedBox(height: 12.h),

                              // Date Selection
                               UltimateMobileDatePicker(
                                 label: 'Start Date *',
                                 value: _selectedDate,
                                 onDateSelected: (date) => setState(() {
                                   _selectedDate = date;
                                   _hasDateError = false;
                                 }),
                                 decoration: _inputDecoration(
                                   'Start Date *',
                                   errorText: _hasDateError ? 'Start Date is required' : null,
                                 ),
                                 firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                 lastDate: DateTime.now().add(const Duration(days: 365)),
                               ),
                               SizedBox(height: 12.h),

                               // End Date Selection
                               UltimateMobileDatePicker(
                                 label: 'End Date (Optional)',
                                 value: _endDate,
                                 onDateSelected: (date) => setState(() => _endDate = date),
                                 decoration: _inputDecoration('End Date (Optional)'),
                                 firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                 lastDate: DateTime.now().add(const Duration(days: 365)),
                               ),

                              SizedBox(height: 12.h),

                              // Time Selection Row
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectTime(true),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: _hasStartTimeError ? Colors.red : const Color(0xFFD1D5DB),
                                            width: _hasStartTimeError ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _startTime == null
                                                    ? 'Start Time *'
                                                    : _startTime!.format(
                                                        context,
                                                      ),
                                                style: AppTypography.body()
                                                    .copyWith(
                                                      fontSize: 14.sp,
                                                      color: _startTime == null
                                                          ? const Color(
                                                              0xFF6B7280,
                                                            )
                                                          : const Color(
                                                              0xFF111827,
                                                            ),
                                                    ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 18.sp,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectTime(false),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 16.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                          border: Border.all(
                                            color: _hasEndTimeError ? Colors.red : const Color(0xFFD1D5DB),
                                            width: _hasEndTimeError ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _endTime == null
                                                    ? 'End Time *'
                                                    : _endTime!.format(context),
                                                style: AppTypography.body()
                                                    .copyWith(
                                                      fontSize: 14.sp,
                                                      color: _endTime == null
                                                          ? const Color(
                                                              0xFF6B7280,
                                                            )
                                                          : const Color(
                                                              0xFF111827,
                                                            ),
                                                    ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 18.sp,
                                              color: const Color(0xFF6B7280),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),

                              // Meal Break Duration
                               UltimateMobileTextField(
                                 controller: _mealBreakController,
                                 keyboardType: TextInputType.number,
                                 decoration: _inputDecoration(
                                   'Meal Break Duration (minutes) *',
                                 ),
                                 validator: (value) {
                                   if (value == null || value.trim().isEmpty) {
                                     return 'Meal break duration is required';
                                   }
                                   if (int.tryParse(value.trim()) == null) {
                                     return 'Enter valid number';
                                   }
                                   return null;
                                 },
                               ),
                              SizedBox(height: 12.h),

                              // Service Group Dropdown
                               UltimateMobileDropdown<String>(
                                 value: validServiceGroupId,
                                 decoration: _inputDecoration(
                                   'Choose Service Group',
                                 ),
                                 items: viewModel.serviceGroups
                                     .map(
                                       (group) => DropdownMenuItem(
                                         value: group['id']?.toString(),
                                         child: Text(group['name'] ?? ''),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (id) => setState(
                                   () => _selectedServiceGroup = viewModel.serviceGroups.firstWhere(
                                     (g) => g['id']?.toString() == id,
                                     orElse: () => {},
                                   ),
                                 ),
                               ),
                              SizedBox(height: 12.h),

                              // Pay Group Dropdown
                               UltimateMobileDropdown<String>(
                                 value: validPayGroupId,
                                 decoration: _inputDecoration(
                                   'Choose Pay Group',
                                 ),
                                 items: viewModel.payGroups
                                     .map(
                                       (group) => DropdownMenuItem(
                                         value: group['id']?.toString(),
                                         child: Text(group['name'] ?? ''),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (id) =>
                                     setState(() => _selectedPayGroup = viewModel.payGroups.firstWhere(
                                       (g) => g['id']?.toString() == id,
                                       orElse: () => {},
                                     )),
                               ),
                              SizedBox(height: 12.h),

                              // Customer PO
                               UltimateMobileTextField(
                                 controller: _customerPOController,
                                 decoration: _inputDecoration(
                                   'Customer PO (Optional)',
                                 ),
                               ),
                              SizedBox(height: 12.h),

                              // Clock-in Questionnaire Dropdown
                               Visibility(
                                 visible: false,
                                 child: Column(
                                   children: [
                                     UltimateMobileDropdown<String>(
                                       value: validQuestionnaireId,
                                       decoration: _inputDecoration(
                                         'Choose Clock-in Questionnaire',
                                       ),
                                       items: viewModel.clockInQuestionnaires
                                           .map(
                                             (quest) => DropdownMenuItem(
                                               value: quest['id']?.toString(),
                                               child: Text(quest['name'] ?? ''),
                                             ),
                                           )
                                           .toList(),
                                       onChanged: (id) => setState(
                                         () => _selectedQuestionnaire = viewModel.clockInQuestionnaires.firstWhere(
                                           (q) => q['id']?.toString() == id,
                                           orElse: () => {},
                                         ),
                                       ),
                                     ),
                                     SizedBox(height: 12.h),
                                   ],
                                 ),
                               ),

                              // Timezone Dropdown
                               UltimateMobileDropdown<String>(
                                 value: _timezones.contains(_selectedTimezone)
                                     ? _selectedTimezone
                                     : null,
                                 decoration: _inputDecoration('Choose Timezone'),
                                 items: _timezones
                                     .map(
                                       (tz) => DropdownMenuItem(
                                         value: tz,
                                         child: Text(
                                           tz.replaceAll('_', ' '),
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                       ),
                                     )
                                     .toList(),
                                 onChanged: (tz) =>
                                     setState(() => _selectedTimezone = tz),
                               ),
                            ],
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: _currentTabIndex != 1,
                        child: _notesStep(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: _currentTabIndex == 0
                      ? ElevatedButton(
                          onPressed: () {
                            bool hasCustomErrors = false;
                            String errorMessage = '';

                            setState(() {
                              _hasDateError = _selectedDate == null;
                              _hasStartTimeError = _startTime == null;
                              _hasEndTimeError = _endTime == null;
                            });

                            if (_hasDateError) {
                              hasCustomErrors = true;
                              errorMessage = 'Start Date is required.';
                            } else if (_hasStartTimeError) {
                              hasCustomErrors = true;
                              errorMessage = 'Start Time is required.';
                            } else if (_hasEndTimeError) {
                              hasCustomErrors = true;
                              errorMessage = 'End Time is required.';
                            }

                            bool isFormValid = _formKey.currentState!.validate();

                            if (hasCustomErrors) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (isFormValid) {
                              setState(() => _currentTabIndex = 1);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E45BA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: AppTypography.body().copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E45BA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isEdit
                                      ? 'Update Shift'
                                      : 'Create Shift',
                                  style: AppTypography.body().copyWith(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE5E7EB), width: 1.h),
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentTabIndex,
                  onTap: (index) {
                    if (index == 1 && _currentTabIndex == 0) {
                      bool hasCustomErrors = false;
                      String errorMessage = '';

                      setState(() {
                        _hasDateError = _selectedDate == null;
                        _hasStartTimeError = _startTime == null;
                        _hasEndTimeError = _endTime == null;
                      });

                      if (_hasDateError) {
                        hasCustomErrors = true;
                        errorMessage = 'Start Date is required.';
                      } else if (_hasStartTimeError) {
                        hasCustomErrors = true;
                        errorMessage = 'Start Time is required.';
                      } else if (_hasEndTimeError) {
                        hasCustomErrors = true;
                        errorMessage = 'End Time is required.';
                      }

                      bool isFormValid = _formKey.currentState!.validate();

                      if (hasCustomErrors) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!isFormValid) return;
                    }
                    setState(() => _currentTabIndex = index);
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF0E45BA),
                  unselectedItemColor: const Color(0xFF9CA3AF),
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.schedule),
                      label: 'Add Shift',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.note_alt_outlined),
                      label: 'Notes',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        Text(
          'Notes (Optional)',
          style: AppTypography.body().copyWith(
            fontSize: 13.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: 12.h),
        UltimateMobileDropdown<String>(
          value: _selectedNoteType,
          decoration: _inputDecoration('Note Type'),
          items: _noteTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) => setState(() => _selectedNoteType = value),
        ),
        SizedBox(height: 12.h),
        UltimateMobileTextField(
          controller: _notesController,
          maxLines: 6,
          decoration: _inputDecoration('Note').copyWith(
            alignLabelWithHint: true,
            hintText: 'Add any notes for this shift...',
          ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

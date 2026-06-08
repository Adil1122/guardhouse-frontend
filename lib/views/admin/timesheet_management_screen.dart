import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../models/timesheet_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:security_app/widgets/ultimate_mobile_widgets.dart';


class TimesheetManagementScreen extends StatefulWidget {
  const TimesheetManagementScreen({super.key});

  @override
  State<TimesheetManagementScreen> createState() =>
      _TimesheetManagementScreenState();
}

class _TimesheetManagementScreenState extends State<TimesheetManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TimesheetStatus? _statusFilter;
  DateTime? _dateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadTimesheets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Timesheet> _getFilteredTimesheets(List<Timesheet> timesheets) {
    var filtered = timesheets;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((timesheet) {
        return timesheet.staffName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            timesheet.customerName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            timesheet.siteName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            timesheet.status.displayName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }).toList();
    }

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered
          .where((timesheet) => timesheet.status == _statusFilter)
          .toList();
    }

    // Date filter
    if (_dateFilter != null) {
      filtered = filtered.where((timesheet) {
        if (timesheet.startDate == null) return false;
        return timesheet.startDate!.year == _dateFilter!.year &&
            timesheet.startDate!.month == _dateFilter!.month &&
            timesheet.startDate!.day == _dateFilter!.day;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Timesheet Management',
          style: AppTypography.title().copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF111827),
            size: 20.sp,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Stats Section
                SizedBox(width: 24.w),
                Consumer<AdminViewModel>(
                  builder: (context, adminViewModel, child) {
                    final timesheets = adminViewModel.timesheets;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildStatsCards(timesheets),
                    );
                  },
                ),
                SizedBox(height: 32.h),

                // Integrated Filters Section (Prevents overflow)
                _buildFiltersSection(),
              ],
            ),
          ),

          // Table Section
          Expanded(
            child: Consumer<AdminViewModel>(
              builder: (context, adminViewModel, child) {
                final timesheets = adminViewModel.timesheets;

                final filteredTimesheets = _getFilteredTimesheets(timesheets);

                return Container(
                  margin: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: filteredTimesheets.isEmpty
                      ? _buildEmptyState()
                      : _buildProfessionalTable(
                          filteredTimesheets,
                          adminViewModel,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFlashMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Line: Search Field (Full Width)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search',
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Icon(
                        Icons.search,
                        color: const Color(0xFF6B7280),
                        size: 20.sp,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF111827),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),

        // Second Line: Status, Date, Refresh Button
        Wrap(
          spacing: 12.w,
          runSpacing: 16.h,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            // Status Filter
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                SizedBox(
                  width: 140.w,
                  height: 44.h,
                  child: UltimateMobileDropdown<TimesheetStatus?>(
                    value: _statusFilter,
                    decoration: _mobileInputDecoration('Status'),
                    hintText: 'Status',
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...TimesheetStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Date Filter
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 150.w,
                      height: 44.h,
                      child: UltimateMobileDatePicker(
                        label: 'Filter Date',
                        value: _dateFilter,
                        onDateSelected: (picked) {
                          setState(() {
                            _dateFilter = picked;
                          });
                        },
                      ),
                    ),
                    if (_dateFilter != null) ...[
                      SizedBox(width: 4.w),
                      IconButton(
                        onPressed: () => setState(() => _dateFilter = null),
                        icon: Icon(
                          Icons.event_busy,
                          color: const Color(0xFF6B7280),
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Refresh Button
            SizedBox(
              width: 44.h,
              height: 44.h,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: () {
                    context.read<AdminViewModel>().loadTimesheets();
                    _showFlashMessage('Timesheets refreshed');
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalTable(
    List<Timesheet> timesheets,
    AdminViewModel adminViewModel,
  ) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Total: ${timesheets.length} timesheets',
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.table_chart,
                color: const Color(0xFF6B7280),
                size: 20.sp,
              ),
            ],
          ),
        ),

        // Scrollable Table Content
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 64.w,
                ),
                child: DataTable(
                  columnSpacing: 24.w,
                  horizontalMargin: 24.w,
                  headingRowHeight: 56.h,
                  dataRowMinHeight: 72.h,
                  dataRowMaxHeight: double.infinity,
                  headingTextStyle: AppTypography.body().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                    letterSpacing: 0.5,
                  ),
                  dataTextStyle: AppTypography.body().copyWith(
                    fontSize: 14.sp,
                    color: const Color(0xFF111827),
                  ),
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: [
                    DataColumn(
                      label: Container(width: 100.w, child: const Text('DATE')),
                    ),
                    DataColumn(
                      label: Container(
                        width: 200.w,
                        child: const Text('CUSTOMER / SITE'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 140.w,
                        child: const Text('STAFF'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 160.w,
                        child: const Text('CLOCK IN/OUT'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 140.w,
                        child: const Text('SERVICE GROUP'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 140.w,
                        child: const Text('PAY GROUP'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 100.w,
                        child: const Text('BREAK'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 180.w,
                        child: const Text('NOTES'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 120.w,
                        child: const Text('START DATE'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 120.w,
                        child: const Text('END DATE'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 160.w,
                        child: const Text('TIMEZONE'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 100.w,
                        child: const Text('STATUS'),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        width: 120.w,
                        child: const Text('ACTIONS'),
                      ),
                    ),
                  ],
                  rows: timesheets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final timesheet = entry.value;
                    return DataRow(
                      color: MaterialStateProperty.all(
                        index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                      ),
                      cells: [
                        DataCell(_buildDateCell(timesheet)),
                        DataCell(_buildCustomerSiteCell(timesheet)),
                        DataCell(_buildStaffCell(timesheet)),
                        DataCell(
                          _buildClockTimeCell(timesheet, adminViewModel),
                        ),
                        DataCell(
                          _buildServiceGroupCell(timesheet, adminViewModel),
                        ),
                        DataCell(_buildPayGroupCell(timesheet, adminViewModel)),
                        DataCell(_buildBreakCell(timesheet, adminViewModel)),
                        DataCell(_buildNotesCell(timesheet, adminViewModel)),
                        DataCell(
                          _buildStartDateCell(timesheet, adminViewModel),
                        ),
                        DataCell(_buildEndDateCell(timesheet, adminViewModel)),
                        DataCell(_buildTimezoneCell(timesheet, adminViewModel)),
                        DataCell(_buildStatusCell(timesheet)),
                        DataCell(_buildActionsCell(timesheet, adminViewModel)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Table Cell Builders
  Widget _buildDateCell(Timesheet timesheet) {
    return Container(
      width: 100.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM d').format(timesheet.date),
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            DateFormat('yyyy').format(timesheet.date),
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSiteCell(Timesheet timesheet) {
    return Container(
      width: 200.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timesheet.customerName,
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            timesheet.siteName,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCell(Timesheet timesheet) {
    return Container(
      width: 140.w,
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Center(
              child: Text(
                timesheet.staffName.isNotEmpty
                    ? timesheet.staffName.substring(0, 1).toUpperCase()
                    : 'S',
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              timesheet.staffName,
              style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockTimeCell(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) {
    return Container(
      width: 160.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clock In
          GestureDetector(
            onTap: () => _editClockInTime(timesheet, adminViewModel),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              margin: EdgeInsets.only(bottom: 4.h),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, size: 14.sp, color: Colors.blue.shade700),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      timesheet.clockInTime != null
                          ? DateFormat('HH:mm').format(timesheet.clockInTime!)
                          : '--:--',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Clock Out
          GestureDetector(
            onTap: () => _editClockOutTime(timesheet, adminViewModel),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.logout,
                    size: 14.sp,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      timesheet.clockOutTime != null
                          ? DateFormat('HH:mm').format(timesheet.clockOutTime!)
                          : '--:--',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildServiceGroupCell(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) {
    return Container(
      width: 140.w,
      child: GestureDetector(
        onTap: () => _editServiceGroup(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                size: 14.sp,
                color: Colors.purple.shade700,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  timesheet.serviceGroup,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayGroupCell(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) {
    return Container(
      width: 140.w,
      child: GestureDetector(
        onTap: () => _editPayGroup(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.teal.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 14.sp,
                color: Colors.teal.shade700,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  timesheet.payGroup.isEmpty
                      ? 'Set pay group'
                      : timesheet.payGroup,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: timesheet.payGroup.isEmpty
                        ? Colors.teal.shade300
                        : Colors.teal.shade700,
                    fontStyle: timesheet.payGroup.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakCell(Timesheet timesheet, AdminViewModel adminViewModel) {
    return Container(
      width: 100.w,
      child: GestureDetector(
        onTap: () => _editBreakMinutes(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.coffee_outlined,
                size: 14.sp,
                color: Colors.green.shade700,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  '${timesheet.breakMinutes}m',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCell(Timesheet timesheet, AdminViewModel adminViewModel) {
    return Container(
      width: 180.w,
      child: GestureDetector(
        onTap: () => _editNotes(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 14.sp,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  timesheet.notes.isEmpty ? 'Add notes...' : timesheet.notes,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: timesheet.notes.isEmpty
                        ? Colors.grey.shade500
                        : Colors.grey.shade700,
                    fontStyle: timesheet.notes.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartDateCell(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) {
    final hasDate = timesheet.startDate != null;
    return Container(
      width: 120.w,
      child: GestureDetector(
        onTap: () => _editStartDate(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13.sp,
                color: Colors.indigo.shade700,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  hasDate
                      ? DateFormat('MMM d, yy').format(timesheet.startDate!)
                      : 'Set date',
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? Colors.indigo.shade700
                        : Colors.indigo.shade300,
                    fontStyle: hasDate ? FontStyle.normal : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndDateCell(Timesheet timesheet, AdminViewModel adminViewModel) {
    final hasDate = timesheet.endDate != null;
    return Container(
      width: 120.w,
      child: GestureDetector(
        onTap: () => _editEndDate(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 13.sp,
                color: Colors.deepOrange.shade700,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  hasDate
                      ? DateFormat('MMM d, yy').format(timesheet.endDate!)
                      : 'Set date',
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? Colors.deepOrange.shade700
                        : Colors.deepOrange.shade300,
                    fontStyle: hasDate ? FontStyle.normal : FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimezoneCell(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) {
    final hasTimezone = timesheet.timezone.isNotEmpty;
    return Container(
      width: 160.w,
      child: GestureDetector(
        onTap: () => _editTimezone(timesheet, adminViewModel),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.public_outlined,
                size: 13.sp,
                color: Colors.cyan.shade700,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  hasTimezone
                      ? timesheet.timezone.replaceAll('_', ' ')
                      : 'Set timezone',
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: hasTimezone
                        ? Colors.cyan.shade700
                        : Colors.cyan.shade300,
                    fontStyle: hasTimezone
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(Timesheet timesheet) {
    Color color;
    IconData icon;
    switch (timesheet.status) {
      case TimesheetStatus.drafted:
        color = Colors.orange;
        icon = Icons.edit_outlined;
        break;
      case TimesheetStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case TimesheetStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case TimesheetStatus.invoiced:
        color = Colors.blue;
        icon = Icons.receipt_long_outlined;
        break;
      case TimesheetStatus.paid:
        color = Colors.purple;
        icon = Icons.payments_outlined;
        break;
      case TimesheetStatus.settled:
        color = Colors.teal;
        icon = Icons.done_all_outlined;
        break;
    }

    return Container(
      width: 100.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                timesheet.status.displayName,
                style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(Timesheet timesheet, AdminViewModel adminViewModel) {
    return Container(
      width: 120.w,
      child: timesheet.status == TimesheetStatus.drafted
          ? Row(
              children: [
                // Approve Button
                Container(
                  width: 32.w,
                  height: 32.w,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        _approveTimesheet(timesheet, adminViewModel),
                    icon: Icon(
                      Icons.check,
                      color: Colors.green.shade700,
                      size: 18.sp,
                    ),
                  ),
                ),
                // Reject Button
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        _rejectTimesheet(timesheet, adminViewModel),
                    icon: Icon(
                      Icons.close,
                      color: Colors.red.shade700,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            )
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Completed',
                style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCards(List<Timesheet> timesheets) {
    final draftedCount = timesheets
        .where((t) => t.status == TimesheetStatus.drafted)
        .length;
    final approvedCount = timesheets
        .where((t) => t.status == TimesheetStatus.approved)
        .length;
    final rejectedCount = timesheets
        .where((t) => t.status == TimesheetStatus.rejected)
        .length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatCard('Drafted', draftedCount, Colors.orange),
        SizedBox(width: 8.w),
        _buildStatCard('Approved', approvedCount, Colors.green),
        SizedBox(width: 8.w),
        _buildStatCard('Rejected', rejectedCount, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTypography.body().copyWith(fontSize: 10.sp, color: color),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _dateFilter = picked;
      });
    }
  }

  InputDecoration _mobileInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(48.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Icon(
                Icons.schedule_outlined,
                size: 40.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Timesheets Found',
              style: AppTypography.title().copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Timesheets will automatically appear here when staff\nclock in and out of their shifts.',
              style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'Try adjusting your filters or create new shifts',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Edit Methods
  void _editClockInTime(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) async {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) {
      return;
    }
    final time = await UltimateMobileTimePicker.show(
      context,
      initialTime: TimeOfDay.fromDateTime(
        timesheet.clockInTime ?? DateTime.now(),
      ),
    );
    if (time != null) {
      final newDateTime = DateTime(
        timesheet.date.year,
        timesheet.date.month,
        timesheet.date.day,
        time.hour,
        time.minute,
      );
      final updatedTimesheet = timesheet.copyWith(clockInTime: newDateTime);
      adminViewModel.updateTimesheet(updatedTimesheet);
    }
  }

  void _editClockOutTime(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) async {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) {
      return;
    }
    final time = await UltimateMobileTimePicker.show(
      context,
      initialTime: TimeOfDay.fromDateTime(
        timesheet.clockOutTime ?? DateTime.now(),
      ),
    );
    if (time != null) {
      final newDateTime = DateTime(
        timesheet.date.year,
        timesheet.date.month,
        timesheet.date.day,
        time.hour,
        time.minute,
      );
      final updatedTimesheet = timesheet.copyWith(clockOutTime: newDateTime);
      adminViewModel.updateTimesheet(updatedTimesheet);
    }
  }

  void _editServiceGroup(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final controller = TextEditingController(text: timesheet.serviceGroup);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'Edit Service Group',
          style: AppTypography.title().copyWith(fontSize: 18.sp),
        ),
        content: Container(
          width: 300.w,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter service group...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTimesheet = timesheet.copyWith(
                serviceGroup: controller.text,
              );
              adminViewModel.updateTimesheet(updatedTimesheet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editPayGroup(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final controller = TextEditingController(text: timesheet.payGroup);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'Edit Pay Group',
          style: AppTypography.title().copyWith(fontSize: 18.sp),
        ),
        content: Container(
          width: 300.w,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter pay group...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTimesheet = timesheet.copyWith(
                payGroup: controller.text,
              );
              adminViewModel.updateTimesheet(updatedTimesheet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editBreakMinutes(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final controller = TextEditingController(
      text: timesheet.breakMinutes.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'Edit Break Time',
          style: AppTypography.title().copyWith(fontSize: 18.sp),
        ),
        content: Container(
          width: 300.w,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter break minutes...',
              suffixText: 'mins',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              final updatedTimesheet = timesheet.copyWith(
                breakMinutes: minutes,
              );
              adminViewModel.updateTimesheet(updatedTimesheet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editNotes(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final controller = TextEditingController(text: timesheet.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'Edit Notes',
          style: AppTypography.title().copyWith(fontSize: 18.sp),
        ),
        content: Container(
          width: 300.w,
          child: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTimesheet = timesheet.copyWith(
                notes: controller.text,
              );
              adminViewModel.updateTimesheet(updatedTimesheet);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editStartDate(
    Timesheet timesheet,
    AdminViewModel adminViewModel,
  ) async {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) {
      return;
    }
    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: timesheet.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      adminViewModel.updateTimesheet(timesheet.copyWith(startDate: picked));
    }
  }

  void _editEndDate(Timesheet timesheet, AdminViewModel adminViewModel) async {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) {
      return;
    }
    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: timesheet.endDate ?? (timesheet.startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      adminViewModel.updateTimesheet(timesheet.copyWith(endDate: picked));
    }
  }

  void _editTimezone(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    const timezones = [
      'Africa/Abidjan',
      'Africa/Cairo',
      'Africa/Johannesburg',
      'Africa/Lagos',
      'Africa/Nairobi',
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
      'Atlantic/Azores',
      'Atlantic/Cape_Verde',
      'Australia/Adelaide',
      'Australia/Brisbane',
      'Australia/Darwin',
      'Australia/Melbourne',
      'Australia/Perth',
      'Australia/Sydney',
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
      'Pacific/Auckland',
      'Pacific/Fiji',
      'Pacific/Guam',
      'Pacific/Honolulu',
      'Pacific/Midway',
      'UTC',
    ];

    String? selected = timesheet.timezone.isNotEmpty
        ? timesheet.timezone
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            title: Text(
              'Select Timezone',
              style: AppTypography.title().copyWith(fontSize: 18.sp),
            ),
            content: SizedBox(
              width: 320.w,
              child: DropdownButtonFormField<String>(
                value: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  hintText: 'Choose timezone',
                ),
                items: timezones
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
                onChanged: (value) => setDialogState(() => selected = value),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selected != null) {
                    adminViewModel.updateTimesheet(
                      timesheet.copyWith(timezone: selected),
                    );
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _approveTimesheet(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.approved,
    );
    adminViewModel.updateTimesheet(updatedTimesheet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timesheet approved for ${timesheet.staffName}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  void _rejectTimesheet(Timesheet timesheet, AdminViewModel adminViewModel) {
    if (!context.read<AuthViewModel>().hasPrivilege('timesheet', 'update')) return;
    final updatedTimesheet = timesheet.copyWith(
      status: TimesheetStatus.rejected,
    );
    adminViewModel.updateTimesheet(updatedTimesheet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timesheet rejected for ${timesheet.staffName}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}

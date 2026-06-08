import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/app_routes.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';

class EnhancedDutyHistoryScreen extends StatefulWidget {
  const EnhancedDutyHistoryScreen({super.key});

  @override
  State<EnhancedDutyHistoryScreen> createState() => _EnhancedDutyHistoryScreenState();
}

class _EnhancedDutyHistoryScreenState extends State<EnhancedDutyHistoryScreen> {
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    _scrollController.addListener(_onScroll);
    });
  }

  void _loadInitialData() async {
    final viewModel = context.read<WorkerGeofenceViewModel>();
    await viewModel.loadDutyHistory(page: 1, perPage: 20);
  }

  void _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final viewModel = context.read<WorkerGeofenceViewModel>();
      _currentPage++;
      await viewModel.loadDutyHistory(page: _currentPage, perPage: 20);
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerBlue,
        elevation: 0,
        title: Text(
          'Duty History',
          style: AppTypography.title().copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Consumer<WorkerGeofenceViewModel>(
        builder: (context, viewModel, child) {
          debugPrint('Duty History Screen - Loading: ${viewModel.isLoading}, Data count: ${viewModel.dutyHistory.length}');
          
          if (viewModel.isLoading && viewModel.dutyHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.dutyHistory.isEmpty && !viewModel.isLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _currentPage = 1;
              await viewModel.loadDutyHistory(page: 1, perPage: 20);
            },
            child: Column(
              children: [
                _buildStatsHeader(viewModel),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: viewModel.dutyHistory.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == viewModel.dutyHistory.length) {
                        return _buildLoadingIndicator();
                      }
                      
                      final duty = viewModel.dutyHistory[index];
                      return _buildDutyCard(duty);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Duty History',
              style: AppTypography.title().copyWith(
                fontSize: 24.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your completed shifts will appear here',
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.go('/worker'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(WorkerGeofenceViewModel viewModel) {
    final stats = _calculateStats(viewModel.dutyHistory);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerBlue, AppColors.headerBlueLight],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Shifts',
                  value: stats['totalShifts'].toString(),
                  icon: Icons.work_outline,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Hours',
                  value: '${stats['totalHours'].toStringAsFixed(1)}h',
                  icon: Icons.access_time,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Hours/Shift',
                  value: '${stats['avgHoursPerShift'].toStringAsFixed(1)}h',
                  icon: Icons.schedule,
                  color: AppColors.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Check-ins',
                  value: stats['totalCheckins'].toString(),
                  icon: Icons.fact_check,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Photos',
                  value: stats['totalPhotos'].toString(),
                  icon: Icons.photo_camera_back,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Photos/Shift',
                  value: stats['avgPhotosPerShift'].toStringAsFixed(1),
                  icon: Icons.photo_library,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24.sp,
                color: color,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      value,
                      style: AppTypography.title().copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDutyCard(Map<String, dynamic> duty) {
    final date = DateTime.tryParse(duty['date']?.toString() ?? '');
    final startTime = duty['start_time']?.toString() ?? '09:00';
    final endTime = duty['end_time']?.toString() ?? '17:00';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duty['site_name']?.toString() ?? 'Unknown Site',
                        style: AppTypography.title().copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            date != null ? _formatDate(date) : 'No Date',
                            style: AppTypography.body().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '$startTime - $endTime',
                        style: AppTypography.body().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(duty['status']?.toString() ?? ''),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        duty['status']?.toString() ?? 'Unknown',
                        style: AppTypography.body().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${(duty['duration_hours'] as num? ?? 0).toStringAsFixed(1)}h',
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.check_circle_outline,
                    'Check-ins',
                    '${duty['checkins_count'] ?? 0}',
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildInfoRow(
                    Icons.photo_camera_back,
                    'Photos',
                    '${duty['photos_count'] ?? 0}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.body().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTypography.body().copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AppColors.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading more duty history...',
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<Map<String, dynamic>> dutyHistory) {
    if (dutyHistory.isEmpty) {
      return {
        'totalShifts': 0,
        'totalHours': 0.0,
        'avgHoursPerShift': 0.0,
        'totalCheckins': 0,
        'totalPhotos': 0,
        'avgPhotosPerShift': 0.0,
      };
    }

    double totalHours = 0;
    double totalCheckins = 0;
    double totalPhotos = 0;
    
    for (final duty in dutyHistory) {
      final hours = (duty['duration_hours'] as num?)?.toDouble() ?? 0);
      totalHours += hours;
      totalCheckins += (duty['checkins_count'] as int?) ?? 0;
      totalPhotos += (duty['photos_count'] as int?) ?? 0;
    }

    return {
      'totalShifts': dutyHistory.length,
      'totalHours': totalHours.isNegative ? 0 : totalHours,
      'avgHoursPerShift': dutyHistory.isEmpty ? 0 : totalHours / dutyHistory.length,
      'totalCheckins': totalCheckins,
      'totalPhotos': totalPhotos,
      'avgPhotosPerShift': dutyHistory.isEmpty ? 0 : totalPhotos / dutyHistory.length,
    };
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clocked-in':
        return AppColors.success;
      case 'clocked-out':
        return AppColors.primary;
      case 'clocked-out-offsite':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '08:00 AM';
    final h = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

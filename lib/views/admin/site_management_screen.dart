import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/site_models.dart';
import '../../routes/routes.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';

class SiteManagementScreen extends StatefulWidget {
  const SiteManagementScreen({super.key});

  @override
  State<SiteManagementScreen> createState() => _SiteManagementScreenState();
}

class _SiteManagementScreenState extends State<SiteManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadSites();
    });
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('site', action);
  }

  String _siteName(Map<String, dynamic> site) {
    final value = site['name'];
    return value == null || value.toString().trim().isEmpty
        ? 'Unknown Site'
        : value.toString();
  }

  String _siteAddress(Map<String, dynamic> site) {
    final value = site['address'];
    if (value == null || value.toString().trim().isEmpty) {
      return 'No address available';
    }
    String addressStr = value.toString();
    if (addressStr.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(addressStr);
        final parts = <String>[];
        if (decoded['name'] != null && decoded['name'].toString().isNotEmpty) parts.add(decoded['name'].toString());
        if (decoded['city'] != null && decoded['city'].toString().isNotEmpty) parts.add(decoded['city'].toString());
        if (decoded['state'] != null && decoded['state'].toString().isNotEmpty) parts.add(decoded['state'].toString());
        if (decoded['zip'] != null && decoded['zip'].toString().isNotEmpty) parts.add(decoded['zip'].toString());
        if (decoded['country'] != null && decoded['country'].toString().isNotEmpty) parts.add(decoded['country'].toString());
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      } catch (_) {}
    }
    return addressStr;
  }

  int _workersCount(Map<String, dynamic> site) {
    final value = site['workers_count'] ?? site['workersAssigned'] ?? 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String _coordinates(Map<String, dynamic> site) {
    String? lat = site['latitude']?.toString() ?? site['lat']?.toString();
    String? lng = site['longitude']?.toString() ?? site['lng']?.toString() ?? site['lon']?.toString();

    var geofence = site['geofence'];
    if (geofence is String && geofence.trim().startsWith('{')) {
      try {
        geofence = jsonDecode(geofence);
      } catch (_) {}
    }
    
    if (geofence is Map) {
      lat ??= geofence['latitude']?.toString() ?? geofence['lat']?.toString();
      lng ??= geofence['longitude']?.toString() ?? geofence['lng']?.toString() ?? geofence['lon']?.toString();
    }

    final latValue = double.tryParse((lat ?? '').toString());
    final lngValue = double.tryParse((lng ?? '').toString());
    if (latValue != null && lngValue != null) {
      return '${latValue.toStringAsFixed(4)}, ${lngValue.toStringAsFixed(4)}';
    }

    final coordinates = site['coordinates'];
    if (coordinates != null && coordinates.toString().trim().isNotEmpty) {
      return coordinates.toString();
    }

    return '--';
  }

  String _geofenceRadius(Map<String, dynamic> site) {
    var geofence = site['geofence'] ?? site['geofence_radius'];
    
    // Handle JSON string case
    if (geofence is String && geofence.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(geofence);
        final radius = decoded['check_in_distance'] ?? decoded['radius'] ?? decoded['geofence_radius'];
        if (radius != null) return '${radius}m';
      } catch (_) {}
    }

    if (geofence is Map) {
      final radius = geofence['check_in_distance'] ?? geofence['radius'] ?? geofence['geofence_radius'] ?? '--';
      return '$radius${radius.toString() == '--' ? '' : 'm'}';
    }
    
    final radius = site['geofence_radius'] ?? site['radius'] ?? site['geofence'] ?? '--';
    if (radius is String && radius.trim().startsWith('{')) {
       try {
        final Map<String, dynamic> decoded = jsonDecode(radius);
        final innerRadius = decoded['check_in_distance'] ?? decoded['radius'] ?? decoded['geofence_radius'];
        if (innerRadius != null) return '${innerRadius}m';
      } catch (_) {}
    }

    return '$radius${radius.toString() == '--' ? '' : 'm'}';
  }

  int _activeSitesCount(List<Map<String, dynamic>> sites) {
    return sites.where((site) {
      final status = (site['status'] ?? 'active').toString().toLowerCase();
      return status == 'active' || status == '1' || status == 'true';
    }).length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── CSV Export ────────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    final sites = context.read<AdminViewModel>().sites;
    if (sites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sites to export')),
      );
      return;
    }

    final rows = <List<dynamic>>[
      ['name', 'address', 'latitude', 'longitude', 'geofence_radius', 'status', 'description'],
    ];

    for (final site in sites) {
      String address = '';
      final raw = site['address'];
      if (raw != null) {
        final s = raw.toString();
        if (s.trim().startsWith('{')) {
          try {
            final m = jsonDecode(s) as Map;
            address = [m['name'], m['city'], m['state'], m['country']]
                .where((p) => p != null && p.toString().isNotEmpty)
                .join(', ');
          } catch (_) {
            address = s;
          }
        } else {
          address = s;
        }
      }

      double? lat, lng;
      var gf = site['geofence'];
      if (gf is String && gf.trim().startsWith('{')) {
        try { gf = jsonDecode(gf); } catch (_) {}
      }
      if (gf is Map) {
        lat = double.tryParse((gf['lat'] ?? gf['latitude'] ?? '').toString());
        lng = double.tryParse((gf['lng'] ?? gf['longitude'] ?? '').toString());
      }
      lat ??= double.tryParse((site['latitude'] ?? site['lat'] ?? '').toString());
      lng ??= double.tryParse((site['longitude'] ?? site['lng'] ?? '').toString());

      String radius = '';
      if (gf is Map) {
        radius = (gf['check_in_distance'] ?? gf['radius'] ?? '').toString();
      }
      if (radius.isEmpty) {
        radius = (site['geofence_radius'] ?? site['radius'] ?? '').toString();
      }

      rows.add([
        site['name'] ?? '',
        address,
        lat ?? '',
        lng ?? '',
        radius,
        site['status'] ?? 'active',
        site['description'] ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sites_export.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Sites Export',
      ),
    );
  }

  // ─── CSV Import ────────────────────────────────────────────────────────────

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV file is empty or has no data rows')),
          );
        }
        return;
      }

      // Map header row to indices
      final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final nameIdx    = header.indexOf('name');
      final addrIdx    = header.indexOf('address');
      final latIdx     = header.indexOf('latitude');
      final lngIdx     = header.indexOf('longitude');
      final radiusIdx  = header.indexOf('geofence_radius');
      final statusIdx  = header.indexOf('status');
      final descIdx    = header.indexOf('description');

      if (nameIdx == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV must have a "name" column')),
          );
        }
        return;
      }

      final dataRows = rows.skip(1).where((r) {
        final name = nameIdx < r.length ? r[nameIdx].toString().trim() : '';
        return name.isNotEmpty;
      }).toList();

      if (dataRows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid rows found in CSV')),
          );
        }
        return;
      }

      if (!mounted) return;
      final confirmed = await _showImportPreviewDialog(dataRows, header, nameIdx, addrIdx);
      if (confirmed != true) return;

      int success = 0, failed = 0;
      final vm = context.read<AdminViewModel>();

      for (final row in dataRows) {
        String cell(int idx) => idx >= 0 && idx < row.length ? row[idx].toString().trim() : '';
        final lat = double.tryParse(cell(latIdx)) ?? 0.0;
        final lng = double.tryParse(cell(lngIdx)) ?? 0.0;
        final radius = double.tryParse(cell(radiusIdx)) ?? 200.0;

        final siteData = {
          'name': cell(nameIdx),
          'address': cell(addrIdx),
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'status': cell(statusIdx).isNotEmpty ? cell(statusIdx) : 'active',
          'description': cell(descIdx),
          'geofence': jsonEncode({
            'lat': lat,
            'lng': lng,
            'check_in_distance': radius.toInt(),
          }),
        };

        final ok = await vm.createSiteFromMap(siteData);
        ok ? success++ : failed++;
      }

      if (mounted) {
        await vm.loadSites();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import complete: $success created, $failed failed'),
            backgroundColor: failed == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool?> _showImportPreviewDialog(
    List<List<dynamic>> rows,
    List<String> header,
    int nameIdx,
    int addrIdx,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import ${rows.length} Site${rows.length == 1 ? '' : 's'}?'),
        content: SizedBox(
          width: double.maxFinite,
          height: 260.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following sites will be created:',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final name = nameIdx < r.length ? r[nameIdx].toString() : '';
                    final addr = addrIdx >= 0 && addrIdx < r.length ? r[addrIdx].toString() : '';
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14.sp, color: AppColors.primary),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              addr.isNotEmpty ? '$name\n$addr' : name,
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Import ${rows.length} Site${rows.length == 1 ? '' : 's'}'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateSitePopup() async {
    final result = await context.push<bool>(Routes.adminSiteWizard);

    if (result == true && mounted) {
      context.read<AdminViewModel>().loadSites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showEditSitePopup(Map<String, dynamic> site) async {
    final siteDetails = _convertToSiteDetails(site);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final adminViewModel = context.read<AdminViewModel>();
      final siteId = siteDetails.id!;
      
      final contacts = await adminViewModel.getSiteContacts(siteId);
      final checkpoints = await adminViewModel.getSiteCheckpoints(siteId);
      final documents = await adminViewModel.getSiteDocuments(siteId);
      final preferences = await adminViewModel.getSitePreferences(siteId);
      
      if (mounted) Navigator.pop(context);

      final result = await context.push<bool>(
        Routes.adminSiteWizard,
        extra: {
          'site': siteDetails,
          'contacts': contacts.map((e) => SiteContact(
            id: int.tryParse(e['id']?.toString() ?? ''),
            firstName: e['first_name']?.toString() ?? e['firstName']?.toString() ?? '',
            lastName: e['last_name']?.toString() ?? e['lastName']?.toString() ?? '',
            position: e['position']?.toString() ?? '',
            email: e['email']?.toString() ?? '',
            contactNumber: e['contact_number']?.toString() ?? e['contactNumber']?.toString() ?? '',
            notes: e['notes']?.toString(),
            siteId: int.tryParse(e['site_id']?.toString() ?? ''),
          )).toList(),
          'checkpoints': checkpoints.map((e) => SiteCheckpoint(
            id: int.tryParse(e['id']?.toString() ?? ''),
            name: e['name']?.toString() ?? '',
            geofence: Geofence.fromJson(e['geofence'] ?? {}),
            qrCodeToken: e['qr_code_token']?.toString(),
            siteId: int.tryParse(e['site_id']?.toString() ?? ''),
          )).toList(),
          'documents': documents.map((e) => SiteDocument(
            id: int.tryParse(e['id']?.toString() ?? ''),
            name: e['name']?.toString() ?? '',
            files: List<String>.from(e['files'] ?? e['filePaths'] ?? []),
            offsiteVisibility: e['offsite_visibility'] ?? e['isViewableOffsite'] ?? false,
            siteId: int.tryParse(e['site_id']?.toString() ?? ''),
          )).toList(),
          'preferences': preferences.map((e) => SitePreference(
            id: int.tryParse(e['id']?.toString() ?? ''),
            siteId: int.tryParse(e['site_id']?.toString() ?? ''),
            referenceId: int.tryParse(e['reference_id']?.toString() ?? ''),
            mode: e['mode']?.toString(),
            setting: e['setting']?.toString(),
          )).toList(),
        },
      );

      if (result == true && mounted) {
        context.read<AdminViewModel>().loadSites();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load site details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  SiteDetails _convertToSiteDetails(Map<String, dynamic> site) {
    String addressName = site['address']?.toString() ?? '';
    String city = site['city']?.toString() ?? '';
    String state = site['state']?.toString() ?? '';
    String zip = site['zip']?.toString() ?? '';
    String country = site['country']?.toString() ?? '';

    if (addressName.trim().startsWith('{')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(addressName);
        addressName = decoded['name']?.toString() ?? '';
        if (city.isEmpty) city = decoded['city']?.toString() ?? '';
        if (state.isEmpty) state = decoded['state']?.toString() ?? '';
        if (zip.isEmpty) zip = decoded['zip']?.toString() ?? '';
        if (country.isEmpty) country = decoded['country']?.toString() ?? '';
      } catch (_) {}
    }

    return SiteDetails(
      id: site['id']?.toString(),
      type: site['type']?.toString() ?? 'static',
      name: site['name']?.toString() ?? '',
      customerId: site['customer_profile_id']?.toString() ?? site['customer_id']?.toString(),
      address: SiteAddress(
        name: addressName,
        city: city,
        state: state,
        zip: zip,
        country: country,
      ),
      geofence: Geofence.fromJson(site['geofence'] ?? {}),
      defaultServiceGroupId: site['default_service_group_id']?.toString() ?? site['service_group_id']?.toString(),
      defaultPayGroupId: site['default_pay_group_id']?.toString() ?? site['pay_group_id']?.toString(),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> site) async {
    final siteId = site['id'];
    if (siteId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete ${_siteName(site)}?'),
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
      final success = await context.read<AdminViewModel>().deleteSite(
            siteId.toString(),
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allSites = viewModel.sites;
        final activeSites = _activeSitesCount(allSites);
        final query = _searchController.text.trim().toLowerCase();
        final sites = query.isEmpty
            ? allSites
            : allSites.where((site) {
                return _siteName(site).toLowerCase().contains(query) ||
                    _siteAddress(site).toLowerCase().contains(query);
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
                                  'Site Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '$activeSites active sites',
                                  style: AppTypography.label().copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // CSV import / export
                          IconButton(
                            onPressed: _importCsv,
                            tooltip: 'Import CSV',
                            icon: Icon(Icons.upload_file, color: Colors.white, size: 22.sp),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            onPressed: _exportCsv,
                            tooltip: 'Export CSV',
                            icon: Icon(Icons.download, color: Colors.white, size: 22.sp),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                          children: [
                            Icon(
                              Icons.search,
                              size: 22.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: AppTypography.body().copyWith(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search sites...',
                                  hintStyle: AppTypography.body().copyWith(
                                    fontSize: 15.sp,
                                    color: Colors.white.withValues(alpha: 0.75),
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
                  child: viewModel.isLoading && allSites.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadSites(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              24.h,
                            ),
                            children: [
                              if (_hasPrivilege('create'))
                              SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: ElevatedButton.icon(
                                  onPressed: _showCreateSitePopup,
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
                                    'Create New Site',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasPrivilege('create')) SizedBox(height: 14.h),
                              if (sites.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No sites found',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...sites.map(
                                  (site) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Container(
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _siteName(site),
                                            style:
                                                AppTypography.body().copyWith(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(
                                                0xFF1F2937,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            _siteAddress(site),
                                            style:
                                                AppTypography.body().copyWith(
                                              fontSize: 12.sp,
                                              color: const Color(
                                                0xFF6B7280,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            '${_workersCount(site)} workers assigned',
                                            style:
                                                AppTypography.body().copyWith(
                                              fontSize: 12.sp,
                                              color: const Color(
                                                0xFF4B5563,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 12.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _SiteInfoBox(
                                                  title: 'Coordinates',
                                                  value: _coordinates(site),
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: _SiteInfoBox(
                                                  title: 'Geofence Radius',
                                                  value: _geofenceRadius(site),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12.h),
                                          if (_hasPrivilege('update') || _hasPrivilege('delete'))
                                          Row(
                                            children: [
                                              if (_hasPrivilege('update'))
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _showEditSitePopup(site),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFD1D5DB),
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                    ),
                                                    minimumSize:
                                                        Size.fromHeight(38.h),
                                                  ),
                                                  child: Text(
                                                    'Edit',
                                                    style: AppTypography.body()
                                                        .copyWith(
                                                      color: const Color(
                                                        0xFF111827,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (_hasPrivilege('update') && _hasPrivilege('delete')) SizedBox(width: 10.w),
                                              if (_hasPrivilege('delete'))
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _confirmDelete(site),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFF7CDD1),
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                    ),
                                                    minimumSize:
                                                        Size.fromHeight(38.h),
                                                  ),
                                                  child: Text(
                                                    'Delete',
                                                    style: AppTypography.body()
                                                        .copyWith(
                                                      color: const Color(
                                                        0xFFEF4444,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13.sp,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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

class _SiteInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _SiteInfoBox({required this.title, required this.value});

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
            title,
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

class _SiteFormSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? site;

  const _SiteFormSheet({required this.isEdit, required this.site});

  @override
  State<_SiteFormSheet> createState() => _SiteFormSheetState();
}

class _SiteFormSheetState extends State<_SiteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _siteNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _geofenceController;

  @override
  void initState() {
    super.initState();
    final site = widget.site;

    _siteNameController = TextEditingController(
      text: (site?['name'] ?? '').toString(),
    );
    _addressController = TextEditingController(
      text: (site?['address'] ?? '').toString(),
    );

    final lat = site?['latitude'] ?? site?['lat'] ?? 0;
    final lng = site?['longitude'] ?? site?['lng'] ?? site?['lon'] ?? 0;
    final geofence = site?['geofence_radius'] ?? site?['radius'] ?? 100;

    _latitudeController = TextEditingController(text: lat.toString());
    _longitudeController = TextEditingController(text: lng.toString());
    _geofenceController = TextEditingController(text: geofence.toString());
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _geofenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AdminViewModel>();
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
    final geofenceText = _geofenceController.text.trim();

    final description = 'lat:$latText,lng:$lngText,geofence:$geofenceText';

    bool success;
    if (widget.isEdit) {
      final siteId = widget.site?['id'];
      if (siteId == null) return;

      final payload = {
        'id': siteId.toString(),
        'name': _siteNameController.text.trim(),
        'address': _addressController.text.trim(),
        'status': ((widget.site?['status'] ?? 'active').toString()),
        'description': description,
        'latitude': latText,
        'longitude': lngText,
        'geofence_radius': geofenceText,
      };
      success = await viewModel.updateSite(payload);
    } else {
      success = await viewModel.createSite(
        name: _siteNameController.text.trim(),
        address: _addressController.text.trim(),
        status: 'active',
        description: description,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.errorMessage ??
              (widget.isEdit
                  ? 'Failed to update site'
                  : 'Failed to create site'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.body().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
                  widget.isEdit ? 'Edit Site' : 'Add Site',
                  style: AppTypography.title().copyWith(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.w,
                8.h,
                16.w,
                16.h + bottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Site Details'),
                    SizedBox(height: 12.h),
                    UltimateMobileTextField(
                      controller: _siteNameController,
                      decoration: _inputDecoration('Site Name *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter site name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _addressController,
                      decoration: _inputDecoration('Address *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _sectionTitle('Location'),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('Latitude *'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('Longitude *'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _geofenceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Geofence Radius (meters) *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        if (double.tryParse(value.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E45BA),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.isEdit ? 'Update Site' : 'Create Site',
                                style: AppTypography.body().copyWith(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_constants.dart';
import '../constants/typography.dart';

class MapPickerWidget extends StatefulWidget {
  final LatLng initialLocation;
  const MapPickerWidget({super.key, required this.initialLocation});

  static Future<LatLng?> show(BuildContext context, {LatLng? initialLocation}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapPickerWidget(
          initialLocation: initialLocation ?? const LatLng(51.509364, -0.128928),
        ),
      ),
    );
  }

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late LatLng _currentPosition;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialLocation;
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: AppTypography.title().copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_currentPosition);
            },
            child: Text(
              'Confirm',
              style: AppTypography.button().copyWith(
                color: AppColors.primary,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition,
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            setState(() {
              _currentPosition = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.security_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentPosition,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

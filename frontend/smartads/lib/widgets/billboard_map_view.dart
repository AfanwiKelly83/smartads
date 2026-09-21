import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/billboard_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BillboardMapView extends StatefulWidget {
  final List<BillboardModel> billboards;
  final Function(BillboardModel) onBookBillboard;
  final BillboardModel? initialSelectedBillboard;
  final bool compact;

  const BillboardMapView({
    super.key,
    required this.billboards,
    required this.onBookBillboard,
    this.initialSelectedBillboard,
    this.compact = false,
  });

  @override
  State<BillboardMapView> createState() => _BillboardMapViewState();
}

class _BillboardMapViewState extends State<BillboardMapView> {
  final MapController _mapController = MapController();
  BillboardModel? _selectedBillboard;
  String _mapStyle = 'google_streets'; // 'google_streets', 'google_satellite', 'dark', 'street'
  String? _googleMapsApiKey;

  // Default center: Cameroon (approx lat: 4.15, lng: 9.7)
  static const LatLng _defaultCenter = LatLng(4.15, 9.7);
  static const double _defaultZoom = 7.5;

  @override
  void initState() {
    super.initState();
    _selectedBillboard = widget.initialSelectedBillboard;
    _fetchMapsKey();
    if (_selectedBillboard != null && _selectedBillboard!.hasCoordinates) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(_selectedBillboard!.lat!, _selectedBillboard!.lng!),
          13.5,
        );
      });
    }
  }

  Future<void> _fetchMapsKey() async {
    final key = await ApiService().getGoogleMapsApiKey();
    if (mounted && key != null && key.isNotEmpty) {
      setState(() => _googleMapsApiKey = key);
    }
  }

  @override
  void didUpdateWidget(covariant BillboardMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedBillboard != null &&
        widget.initialSelectedBillboard != oldWidget.initialSelectedBillboard &&
        widget.initialSelectedBillboard!.hasCoordinates) {
      setState(() => _selectedBillboard = widget.initialSelectedBillboard);
      _mapController.move(
        LatLng(
          widget.initialSelectedBillboard!.lat!,
          widget.initialSelectedBillboard!.lng!,
        ),
        13.5,
      );
    }
  }

  void _openInGoogleMaps(BillboardModel billboard) async {
    final uri = Uri.parse(billboard.googleMapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.surfaceDark,
            content: Text('Could not open Google Maps: $e'),
          ),
        );
      }
    }
  }

  void _flyToCity(String cityName, LatLng coords, double zoom) {
    _mapController.move(coords, zoom);
  }

  void _recenterAll() {
    final withCoords = widget.billboards.where((b) => b.hasCoordinates).toList();
    if (withCoords.isNotEmpty) {
      final first = withCoords.first;
      _mapController.move(LatLng(first.lat!, first.lng!), _defaultZoom);
    } else {
      _mapController.move(_defaultCenter, _defaultZoom);
    }
    setState(() => _selectedBillboard = null);
  }

  String _getTileUrl() {
    switch (_mapStyle) {
      case 'google_streets':
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}${_googleMapsApiKey != null ? '&key=$_googleMapsApiKey' : ''}';
      case 'google_satellite':
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}${_googleMapsApiKey != null ? '&key=$_googleMapsApiKey' : ''}';
      case 'street':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'dark':
      default:
        return 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final validBillboards =
        widget.billboards.where((b) => b.hasCoordinates).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // FlutterMap Core
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedBillboard?.hasCoordinates == true
                  ? LatLng(_selectedBillboard!.lat!, _selectedBillboard!.lng!)
                  : _defaultCenter,
              initialZoom: _selectedBillboard?.hasCoordinates == true ? 13.0 : _defaultZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                setState(() => _selectedBillboard = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.smartads.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: validBillboards.map((b) {
                  final isSelected = _selectedBillboard?.billboardId == b.billboardId;
                  final isAvailable = b.availabilityStatus == 'AVAILABLE';

                  return Marker(
                    point: LatLng(b.lat!, b.lng!),
                    width: isSelected ? 120 : 90,
                    height: isSelected ? 90 : 70,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedBillboard = b);
                        _mapController.move(LatLng(b.lat!, b.lng!), 14.0);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price Tag Bubble
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentPrimary
                                  : AppTheme.surfaceDark.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : (isAvailable
                                        ? const Color(0xFF10B981)
                                        : Colors.amber),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSelected
                                          ? AppTheme.accentPrimary
                                          : Colors.black)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${b.hourlyRate.toStringAsFixed(0)} F',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSelected ? 11 : 9,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Pin Icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 38 : 28,
                            height: isSelected ? 38 : 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.accentLight
                                  : (isAvailable
                                      ? const Color(0xFF10B981)
                                      : Colors.amber),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAvailable
                                          ? const Color(0xFF10B981)
                                          : Colors.amber)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 12,
                                  spreadRadius: isSelected ? 3 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.tv_rounded,
                              color: Colors.black,
                              size: isSelected ? 20 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Overlay: Quick City Filter Chips
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCityChip(
                    'All Displays (${validBillboards.length})',
                    const LatLng(4.15, 9.7),
                    7.0,
                    Icons.map_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    'Douala',
                    const LatLng(4.0511, 9.7679),
                    12.5,
                    Icons.location_city_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    'Yaoundé',
                    const LatLng(3.8830, 11.5120),
                    12.5,
                    Icons.location_city_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    'Buea',
                    const LatLng(4.1560, 9.2435),
                    13.0,
                    Icons.school_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    'Limbe',
                    const LatLng(4.0167, 9.2167),
                    13.0,
                    Icons.beach_access_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    'Bafoussam',
                    const LatLng(5.4777, 10.4176),
                    13.0,
                    Icons.store_rounded,
                  ),
                ],
              ),
            ),
          ),

          // Map Controls (Right Side)
          Positioned(
            top: 60,
            right: 12,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter Map',
                  onTap: _recenterAll,
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: _mapStyle == 'google_streets'
                      ? Icons.map_rounded
                      : _mapStyle == 'google_satellite'
                          ? Icons.satellite_alt_rounded
                          : _mapStyle == 'dark'
                              ? Icons.dark_mode_rounded
                              : Icons.wb_sunny_rounded,
                  tooltip: 'Map Layer: ${_mapStyle.replaceAll('_', ' ').toUpperCase()}',
                  onTap: () {
                    setState(() {
                      if (_mapStyle == 'google_streets') {
                        _mapStyle = 'google_satellite';
                      } else if (_mapStyle == 'google_satellite') {
                        _mapStyle = 'dark';
                      } else if (_mapStyle == 'dark') {
                        _mapStyle = 'street';
                      } else {
                        _mapStyle = 'google_streets';
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Bottom Popup Card for Selected Billboard
          if (_selectedBillboard != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _buildSelectedBillboardCard(_selectedBillboard!),
            ),
        ],
      ),
    );
  }

  Widget _buildCityChip(
    String label,
    LatLng coords,
    double zoom,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _flyToCity(label, coords, zoom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.accentLight, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderSubtle.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.accentLight, size: 18),
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSelectedBillboardCard(BillboardModel b) {
    final isAvailable = b.availabilityStatus == 'AVAILABLE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Status, Close
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tv_rounded,
                  color: AppTheme.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.billboardName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      b.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFF10B981)
                        : Colors.amber,
                  ),
                ),
                child: Text(
                  isAvailable ? 'AVAILABLE' : 'ACTIVE',
                  style: TextStyle(
                    color: isAvailable
                        ? const Color(0xFF10B981)
                        : Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                onPressed: () => setState(() => _selectedBillboard = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Specs & Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.aspect_ratio_rounded,
                    color: AppTheme.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    b.screenSize,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '${b.hourlyRate.toStringAsFixed(0)} FCFA / hr',
                style: const TextStyle(
                  color: AppTheme.accentLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.borderSubtle, height: 18),

          // Action Buttons: Google Maps & Book Now
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openInGoogleMaps(b),
                  icon: const Icon(
                    Icons.directions_rounded,
                    color: AppTheme.accentLight,
                    size: 16,
                  ),
                  label: const Text(
                    'GOOGLE MAPS',
                    style: TextStyle(
                      color: AppTheme.accentLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.accentPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onBookBillboard(b),
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'BOOK THIS SCREEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
}

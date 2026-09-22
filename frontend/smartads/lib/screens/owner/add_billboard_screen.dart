import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../models/billboard_model.dart';
import '../../services/billboard_service.dart';
import '../../config/api_config.dart';
import '../../widgets/role_guard.dart';

class AddBillboardScreen extends StatefulWidget {
  const AddBillboardScreen({super.key});

  @override
  State<AddBillboardScreen> createState() => _AddBillboardScreenState();
}

class _AddBillboardScreenState extends State<AddBillboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController(text: '15000');
  final _maxCampaignsController = TextEditingController(text: '10');
  final _sizeController = TextEditingController(text: 'Smart TV HD (1920x1080)');
  final _widthController = TextEditingController(text: '1920');
  final _heightController = TextEditingController(text: '1080');
  final _resolutionController = TextEditingController(text: '1920x1080');
  final _operatingHoursController = TextEditingController(text: '06:00 - 22:00');
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _technicalSpecsController = TextEditingController();
  final _latController = TextEditingController(text: '4.0511');
  final _lngController = TextEditingController(text: '9.7679');
  String _billboardType = 'SMART_TV';

  bool _isSubmitting = false;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _maxCampaignsController.dispose();
    _sizeController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _resolutionController.dispose();
    _operatingHoursController.dispose();
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    _technicalSpecsController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final rate = double.tryParse(_rateController.text.trim()) ?? 15000.0;
        final maxCampaigns = int.tryParse(_maxCampaignsController.text.trim()) ?? 10;
        final billboard = await BillboardService().createBillboard(
          billboardName: _nameController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : _locationController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Digital advertising display available for scheduled campaigns.',
          billboardType: _billboardType,
          width: _widthController.text.trim(),
          height: _heightController.text.trim(),
          resolution: _resolutionController.text.trim(),
          pricePerHour: rate,
          maxActiveCampaigns: maxCampaigns,
          operatingHours: _operatingHoursController.text.trim(),
          images: _imageUrlController.text.trim().isNotEmpty
              ? _imageUrlController.text.trim()
              : null,
          videoDemo: _videoUrlController.text.trim().isNotEmpty
              ? _videoUrlController.text.trim()
              : null,
          technicalSpecs: _technicalSpecsController.text.trim().isNotEmpty
              ? _technicalSpecsController.text.trim()
              : null,
          screenSize: _sizeController.text.trim().isNotEmpty
              ? _sizeController.text.trim()
              : 'Smart TV HD (1920x1080)',
          latitude: _latController.text.trim(),
          longitude: _lngController.text.trim(),
        );

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessAndQR(billboard);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade900,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadQrCode(BillboardModel billboard) async {
    try {
      final qrPath = billboard.qrCodeUrl;
      if (qrPath == null || qrPath.isEmpty) {
        throw Exception('The server did not return a QR code.');
      }
      final response = await http.get(
        Uri.parse(ApiConfig.resolveAssetUrl(qrPath)),
      );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('The generated QR code could not be downloaded.');
      }

      await FileSaver.instance.saveFile(
        name: 'smartads_${billboard.billboardCode.isNotEmpty ? billboard.billboardCode : billboard.billboardId}',
        bytes: response.bodyBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceDark,
          content: Text('Billboard QR Code PNG saved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('Could not save QR Code: $error'),
        ),
      );
    }
  }

  Widget _buildPresetChip(
    String label,
    String defaultName,
    String defaultLocation,
    String lat,
    String lng,
  ) {
    return ActionChip(
      backgroundColor: AppColors.inputBg,
      side: BorderSide(
        color: AppColors.borderSubtle.withValues(alpha: 0.4),
      ),
      avatar: const Icon(
        Icons.tv_rounded,
        size: 14,
        color: AppColors.accentLight,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      onPressed: () {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = defaultName;
          }
          _locationController.text = defaultLocation;
          _addressController.text = defaultLocation;
          _latController.text = lat;
          _lngController.text = lng;
        });
      },
    );
  }

  void _showSuccessAndQR(BillboardModel billboard) {
    final code = billboard.billboardCode.isNotEmpty
        ? billboard.billboardCode
        : 'BILL-${billboard.billboardId}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Billboard Registered!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${billboard.billboardName} ($code) is successfully registered. Status: ${billboard.approvalStatus}. Download and print this QR code to place on your display.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              // Printable Poster Card for the Smart TV / Billboard
              Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SMARTADS • DIGITAL BILLBOARD',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      billboard.billboardName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.black54, size: 12),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            billboard.location,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Image.network(
                      billboard.qrCodeUrl == null
                          ? ''
                          : ApiConfig.resolveAssetUrl(billboard.qrCodeUrl!),
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.qr_code_rounded,
                        color: Colors.black54,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SCAN WITH SMARTADS APP TO BOOK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billboard ID: $code',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _downloadQrCode(billboard),
            icon: const Icon(
              Icons.download_for_offline_rounded,
              color: AppColors.accentLight,
            ),
            label: const Text(
              'DOWNLOAD & PRINT QR',
              style: TextStyle(
                color: AppColors.accentLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
            ),
            child: const Text(
              'DONE & RETURN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: RoleAccess.adminAndOwner,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          title: const Text(
            'Register Billboard Display',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tv_rounded,
                            color: AppColors.accentLight,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADD DIGITAL BILLBOARD / TV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Enter display details. Unique ID (BILL-xxx) & QR will generate automatically.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick TV Location Presets
                    const Text(
                      'QUICK LOCATION PRESETS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip(
                            'Akwa Boulevard TV',
                            'Smart TV #01 - Akwa LED Screen',
                            'Akwa Boulevard, Douala',
                            '4.0511',
                            '9.7679',
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            'Bastos Junction TV',
                            'Smart TV #02 - Bastos Display',
                            'Bastos Junction, Yaoundé',
                            '3.8830',
                            '11.5120',
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            'Buea Campus TV',
                            'Smart TV #03 - University Hall Screen',
                            'Main University Road, Buea',
                            '4.1560',
                            '9.2435',
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            'Living Room / Lab TV',
                            'Smart TV Prototype #01',
                            'SmartAds IoT Hardware Lab',
                            '4.0511',
                            '9.7679',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Billboard Type Selector
                    const Text(
                      'BILLBOARD TYPE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('SMART TV'),
                          selected: _billboardType == 'SMART_TV',
                          selectedColor: AppColors.accentPrimary,
                          onSelected: (v) => setState(() => _billboardType = 'SMART_TV'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('LED WALL'),
                          selected: _billboardType == 'LED_DISPLAY',
                          selectedColor: AppColors.accentPrimary,
                          onSelected: (v) => setState(() => _billboardType = 'LED_DISPLAY'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('DIGITAL POSTER'),
                          selected: _billboardType == 'DIGITAL_POSTER',
                          selectedColor: AppColors.accentPrimary,
                          onSelected: (v) => setState(() => _billboardType = 'DIGITAL_POSTER'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 1. Billboard / TV Name & ID
                    TextFormField(
                      controller: _nameController,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Billboard Name / ID'),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Billboard Name / Identifier *',
                        hintText: 'e.g. Smart TV #01 - Living Room Prototype',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.tv_rounded, color: AppColors.accentLight),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Physical Location
                    TextFormField(
                      controller: _locationController,
                      validator: (v) =>
                          Validators.validateRequired(v, 'City / Physical Location'),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'City / Region *',
                        hintText: 'e.g. Douala, Cameroon / Bastos, Yaoundé',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.accentLight),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Street Address
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Detailed Street Address',
                        hintText: 'e.g. 142 Boulevard de la Liberté, Akwa',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.pin_drop_rounded, color: AppColors.accentLight),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Rate & Capacity Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            validator: (v) => Validators.validateRequired(v, 'Hourly Rate'),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Hourly Rate (FCFA) *',
                              hintText: '15000',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.monetization_on_rounded, color: AppColors.accentLight),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _maxCampaignsController,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final num = int.tryParse(v?.trim() ?? '');
                              if (num == null || num < 1) {
                                return 'Enter capacity >= 1';
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Max Active Campaigns *',
                              hintText: '10',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.layers_rounded, color: AppColors.accentLight),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Optional Advanced Settings Expansion Tile
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          _showAdvanced ? 'Hide Technical & GPS Specs' : 'Show Technical Specs (Resolution, Hours, Demos & GPS)',
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          _showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: AppColors.accentLight,
                          size: 20,
                        ),
                        onExpansionChanged: (val) => setState(() => _showAdvanced = val),
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _resolutionController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Resolution',
                                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    filled: true,
                                    fillColor: AppColors.inputBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _operatingHoursController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Operating Hours',
                                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    filled: true,
                                    fillColor: AppColors.inputBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Latitude (GPS)',
                                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    filled: true,
                                    fillColor: AppColors.inputBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _lngController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Longitude (GPS)',
                                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    filled: true,
                                    fillColor: AppColors.inputBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Description & Advertising Info',
                              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'REGISTERING BILLBOARD & GENERATING QR...'
                              : 'REGISTER BILLBOARD & GENERATE QR CODE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

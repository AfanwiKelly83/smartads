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
  final _rateController = TextEditingController(text: '15000');
  final _sizeController = TextEditingController(text: '4K UHD (3840x2160)');
  final _latController = TextEditingController(text: '4.0511');
  final _lngController = TextEditingController(text: '9.7679');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _rateController.dispose();
    _sizeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final rate = double.tryParse(_rateController.text.trim()) ?? 15000.0;
        final billboard = await BillboardService().createBillboard(
          billboardName: _nameController.text.trim(),
          location: _locationController.text.trim(),
          pricePerHour: rate,
          screenSize: _sizeController.text.trim(),
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
        name: 'smartads_billboard_${billboard.billboardId}',
        bytes: response.bodyBytes,
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceDark,
          content: Text('QR Code PNG saved successfully.'),
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

  void _showSuccessAndQR(BillboardModel billboard) {
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
              'Billboard & QR Code Created!',
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
                '${billboard.billboardName} has been registered! System generated the physical location QR Code. Download and print this label to paste onto the digital billboard structure.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),

              // Printable Poster Card Layout
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
                        'SMARTADS PHYSICAL DISPLAY',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 10,
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
                    Text(
                      billboard.location,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
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
                        Icons.broken_image_outlined,
                        color: Colors.black54,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SCAN TO ADVERTISE ON THIS SCREEN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Billboard ID #BLB-${billboard.billboardId.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 9,
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
      allowedRoles: RoleAccess.admin,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          title: const Text(
            'Register New Billboard',
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
              constraints: const BoxConstraints(maxWidth: 650),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BILLBOARD REGISTRATION & LOCATION DETIALS',
                      style: TextStyle(
                        color: AppColors.accentPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Billboard Name
                    TextFormField(
                      controller: _nameController,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Billboard Name'),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Billboard Name *',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.tv_rounded,
                          color: AppColors.accentLight,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      validator: (v) =>
                          Validators.validateRequired(v, 'Location Address'),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Location / City Address *',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.accentLight,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rateController,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Hourly Rate'),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Rate (FCFA / hr) *',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.payments_rounded,
                                color: AppColors.accentLight,
                              ),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Screen Resolution',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.aspect_ratio_rounded,
                                color: AppColors.accentLight,
                              ),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Latitude (GPS)',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Longitude (GPS)',
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

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
                              ? 'GENERATING QR & REGISTERING...'
                              : 'REGISTER BILLBOARD & GENERATE QR CODE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

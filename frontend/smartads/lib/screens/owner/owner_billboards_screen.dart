import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../utils/app_colors.dart';
import '../../models/billboard_model.dart';
import '../../services/billboard_service.dart';
import '../../config/api_config.dart';
import 'add_billboard_screen.dart';

class OwnerBillboardsScreen extends StatefulWidget {
  final VoidCallback? onAddBillboard;

  const OwnerBillboardsScreen({super.key, this.onAddBillboard});

  @override
  State<OwnerBillboardsScreen> createState() => _OwnerBillboardsScreenState();
}

class _OwnerBillboardsScreenState extends State<OwnerBillboardsScreen> {
  List<BillboardModel> _billboards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBillboards();
  }

  Future<void> _loadBillboards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await BillboardService().getMyBillboards();
      if (mounted) {
        setState(() {
          _billboards = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showQrDialog(BillboardModel billboard) {
    final qrData = billboard.billboardCode.isNotEmpty
        ? 'https://smartads.cm/billboard/${billboard.billboardCode}'
        : 'https://smartads.cm/billboard/${billboard.billboardId}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppColors.accentLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'QR Code: ${billboard.billboardCode.isNotEmpty ? billboard.billboardCode : billboard.billboardName}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Public Billboard ID: ${billboard.billboardCode.isNotEmpty ? billboard.billboardCode : 'BILL-${billboard.billboardId}'}',
              style: const TextStyle(
                color: AppColors.accentLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              billboard.location,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              try {
                if (billboard.qrCodeUrl != null && billboard.qrCodeUrl!.isNotEmpty) {
                  final res = await http.get(Uri.parse(ApiConfig.resolveAssetUrl(billboard.qrCodeUrl!)));
                  if (res.statusCode == 200) {
                    await FileSaver.instance.saveFile(
                      name: 'qr_${billboard.billboardCode.isNotEmpty ? billboard.billboardCode : billboard.billboardId}',
                      bytes: res.bodyBytes,
                      fileExtension: 'png',
                      mimeType: MimeType.png,
                    );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('QR Code saved successfully!')),
                      );
                    }
                  }
                }
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('QR code saved locally.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.accentLight),
            label: const Text('Download PNG', style: TextStyle(color: AppColors.accentLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status) {
      case 'APPROVED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        label = 'APPROVED & ACTIVE';
        break;
      case 'PENDING_APPROVAL':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        label = 'PENDING ADMIN APPROVAL';
        break;
      case 'REJECTED':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        label = 'REJECTED BY ADMIN';
        break;
      case 'SUSPENDED':
      case 'UNPUBLISHED':
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        label = status;
        break;
      default:
        bg = AppTheme.accentPrimary.withValues(alpha: 0.15);
        fg = AppTheme.accentLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MY BILLBOARD INVENTORY',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage Displays & QR Codes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onAddBillboard != null) {
                      widget.onAddBillboard!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBillboardScreen()),
                      ).then((_) => _loadBillboards());
                    }
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'ADD BILLBOARD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.accentPrimary),
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text('Error: $_error', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadBillboards, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_billboards.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.tv_off_rounded, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text(
                      'No Billboards Registered Yet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register your digital screens or Smart TVs to start receiving bookings.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddBillboardScreen()),
                        ).then((_) => _loadBillboards());
                      },
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text('REGISTER FIRST BILLBOARD', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPrimary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _billboards.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final b = _billboards[i];
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: b.isApproved
                            ? AppTheme.accentPrimary.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Icon(Icons.tv_rounded, color: AppTheme.accentLight, size: 28),
                        ),
                        const SizedBox(width: 18),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    b.billboardName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b.billboardCode.isNotEmpty ? b.billboardCode : 'ID #${b.billboardId}',
                                      style: const TextStyle(
                                        color: AppTheme.accentLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    b.location,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  _buildSpecChip('Rate: ${b.hourlyRate.toStringAsFixed(0)} FCFA/hr'),
                                  _buildSpecChip('Type: ${b.billboardType}'),
                                  _buildSpecChip('Res: ${b.resolution}'),
                                  _buildSpecChip('Hours: ${b.operatingHours}'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildApprovalBadge(b.approvalStatus),
                            ],
                          ),
                        ),

                        // Actions
                        Column(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showQrDialog(b),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.accentLight),
                              label: const Text('QR Code', style: TextStyle(color: AppColors.accentLight, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.borderSubtle),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}

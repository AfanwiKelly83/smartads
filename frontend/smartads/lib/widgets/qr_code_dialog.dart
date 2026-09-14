import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/billboard_model.dart';
import '../services/auth_service.dart';

class QrCodeDialog extends StatefulWidget {
  final BillboardModel billboard;
  final bool readOnly;

  const QrCodeDialog({
    super.key,
    required this.billboard,
    this.readOnly = false,
  });

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  bool _isDownloading = false;

  Future<void> _downloadQrCode(String data) async {
    setState(() => _isDownloading = true);

    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
      );
      final imageData = await painter.toImageData(
        1200,
        format: ui.ImageByteFormat.png,
      );

      if (imageData == null) {
        throw Exception('QR image could not be generated');
      }

      await FileSaver.instance.saveFile(
        name: 'smartads_billboard_${widget.billboard.billboardId}',
        bytes: imageData.buffer.asUint8List(),
        fileExtension: 'png',
        mimeType: MimeType.png,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.cardDark,
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
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billboard = widget.billboard;
    final qrTargetUrl =
        'https://smartads.com/billboards/${billboard.billboardId}';
    final canDownload =
        !widget.readOnly && AuthService().currentUser?.isAdmin == true;

    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: AppTheme.accentLight,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Billboard QR Code',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Billboard title
            Text(
              billboard.billboardName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              billboard.location,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Container with sleek gold border frame
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrTargetUrl,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: BLB-${billboard.billboardId.toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan target URL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    color: AppTheme.accentPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qrTargetUrl,
                      style: const TextStyle(
                        color: AppTheme.accentLight,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Management actions are hidden for read-only viewers.
            if (canDownload)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading
                            ? null
                            : () => _downloadQrCode(qrTargetUrl),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.black,
                              ),
                        label: const Text(
                          'DOWNLOAD QR CODE',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.cardDark,
                              content: Row(
                                children: const [
                                  Icon(
                                    Icons.waving_hand_rounded,
                                    color: AppTheme.accentLight,
                                  ),
                                  SizedBox(width: 12),
                                  Text('Welcome to SmartAds!'),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppTheme.accentLight,
                        ),
                        label: const Text(
                          'SCAN & OPEN',
                          style: TextStyle(
                            color: AppTheme.accentLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.borderSubtle.withValues(alpha: 0.25),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

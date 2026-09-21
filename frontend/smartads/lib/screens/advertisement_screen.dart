import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/advertisement_model.dart';
import '../services/advertisement_service.dart';
import '../widgets/role_guard.dart';

class AdvertisementScreen extends StatefulWidget {
  const AdvertisementScreen({super.key});

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  List<AdvertisementModel> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  Future<void> _loadAdvertisements() async {
    setState(() => _isLoading = true);
    final data = await AdvertisementService().getAllAdvertisements();
    if (mounted) {
      setState(() {
        _ads = data;
        _isLoading = false;
      });
    }
  }

  void _showUploadDialog() {
    final titleController = TextEditingController();
    String mediaType = 'IMAGE';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.accentPrimary),
          ),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: AppTheme.accentLight),
              SizedBox(width: 10),
              Text(
                'Upload Ad & AI Scan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload advertising image/video file. SMARTADS Gemini AI will automatically perform content safety verification.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ADVERTISEMENT TITLE *',
                  hintText: 'e.g. Summer Promo 2026',
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'MEDIA TYPE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('IMAGE (.PNG / .JPG)'),
                    selected: mediaType == 'IMAGE',
                    onSelected: (val) =>
                        setModalState(() => mediaType = 'IMAGE'),
                    selectedColor: AppTheme.accentPrimary,
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('VIDEO (.MP4 / .MOV)'),
                    selected: mediaType == 'VIDEO',
                    onSelected: (val) =>
                        setModalState(() => mediaType = 'VIDEO'),
                    selectedColor: AppTheme.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // File preview box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderSubtle.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mediaType == 'VIDEO'
                          ? Icons.movie_rounded
                          : Icons.image_rounded,
                      color: AppTheme.accentLight,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'selected_ad_file.${mediaType == 'VIDEO' ? 'mp4' : 'png'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'Size: 4.2 MB | Resolution: 1080p',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleController.text.trim().isNotEmpty) {
                        setModalState(() => isUploading = true);
                        await AdvertisementService().uploadAdvertisement(
                          title: titleController.text.trim(),
                          mediaType: mediaType,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _loadAdvertisements();
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.white,
              ),
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'UPLOAD & RUN AI SCAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color border;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = const Color(0xFF065F46);
        border = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        bg = Colors.red.shade900;
        border = Colors.red;
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = Colors.amber.shade900;
        border = Colors.amber;
        icon = Icons.access_time_filled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: RoleAccess.advertiser,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: RefreshIndicator(
          onRefresh: _loadAdvertisements,
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Advertisement Library & AI Verification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload ad media files and monitor automated Gemini AI safety verification results.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showUploadDialog,
                      icon: const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'UPLOAD NEW AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  )
                else if (_ads.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.perm_media_rounded,
                          size: 60,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Advertisements Uploaded Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ads.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.5,
                        ),
                    itemBuilder: (context, index) {
                      final ad = _ads[index];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ad.mediaType,
                                    style: const TextStyle(
                                      color: AppTheme.accentLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                _buildStatusBadge(ad.verificationStatus),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              ad.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppTheme.accentLight,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Confidence: ${(ad.aiConfidence * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
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
        ),
      ),
    );
  }
}


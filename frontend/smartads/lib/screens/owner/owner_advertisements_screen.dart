import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/advertisement_model.dart';
import '../../services/advertisement_service.dart';
import '../../widgets/role_guard.dart';

class OwnerAdvertisementsScreen extends StatefulWidget {
  const OwnerAdvertisementsScreen({super.key});

  @override
  State<OwnerAdvertisementsScreen> createState() => _OwnerAdvertisementsScreenState();
}

class _OwnerAdvertisementsScreenState extends State<OwnerAdvertisementsScreen> {
  List<AdvertisementModel> _ads = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await AdvertisementService().getOwnerAdvertisements();
      if (mounted) {
        setState(() {
          _ads = list;
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

  Widget _buildAiBadge(AdvertisementModel ad) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (ad.isAiApproved) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.15);
      fg = const Color(0xFF10B981);
      icon = Icons.verified_rounded;
      label = 'AI APPROVED (${(ad.aiConfidence * 100).toInt()}%)';
    } else if (ad.isAiFlagged) {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amber;
      icon = Icons.warning_amber_rounded;
      label = 'AI FLAGGED - REVIEW';
    } else if (ad.isAiRejected) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.redAccent;
      icon = Icons.cancel_outlined;
      label = 'AI REJECTED';
    } else {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blueAccent;
      icon = Icons.hourglass_top_rounded;
      label = 'PENDING AI';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _ads.where((ad) {
      final matchesSearch = ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ad.billboardName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      if (_filter == 'ALL') return matchesSearch;
      if (_filter == 'RUNNING') return matchesSearch && ad.status == 'RUNNING';
      if (_filter == 'SCHEDULED') return matchesSearch && ad.status == 'SCHEDULED';
      if (_filter == 'COMPLETED') return matchesSearch && ad.status == 'COMPLETED';
      return matchesSearch;
    }).toList();

    return RoleGuard(
      allowedRoles: RoleAccess.adminAndOwner,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: RefreshIndicator(
          onRefresh: _loadAds,
          color: AppColors.accentLight,
          backgroundColor: AppColors.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.accentPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.accentLight,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast Advertisements & AI Verification',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Inspect advertisement creatives scheduled on your displays, live playback progress, and Gemini AI compliance safety results.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by ad title or billboard...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentLight),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.borderSubtle.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderSubtle.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filter,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(Icons.filter_list_rounded, color: AppColors.accentLight),
                          onChanged: (val) {
                            if (val != null) setState(() => _filter = val);
                          },
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Advertisements')),
                            DropdownMenuItem(value: 'RUNNING', child: Text('Live / Running')),
                            DropdownMenuItem(value: 'SCHEDULED', child: Text('Scheduled')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Content
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(60.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accentLight),
                    ),
                  )
                else if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade900),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadAds,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                          child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                else if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderSubtle.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.video_library_rounded, size: 60, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No Advertisements Found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'When ads are scheduled and verified by AI for your billboards, they will be listed here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final ad = filtered[index];
                      final isRunning = ad.status == 'RUNNING';

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRunning
                                ? AppColors.accentPrimary.withValues(alpha: 0.5)
                                : AppColors.borderSubtle.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildAiBadge(ad),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ad.mediaType == 'VIDEO'
                                        ? Colors.purple.withValues(alpha: 0.2)
                                        : Colors.cyan.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ad.mediaType,
                                    style: TextStyle(
                                      color: ad.mediaType == 'VIDEO' ? Colors.purpleAccent : Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isRunning
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      if (isRunning) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        ad.status,
                                        style: TextStyle(
                                          color: isRunning ? const Color(0xFF10B981) : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              ad.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (ad.billboardName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Display: ${ad.billboardName}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Progress Bar for running / scheduled ad
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Broadcast Slot: ${ad.slotTime}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${ad.progressPercentage}% played',
                                      style: const TextStyle(
                                        color: AppColors.accentLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: ad.progressPercentage / 100.0,
                                    backgroundColor: AppColors.inputBg,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isRunning ? AppColors.accentPrimary : const Color(0xFF10B981),
                                    ),
                                    minHeight: 8,
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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import '../../models/advertisement_model.dart';
import '../../services/advertisement_service.dart';
import '../../widgets/role_guard.dart';

class AdvertiserBookingsScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdvertiserBookingsScreen({super.key, this.onNavigateTab});

  @override
  State<AdvertiserBookingsScreen> createState() => _AdvertiserBookingsScreenState();
}

class _AdvertiserBookingsScreenState extends State<AdvertiserBookingsScreen> {
  List<AdvertisementModel> _ads = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ads = await AdvertisementService().getAllAdvertisements();
      if (mounted) {
        setState(() {
          _ads = ads;
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

  Future<void> _openGoogleMaps(String location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $location')),
        );
      }
    }
  }

  void _openUpdateAdModal(AdvertisementModel ad) {
    final titleController = TextEditingController(text: ad.title);
    String selectedSlot = ad.slotTime;
    String selectedMedia = ad.mediaType;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar_rounded, color: AppColors.accentLight),
              SizedBox(width: 10),
              Text(
                'Update Booked Slot & Ad',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Campaign / Ad Title',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedSlot,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Broadcast Time Slot',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '08:00 AM - 12:00 PM', child: Text('08:00 AM - 12:00 PM (Morning Prime)')),
                    DropdownMenuItem(value: '12:00 PM - 04:00 PM', child: Text('12:00 PM - 04:00 PM (Afternoon)')),
                    DropdownMenuItem(value: '04:00 PM - 08:00 PM', child: Text('04:00 PM - 08:00 PM (Evening Prime)')),
                    DropdownMenuItem(value: '08:00 PM - 12:00 AM', child: Text('08:00 PM - 12:00 AM (Night Life)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedSlot = val);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedMedia,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Creative Media Format',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'IMAGE', child: Text('High-Res Poster (.PNG / .JPG)')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Full Motion Video (.MP4 / .MOV)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMedia = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await AdvertisementService().updateAdvertisement(
                          advertisementId: ad.advertisementId,
                          title: titleController.text.trim(),
                          mediaType: selectedMedia,
                          slotTime: selectedSlot,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        _loadBookings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking & ad creative updated successfully!')),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
      label = 'AI MANUAL REVIEW';
    } else if (ad.isAiRejected) {
      bg = Colors.red.withValues(alpha: 0.15);
      fg = Colors.redAccent;
      icon = Icons.cancel_outlined;
      label = 'AI REJECTED';
    } else {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blueAccent;
      icon = Icons.hourglass_top_rounded;
      label = 'AI SCREENING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAds = _ads.where((ad) {
      final matchesSearch = ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ad.billboardName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      if (_filterStatus == 'ALL') return matchesSearch;
      if (_filterStatus == 'RUNNING') return matchesSearch && ad.status == 'RUNNING';
      if (_filterStatus == 'SCHEDULED') return matchesSearch && ad.status == 'SCHEDULED';
      if (_filterStatus == 'COMPLETED') return matchesSearch && ad.status == 'COMPLETED';
      return matchesSearch;
    }).toList();

    return RoleGuard(
      allowedRoles: RoleAccess.advertiser,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: RefreshIndicator(
          onRefresh: _loadBookings,
          color: AppColors.accentLight,
          backgroundColor: AppColors.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner Header
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
                          Icons.playlist_play_rounded,
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
                              'My Booked Billboards & Broadcasts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your reserved billboard devices, inspect Gemini AI safety statuses, update creative assets, and follow live broadcast playback.',
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

                // Search & Filters Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by ad title or screen name/location...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentLight),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                          value: _filterStatus,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          icon: const Icon(Icons.filter_list_rounded, color: AppColors.accentLight),
                          onChanged: (val) {
                            if (val != null) setState(() => _filterStatus = val);
                          },
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Bookings')),
                            DropdownMenuItem(value: 'RUNNING', child: Text('Live Broadcasts')),
                            DropdownMenuItem(value: 'SCHEDULED', child: Text('Upcoming Slots')),
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
                          onPressed: _loadBookings,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
                          child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                else if (filteredAds.isEmpty)
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
                    child: Column(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No Bookings Found',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'You have not booked any digital billboard displays matching your search yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => widget.onNavigateTab?.call(1), // Go to search billboards
                          icon: const Icon(Icons.search_rounded, color: Colors.white),
                          label: const Text('BROWSE AVAILABLE BILLBOARDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAds.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final ad = filteredAds[index];
                      final isRunning = ad.status == 'RUNNING';
                      final billboardName = ad.billboardName ?? 'Digital Billboard Display';

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRunning
                                ? AppColors.accentPrimary.withValues(alpha: 0.4)
                                : AppColors.borderSubtle.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Badges and Update Action
                            Row(
                              children: [
                                _buildAiBadge(ad),
                                const SizedBox(width: 8),
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
                                    mainAxisSize: MainAxisSize.min,
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

                            // Ad Title & Billboard
                            Text(
                              ad.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.tv_rounded, size: 14, color: AppColors.accentLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    billboardName,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Schedule & Progress Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accentLight),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Slot: ${ad.slotTime}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${ad.progressPercentage}% played',
                                        style: const TextStyle(
                                          color: AppColors.accentLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
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
                            ),
                            const SizedBox(height: 14),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openGoogleMaps(billboardName),
                                  icon: const Icon(Icons.map_rounded, size: 14, color: AppColors.accentLight),
                                  label: const Text('VIEW MAP', style: TextStyle(color: AppColors.accentLight, fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.borderSubtle),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _openUpdateAdModal(ad),
                                  icon: const Icon(Icons.edit_calendar_rounded, size: 14, color: Colors.white),
                                  label: const Text('UPDATE AD / SLOT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

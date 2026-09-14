import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/booking_flow.dart';
import '../../models/advertisement_model.dart';
import '../../models/billboard_model.dart';
import '../../services/auth_service.dart';
import '../../services/advertisement_service.dart';
import '../../services/billboard_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/qr_scanner_screen.dart';

class AdvertiserDashboard extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final bool isNewRegistration;

  const AdvertiserDashboard({
    super.key,
    this.onNavigateTab,
    this.isNewRegistration = false,
  });

  @override
  State<AdvertiserDashboard> createState() => _AdvertiserDashboardState();
}

class _AdvertiserDashboardState extends State<AdvertiserDashboard> {
  List<AdvertisementModel> _ads = [];
  List<BillboardModel> _billboards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final ads = await AdvertisementService().getAllAdvertisements();
    final billboards = await BillboardService().getAllBillboards();
    if (mounted) {
      setState(() {
        _ads = ads;
        _billboards = billboards;
        _isLoading = false;
      });
    }
  }

  // ── 1. Open the camera scanner and continue directly to booking ────────────
  Future<void> _openQrScannerDialog() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted || scannedCode == null || scannedCode.isEmpty) return;

    final billboard = _findBillboardFromQr(scannedCode);
    if (billboard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This QR code is not a SmartAds billboard.'),
        ),
      );
      return;
    }
    _openBookingFlow(billboard);
  }

  BillboardModel? _findBillboardFromQr(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['billboardId'] != null) {
        final id = int.tryParse(decoded['billboardId'].toString());
        return _billboards.cast<BillboardModel?>().firstWhere(
          (billboard) => billboard?.billboardId == id,
          orElse: () => null,
        );
      }
    } catch (_) {}

    final idMatch = RegExp(
      r'(?:billboards?/|BLB[-_])([0-9]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (idMatch == null) return null;
    final id = int.tryParse(idMatch.group(1)!);
    for (final billboard in _billboards) {
      if (billboard.billboardId == id) return billboard;
    }
    return null;
  }

  // ── 2. Open Booking Flow Dialog ───────────────────────────────────────────
  void _openBookingFlow(BillboardModel billboard) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          BookingFlowDialog(billboard: billboard, canManageAds: true),
    );

    if (result == true && mounted) {
      _loadDashboardData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.accentPrimary),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Booking Confirmed on ${billboard.billboardName}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── 3. Update Advertisement Dialog (Add Slot / Change Media) ──────────────
  void _openUpdateAdDialog(AdvertisementModel ad) {
    final titleController = TextEditingController(text: ad.title);
    String selectedSlot = ad.slotTime;
    String selectedMedia = ad.mediaType;
    String? mediaUrl = ad.mediaUrl;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setUpdateState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit_calendar_rounded, color: AppColors.accentLight),
              SizedBox(width: 10),
              Text(
                'Update Advertisement',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extend or change your broadcast time slot, add new videos, or edit advertisement info.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Ad Title Input
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ADVERTISEMENT TITLE',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot Selection (Add / Extend slot)
                const Text(
                  'SELECT / EXTEND TIME SLOT',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        '08:00 AM - 12:00 PM (Morning)',
                        '12:00 PM - 04:00 PM (Afternoon)',
                        '04:00 PM - 08:00 PM (Peak Evening)',
                        '08:00 PM - 12:00 AM (Night Slot)',
                        '+ 2 Hours Extension',
                      ].map((slot) {
                        final isSelected = selectedSlot.startsWith(
                          slot.split(' ')[0],
                        );
                        return ChoiceChip(
                          label: Text(
                            slot,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accentPrimary,
                          onSelected: (val) {
                            setUpdateState(() => selectedSlot = slot);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 18),

                // Change or Add Media / Video
                const Text(
                  'MEDIA FORMAT & CONTENT',
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
                      label: const Text('IMAGE (.PNG / .JPG)'),
                      selected: selectedMedia == 'IMAGE',
                      selectedColor: AppColors.accentPrimary,
                      onSelected: (_) => setUpdateState(() {
                        selectedMedia = 'IMAGE';
                        mediaUrl =
                            'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=800';
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('VIDEO (.MP4 / .MOV)'),
                      selected: selectedMedia == 'VIDEO',
                      selectedColor: AppColors.accentPrimary,
                      onSelected: (_) => setUpdateState(() {
                        selectedMedia = 'VIDEO';
                        mediaUrl =
                            'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4';
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Media Preview Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderSubtle.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedMedia == 'VIDEO'
                            ? Icons.videocam_rounded
                            : Icons.image_rounded,
                        color: AppColors.accentLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Media: $selectedMedia (Ready for broadcast)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setUpdateState(() => isSaving = true);
                      await AdvertisementService().updateAdvertisement(
                        advertisementId: ad.advertisementId,
                        title: titleController.text.trim(),
                        mediaType: selectedMedia,
                        mediaUrl: mediaUrl,
                        slotTime: selectedSlot,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.cardDark,
                          content: Text(
                            'Advertisement "${titleController.text.trim()}" updated successfully!',
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'SAVE & UPDATE AD',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return RoleGuard(
      allowedRoles: RoleAccess.advertiser,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner (New Advertiser vs Returning Advertiser) ────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF065F46),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADVERTISER PORTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.isNewRegistration
                                ? 'Welcome to SmartAds! You registered as an Advertiser.'
                                : 'Welcome back to SmartAds, ${user?.fullName ?? 'Advertiser'}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isNewRegistration
                                ? 'Get started now! Scan a physical billboard QR code on-site or search digital billboards to schedule your first advertisement.'
                                : 'Monitor your active billboard broadcasts, check real-time playback percentages, and update your advertising media or time slots.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop)
                      const Icon(
                        Icons.campaign_rounded,
                        size: 70,
                        color: AppColors.accentLight,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── NEW ADVERTISER ONBOARDING ACTIONS (Scan QR vs Search) ────────
              if (widget.isNewRegistration) ...[
                const Text(
                  'GET STARTED: CHOOSE HOW YOU WANT TO ADVERTISE',
                  style: TextStyle(
                    color: AppColors.accentPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildScanQrCard()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildSearchBillboardCard()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildScanQrCard(),
                              const SizedBox(height: 16),
                              _buildSearchBillboardCard(),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 32),
              ],

              // ── CAMPAIGN METRICS ─────────────────────────────────────────────
              const Text(
                'CAMPAIGN & ADVERTISING METRICS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 2.2,
                children: const [
                  StatCard(
                    title: 'Active Campaigns',
                    value: '3 Running',
                    subtitle: '2 Scheduled for Q4',
                    icon: Icons.campaign_rounded,
                    accentColor: AppColors.accentPrimary,
                  ),
                  StatCard(
                    title: 'Uploaded Media Ads',
                    value: '6 Files',
                    subtitle: 'Ready for Broadcast',
                    icon: Icons.perm_media_rounded,
                    accentColor: Colors.cyan,
                  ),
                  StatCard(
                    title: 'Total Spending',
                    value: '680,000 FCFA',
                    subtitle: 'Paid via MoMo / Orange',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: Color(0xFF10B981),
                  ),
                  StatCard(
                    title: 'Playbacks',
                    value: '42,500 Times',
                    subtitle: 'Player Reported',
                    icon: Icons.auto_awesome_rounded,
                    accentColor: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── EXISTING ADVERTISEMENTS & LIVE PROGRESS STATUS BAR ────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'MY ADVERTISEMENTS & LIVE STATUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Live playback progress percentage: Ongoing ads show live %, upcoming ads show 0%.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadDashboardData,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.accentLight,
                    ),
                    tooltip: 'Refresh Ad Progress',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                )
              else if (_ads.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderSubtle.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.perm_media_outlined,
                        size: 50,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Active Advertisements',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Scan a billboard QR code or search available billboards to publish your first ad.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openQrScannerDialog,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 16,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'SCAN BILLBOARD QR CODE',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ads.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    return _buildAdProgressCard(ad);
                  },
                ),
              const SizedBox(height: 36),

              // ── QUICK ACTIONS ROW ─────────────────────────────────────────────
              const Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openQrScannerDialog,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'SCAN PHYSICAL QR CODE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.onNavigateTab?.call(1), // Billboards tab
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.accentLight,
                    ),
                    label: const Text(
                      'SEARCH DIGITAL BILLBOARDS',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── ONBOARDING CARD 1: SCAN QR CODE ───────────────────────────────────────
  Widget _buildScanQrCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.accentLight,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Billboard QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Standing in front of a screen?',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'The person standing in front of the billboard can instantly scan the physical QR code on the display. It automatically opens that billboard\'s booking page to select time, pay, and upload ad.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openQrScannerDialog,
              icon: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.black,
                size: 18,
              ),
              label: const Text(
                'SCAN PHYSICAL QR CODE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ONBOARDING CARD 2: SEARCH BILLBOARDS ───────────────────────────────────
  Widget _buildSearchBillboardCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.travel_explore_rounded,
                  color: Colors.cyanAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Available Billboards',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Browse prime locations',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Search through all active digital billboard displays across Cameroon. Review hourly rates, screen resolutions, and click "Book Now" to select time slots, upload, and AI verify.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab?.call(1),
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'SEARCH DIGITAL BILLBOARDS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ADVERTISEMENT PROGRESS CARD WITH STATUS BAR & UPDATE BUTTON ────────────
  Widget _buildAdProgressCard(AdvertisementModel ad) {
    final int progress = _calculateScheduleProgress(ad);
    final bool isOngoing = progress > 0 && progress < 100;
    final bool isUpcoming = progress == 0;

    Color statusColor = isOngoing
        ? const Color(0xFF10B981)
        : (isUpcoming ? Colors.cyan : Colors.amber);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title, Media badge, and Update Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ad.mediaType == 'VIDEO'
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                  color: AppColors.accentLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.billboardName ?? 'Douala Akwa Commercial LED'} • Slot: ${ad.slotTime}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // "Update Advertisement" Action Button
              ElevatedButton.icon(
                onPressed: () => _openUpdateAdDialog(ad),
                icon: const Icon(
                  Icons.edit_calendar_rounded,
                  size: 14,
                  color: Colors.black,
                ),
                label: const Text(
                  'UPDATE AD',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              Text(
                'Start: ${ad.playStartTime}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                'End: ${ad.playEndTime}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                isUpcoming
                    ? 'Remaining: Not started'
                    : (progress >= 100
                          ? 'Remaining: Finished'
                          : 'Remaining: In progress'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Text(
                'Payment: Paid',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Status Bar Row with Percentage ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOngoing
                        ? 'BROADCASTING LIVE ($progress%)'
                        : (isUpcoming
                              ? 'STILL TO START (0%)'
                              : 'COMPLETED (100%)'),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (progress / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.inputBg,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOngoing
                    ? 'Active broadcast in progress on physical display'
                    : (isUpcoming
                          ? 'Ad queue ready • Waiting for time slot to start'
                          : 'Time slot playback finished'),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const Text(
                'AI Safety: Verified 100%',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateScheduleProgress(AdvertisementModel ad) {
    DateTime? parseTime(String value) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})\s*([AP]M)?',
        caseSensitive: false,
      ).firstMatch(value.trim());
      if (match == null) return null;
      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final meridiem = match.group(3)?.toUpperCase();
      if (meridiem != null) {
        if (hour == 12) hour = 0;
        if (meridiem == 'PM') hour += 12;
      }
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final start = parseTime(ad.playStartTime);
    final end = parseTime(ad.playEndTime);
    if (start == null || end == null || !end.isAfter(start)) {
      return ad.progressPercentage.clamp(0, 100);
    }
    final now = DateTime.now();
    if (now.isBefore(start)) return 0;
    if (!now.isBefore(end)) return 100;
    return (((now.difference(start).inSeconds /
                    end.difference(start).inSeconds) *
                100)
            .round())
        .clamp(0, 100);
  }
}

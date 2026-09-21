import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/campaign_model.dart';
import '../models/billboard_model.dart';
import '../services/campaign_service.dart';
import '../services/billboard_service.dart';
import '../widgets/time_slot_picker.dart';
import '../widgets/role_guard.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  List<CampaignModel> _campaigns = [];
  List<BillboardModel> _billboards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final campaigns = await CampaignService().getAllCampaigns();
    final billboards = await BillboardService().getAllBillboards();
    if (mounted) {
      setState(() {
        _campaigns = campaigns;
        _billboards = billboards;
        _isLoading = false;
      });
    }
  }

  void _showCreateCampaignDialog() {
    final nameController = TextEditingController();
    final startController = TextEditingController(text: '2026-09-01');
    final endController = TextEditingController(text: '2026-09-30');
    final budgetController = TextEditingController(text: '15000');
    String selectedSlotText = '08:00 AM - 09:00 AM (1 Hour)';
    int selectedBillboardId = _billboards.isNotEmpty
        ? _billboards.first.billboardId
        : 1;

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
              Icon(Icons.campaign_rounded, color: AppTheme.accentLight),
              SizedBox(width: 10),
              Text(
                'Create Advertising Campaign',
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
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'CAMPAIGN NAME *',
                  hintText: 'e.g. Q4 Brand Expansion',
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time Slot & Pricing Selection Launcher Button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppTheme.accentLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TIME SLOT & DURATION PRICING',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedSlotText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_billboards.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No available time slots.'),
                            ),
                          );
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (context) => TimeSlotPickerModal(
                            billboardId: _billboards
                                .firstWhere(
                                  (b) => b.billboardId == selectedBillboardId,
                                  orElse: () => _billboards.first,
                                )
                                .billboardId,
                            billboardName: _billboards
                                .firstWhere(
                                  (b) => b.billboardId == selectedBillboardId,
                                  orElse: () => _billboards.first,
                                )
                                .billboardName,
                            hourlyRate: _billboards
                                .firstWhere(
                                  (billboard) =>
                                      billboard.billboardId ==
                                      selectedBillboardId,
                                  orElse: () => _billboards.first,
                                )
                                .hourlyRate,
                            onSlotSelected: (slotTime, duration, price) {
                              setModalState(() {
                                selectedSlotText = '$slotTime ($duration)';
                                budgetController.text = price.toStringAsFixed(
                                  0,
                                );
                              });
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'SELECT SLOT',
                        style: TextStyle(
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'START DATE',
                        labelStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'END DATE',
                        labelStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'CALCULATED BUDGET (FCFA)',
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
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
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final budget =
                      double.tryParse(budgetController.text) ?? 15000.0;
                  await CampaignService().createCampaign(
                    campaignName: nameController.text.trim(),
                    startDate: startController.text.trim(),
                    endDate: endController.text.trim(),
                    totalBudget: budget,
                    billboardId: selectedBillboardId,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'CREATE CAMPAIGN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
          onRefresh: _loadData,
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Campaign Management & Time Slot Availability',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Inspect free vs occupied billboard time slots, calculate durations (1-min to daily), & schedule campaigns.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateCampaignDialog,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text(
                        'NEW CAMPAIGN',
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
                else if (_campaigns.isEmpty)
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
                          Icons.campaign_rounded,
                          size: 60,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Active Campaigns',
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = _campaigns[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: AppTheme.accentLight,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign.campaignName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Duration: ${campaign.startDate} to ${campaign.endDate} | Target: ${campaign.billboardName ?? 'Douala LED'}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${campaign.totalBudget.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: AppTheme.accentLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF065F46),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    campaign.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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


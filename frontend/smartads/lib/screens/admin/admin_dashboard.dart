import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/billboard_service.dart';
import '../../models/billboard_model.dart';
import '../../models/advertisement_model.dart';
import '../../services/advertisement_service.dart';
import '../owner/add_billboard_screen.dart';
import '../analytics_iot_screen.dart';
import '../../widgets/qr_code_dialog.dart';
import '../../widgets/role_guard.dart';
import 'admin_iot_monitoring_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ── Edit User Dialog ───────────────────────────────────────────────────────
  Future<void> _showEditUserDialog(
    BuildContext context,
    Map<String, dynamic> user,
    Future<void> Function() onSaved,
  ) async {
    final nameController = TextEditingController(
      text: user['fullName']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: user['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: user['phoneNumber']?.toString() ?? '',
    );
    var role = (user['role'] ?? 'USER').toString().toUpperCase();
    var status = (user['accountStatus'] ?? 'ACTIVE').toString().toUpperCase();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.accentPrimary, width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.manage_accounts_rounded, color: AppColors.accentLight),
              SizedBox(width: 10),
              Text(
                'Update User Account',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  items:
                      const ['ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setDialogState(() => role = value!),
                  decoration: const InputDecoration(
                    labelText: 'Platform Role',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  items: const ['ACTIVE', 'SUSPENDED', 'BLOCKED']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await ApiService().updateUser(
                          userId: int.parse(user['userId'].toString()),
                          fullName: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phoneNumber: phoneController.text.trim(),
                          role: role,
                          accountStatus: status,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await onSaved();
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Update failed: $error')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _setUserStatus(
    BuildContext context,
    Map<String, dynamic> user,
    String status,
    Future<void> Function() onSaved,
  ) async {
    try {
      await ApiService().updateUser(
        userId: int.parse(user['userId'].toString()),
        accountStatus: status,
      );
      if (!context.mounted) return;
      await onSaved();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cardDark,
          content: Text('User status updated to $status.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status update failed: $error')),
      );
    }
  }

  // ── Manage Users Dialog (Mobile & Desktop Responsive) ─────────────────────
  void _openManageUsersDialog(BuildContext context) async {
    String searchQuery = '';
    String selectedRoleFilter = 'ALL';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 600;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService().getAllUsers(),
            builder: (context, snapshot) {
              final allUsers = snapshot.data ?? [];
              final filteredUsers = allUsers.where((u) {
                final name = (u['fullName'] ?? '').toString().toLowerCase();
                final email = (u['email'] ?? '').toString().toLowerCase();
                final role = (u['role'] ?? '').toString().toUpperCase();
                final query = searchQuery.toLowerCase();
                final matchesQuery = name.contains(query) || email.contains(query);
                final matchesRole = selectedRoleFilter == 'ALL' || role == selectedRoleFilter;
                return matchesQuery && matchesRole;
              }).toList();

              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Container(
                  width: min(size.width * 0.96, 850),
                  height: min(size.height * 0.90, 720),
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Manage Platform Users',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 19,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Search & Role Filter
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Search user name or email...',
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (val) {
                                  setModalState(() => searchQuery = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Role Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'ADMIN', 'ADVERTISER', 'BILLBOARD_OWNER', 'USER'].map((r) {
                            final isSel = selectedRoleFilter == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  r == 'BILLBOARD_OWNER' ? 'OWNER' : r,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: Colors.redAccent,
                                backgroundColor: AppColors.cardDark,
                                onSelected: (val) {
                                  if (val) setModalState(() => selectedRoleFilter = r);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // User Count
                      Text(
                        'Total Accounts: ${filteredUsers.length} of ${allUsers.length}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 8),

                      // List
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.redAccent),
                          ),
                        )
                      else if (filteredUsers.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No matching user accounts found.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final u = filteredUsers[index];
                              final role = (u['role'] ?? 'USER').toString();
                              final status = (u['accountStatus'] ?? 'ACTIVE').toString().toUpperCase();
                              final isCurrentAdmin =
                                  u['userId'].toString() == AuthService().currentUser?.userId.toString();

                              Color roleColor = Colors.cyan;
                              if (role == 'ADMIN') roleColor = Colors.redAccent;
                              if (role == 'ADVERTISER') roleColor = const Color(0xFF10B981);
                              if (role.contains('OWNER')) roleColor = Colors.amber;

                              return Container(
                                padding: EdgeInsets.all(isMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrentAdmin
                                        ? Colors.redAccent.withValues(alpha: 0.5)
                                        : AppColors.borderSubtle.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: isMobile ? 18 : 22,
                                      backgroundColor: roleColor.withValues(alpha: 0.2),
                                      child: Icon(Icons.person, color: roleColor, size: isMobile ? 18 : 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  u['fullName'] ?? 'User #${u['userId']}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: roleColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: roleColor, width: 0.8),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: TextStyle(
                                                    color: roleColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${u['email']} • ${u['phoneNumber'] ?? '+237 600000000'}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: status == 'ACTIVE'
                                                      ? const Color(0xFF10B981)
                                                      : (status == 'SUSPENDED' ? Colors.orange : Colors.red),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Status: $status',
                                                style: TextStyle(
                                                  color: status == 'ACTIVE'
                                                      ? const Color(0xFF10B981)
                                                      : (status == 'SUSPENDED' ? Colors.orangeAccent : Colors.redAccent),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: isCurrentAdmin ? 'Your Account' : 'Edit User',
                                      onPressed: isCurrentAdmin
                                          ? null
                                          : () => _showEditUserDialog(
                                                context,
                                                u,
                                                () async => setModalState(() {}),
                                              ),
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: isCurrentAdmin ? Colors.grey : AppColors.accentLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Change Status',
                                      enabled: !isCurrentAdmin,
                                      onSelected: (nextStatus) => _setUserStatus(
                                        context,
                                        u,
                                        nextStatus,
                                        () async => setModalState(() {}),
                                      ),
                                      itemBuilder: (context) => [
                                        if (status != 'ACTIVE')
                                          const PopupMenuItem(
                                            value: 'ACTIVE',
                                            child: Text('Activate Account'),
                                          ),
                                        if (status != 'SUSPENDED')
                                          const PopupMenuItem(
                                            value: 'SUSPENDED',
                                            child: Text('Suspend Account'),
                                          ),
                                        if (status != 'BLOCKED')
                                          const PopupMenuItem(
                                            value: 'BLOCKED',
                                            child: Text('Block Account'),
                                          ),
                                      ],
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: isCurrentAdmin ? Colors.grey : AppColors.accentLight,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Edit Billboard Dialog ────────────────────────────────────────────────
  void _openEditBillboardDialog(
    BuildContext context,
    BillboardModel b,
    VoidCallback onSaved,
  ) {
    final nameCtrl = TextEditingController(text: b.billboardName);
    final locCtrl = TextEditingController(text: b.location);
    final rateCtrl = TextEditingController(text: b.hourlyRate.toStringAsFixed(0));
    final maxCampaignsCtrl = TextEditingController(text: b.maxActiveCampaigns.toString());
    String displayStatus = b.status;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (editCtx) => StatefulBuilder(
        builder: (editCtx, setEditState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.accentPrimary, width: 1.2),
          ),
          title: Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: AppColors.accentLight, size: 24),
              SizedBox(width: 10),
              Text(
                'Edit Billboard & TV Specs',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Billboard Name / TV Identifier',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Physical Location Address',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Hourly Rate (FCFA)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxCampaignsCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Max Capacity (Campaigns)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: displayStatus,
                  dropdownColor: AppColors.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Display Status',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Online)')),
                    DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE (Offline)')),
                    DropdownMenuItem(value: 'MAINTENANCE', child: Text('MAINTENANCE')),
                  ],
                  onChanged: (val) {
                    if (val != null) setEditState(() => displayStatus = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(editCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setEditState(() => isSaving = true);
                      try {
                        final rate = double.tryParse(rateCtrl.text.trim()) ?? b.hourlyRate;
                        final maxCap = int.tryParse(maxCampaignsCtrl.text.trim()) ?? b.maxActiveCampaigns;
                        await BillboardService().updateBillboard(
                          billboardId: b.billboardId,
                          billboardName: nameCtrl.text.trim(),
                          location: locCtrl.text.trim(),
                          pricePerHour: rate,
                          maxActiveCampaigns: maxCap,
                          displayStatus: displayStatus,
                        );
                        if (!editCtx.mounted) return;
                        Navigator.pop(editCtx);
                        onSaved();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.cardDark,
                            content: Text('${nameCtrl.text.trim()} updated successfully!'),
                          ),
                        );
                      } catch (e) {
                        setEditState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red.shade900,
                            content: Text('Update failed: $e'),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPrimary),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Manage Billboards Dialog (Mobile & Desktop Responsive) ────────────────
  void _openManageBillboardsDialog(BuildContext context) async {
    String searchQuery = '';
    String statusFilter = 'ALL';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 650;

          return FutureBuilder<List<BillboardModel>>(
            future: BillboardService().getAllBillboards(),
            builder: (context, snapshot) {
              final allBillboards = snapshot.data ?? [];
              final filteredBillboards = allBillboards.where((b) {
                final name = b.billboardName.toLowerCase();
                final loc = b.location.toLowerCase();
                final query = searchQuery.toLowerCase();
                final matchesQuery = name.contains(query) || loc.contains(query);
                final matchesStatus = statusFilter == 'ALL' ||
                    (statusFilter == 'ONLINE' && b.status.toUpperCase() == 'ACTIVE') ||
                    (statusFilter == 'OFFLINE' && b.status.toUpperCase() != 'ACTIVE');
                return matchesQuery && matchesStatus;
              }).toList();

              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Container(
                  width: min(size.width * 0.96, 920),
                  height: min(size.height * 0.90, 740),
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tv_rounded,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Digital Billboards & Screens',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 19,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Controls Bar (Search + Add Billboard)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Filter by billboard name or location...',
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (val) {
                                  setModalState(() => searchQuery = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddBillboardScreen(),
                                ),
                              );
                              setState(() {});
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              isMobile ? 'Add' : 'Add Billboard',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['ALL', 'ONLINE', 'OFFLINE'].map((status) {
                            final isSel = statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: Colors.redAccent,
                                backgroundColor: AppColors.cardDark,
                                onSelected: (val) {
                                  if (val) setModalState(() => statusFilter = status);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Count
                      Text(
                        'Displays Configured: ${filteredBillboards.length} of ${allBillboards.length}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 8),

                      // Billboards list
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.redAccent),
                          ),
                        )
                      else if (filteredBillboards.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No digital billboards match the search query.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: filteredBillboards.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final b = filteredBillboards[index];
                              final bool isOnline = b.status.toUpperCase() == 'ACTIVE';

                              return Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 14),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isOnline
                                        ? const Color(0xFF10B981).withValues(alpha: 0.35)
                                        : Colors.amber.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Icon, Title, Online Badge, and Status Menu
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: isOnline
                                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                : Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.tv_rounded,
                                            size: 18,
                                            color: isOnline ? const Color(0xFF10B981) : Colors.amber,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.billboardName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${b.location} • ${b.hourlyRate.toStringAsFixed(0)} FCFA/hr • Capacity: ${b.maxActiveCampaigns} campaigns',
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentPrimary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            'CAP: ${b.maxActiveCampaigns}',
                                            style: const TextStyle(
                                              color: AppColors.accentLight,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOnline ? const Color(0xFF065F46) : const Color(0xFF78350F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOnline ? 'ONLINE' : 'OFFLINE',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          iconSize: 18,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Change Approval / Display Status',
                                          onSelected: (newStatus) async {
                                            try {
                                              await BillboardService().updateApprovalStatus(
                                                b.billboardId,
                                                newStatus,
                                                notes: 'Updated by System Admin via control console.',
                                              );
                                              setModalState(() {});
                                              setState(() {});
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: AppColors.cardDark,
                                                  content: Text('${b.billboardName} status set to $newStatus'),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed: $e')),
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'ACTIVE',
                                              child: Text('Approve / Online'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'INACTIVE',
                                              child: Text('Set Inactive (Offline)'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'PENDING',
                                              child: Text('Pending Approval'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'REJECTED',
                                              child: Text('Reject / Block'),
                                            ),
                                          ],
                                          icon: const Icon(Icons.more_vert, color: AppColors.accentLight),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 2: Action Buttons (Responsive Wrap)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            _openEditBillboardDialog(context, b, () {
                                              setModalState(() {});
                                              setState(() {});
                                            });
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 14),
                                          label: const Text('Edit Specs', style: TextStyle(fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.accentLight,
                                            side: const BorderSide(color: AppColors.borderSubtle),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const AdminIotMonitoringScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.sensors_rounded, size: 14, color: Colors.cyanAccent),
                                          label: const Text('IoT Telemetry', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.cyan.withValues(alpha: 0.4)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => QrCodeDialog(
                                                billboard: b,
                                                readOnly: false,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.qr_code_2_rounded, size: 14, color: Colors.white),
                                          label: const Text('Print QR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accentPrimary,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Flagged Ads & AI Moderation Dialog ──────────────────────────────────
  void _openFlaggedAdsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 650;

          return FutureBuilder<List<AdvertisementModel>>(
            future: AdvertisementService().getFlaggedAdvertisements(),
            builder: (context, snapshot) {
              final ads = snapshot.data ?? [];

              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.amber, width: 1.5),
                ),
                child: Container(
                  width: min(size.width * 0.96, 800),
                  height: min(size.height * 0.88, 680),
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, color: Colors.amber, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'AI Moderation Queue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Advertisements reviewed by Google Gemini AI safety filters.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.amber),
                          ),
                        )
                      else if (ads.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                                SizedBox(height: 10),
                                Text(
                                  'Flagged Ads Queue Clear!',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'All uploaded ads comply with Gemini safety policies.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: ads.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ad = ads[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber),
                                          ),
                                          child: Text(
                                            ad.verificationStatus,
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Confidence: ${(ad.aiConfidence * 100).toInt()}%',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                        const Spacer(),
                                        Text(
                                          ad.mediaType,
                                          style: const TextStyle(
                                            color: AppColors.accentLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ad.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (ad.rejectionReason != null && ad.rejectionReason!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Note: ${ad.rejectionReason}',
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await AdvertisementService().adminReviewAdvertisement(
                                                advertisementId: ad.advertisementId,
                                                status: 'REJECTED',
                                                adminNotes: 'Rejected during admin review.',
                                                correctionReason: 'Content violates advertising guidelines.',
                                              );
                                              setModalState(() {});
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Ad rejected.')),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                                          label: const Text('REJECT', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await AdvertisementService().adminReviewAdvertisement(
                                                advertisementId: ad.advertisementId,
                                                status: 'APPROVED',
                                                adminNotes: 'Approved after admin manual inspection.',
                                              );
                                              setModalState(() {});
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Ad approved for broadcast!')),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                          label: const Text('APPROVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Manage Payments Dialog ────────────────────────────────────────────────
  void _openManagePaymentsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final size = MediaQuery.of(context).size;
          final isMobile = size.width < 650;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService().getAllPayments(),
            builder: (context, snapshot) {
              final payments = snapshot.data ?? [];
              double totalRevenue = 0;
              for (final p in payments) {
                totalRevenue += (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
              }

              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                insetPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                ),
                child: Container(
                  width: min(size.width * 0.96, 750),
                  height: min(size.height * 0.88, 650),
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.payment_rounded, color: Color(0xFF10B981), size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Payment Ledger & Revenue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Revenue Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Verified Platform Revenue:',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              '${totalRevenue.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF10B981)),
                          ),
                        )
                      else if (payments.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No transactions recorded yet.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: payments.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = payments[index];
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${p['amount']} FCFA • ${p['paymentMethod'] ?? "MOMOPAY"}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            '${p['transactionReference'] ?? "REF-AUTO"} • ${p['advertiserName'] ?? 'Advertiser'}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF065F46),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p['paymentStatus'] ?? 'PAID',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Main Dashboard Builder ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;
    final isDesktop = size.width >= 960;

    return RoleGuard(
      allowedRoles: RoleAccess.admin,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.redAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 12 : 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sleek Admin Command Center Banner
                Container(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E1020),
                        AppColors.surfaceDark,
                        AppColors.cardDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_rounded, size: 11, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'ADMIN CONTROL PANEL',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 9, color: Color(0xFF10B981)),
                                      SizedBox(width: 3),
                                      Text(
                                        'SYS ONLINE',
                                        style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome, ${user?.fullName ?? "System Admin"}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Platform overview: users, displays, active broadcasts, & ledger.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh Dashboard',
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                              )
                            : const Icon(Icons.refresh_rounded, color: AppColors.accentLight),
                        onPressed: _refreshData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Platform KPI Metrics Grid (Compact Responsive 2x2 or 4x1)
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 2.1 : (isMobile ? 1.55 : 2.2),
                  children: const [
                    StatCard(
                      title: 'Total Users',
                      value: '142',
                      subtitle: '85 Advertisers • 42 Owners',
                      icon: Icons.people_alt_rounded,
                      accentColor: Colors.redAccent,
                    ),
                    StatCard(
                      title: 'Digital Billboards',
                      value: '38',
                      subtitle: '35 Online • 3 Maintenance',
                      icon: Icons.tv_rounded,
                      accentColor: Colors.cyan,
                    ),
                    StatCard(
                      title: 'Active Campaigns',
                      value: '24',
                      subtitle: '18 Running • 6 Scheduled',
                      icon: Icons.campaign_rounded,
                      accentColor: Color(0xFF10B981),
                    ),
                    StatCard(
                      title: 'Gross Revenue',
                      value: '4.85M FCFA',
                      subtitle: 'All Bookings & MoMo',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Executive Action Center Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'ADMIN COMMAND CENTER & TOOLS',
                      style: TextStyle(
                        color: AppColors.accentPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Tap tool to manage',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. Professional Action Grid (Cards with modern icons, badges, hover glow)
                GridView.count(
                  crossAxisCount: isDesktop ? 3 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 2.3 : (isMobile ? 1.30 : 1.9),
                  children: [
                    _buildAdminActionCard(
                      title: 'Manage Billboards',
                      subtitle: '38 Displays • Specs & QR',
                      icon: Icons.tv_rounded,
                      accentColor: Colors.cyanAccent,
                      badgeText: '38 DISPLAYS',
                      onTap: () => _openManageBillboardsDialog(context),
                    ),
                    _buildAdminActionCard(
                      title: 'Manage Users',
                      subtitle: '142 Accounts • Roles & Status',
                      icon: Icons.people_alt_rounded,
                      accentColor: Colors.redAccent,
                      badgeText: '142 USERS',
                      onTap: () => _openManageUsersDialog(context),
                    ),
                    _buildAdminActionCard(
                      title: 'IoT Monitoring',
                      subtitle: 'Live Telemetry & Heartbeat',
                      icon: Icons.sensors_rounded,
                      accentColor: const Color(0xFF00E5FF),
                      badgeText: 'ONLINE PING',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminIotMonitoringScreen(),
                          ),
                        );
                      },
                    ),
                    _buildAdminActionCard(
                      title: 'AI Moderation',
                      subtitle: 'Gemini Safety Inspection',
                      icon: Icons.verified_user_rounded,
                      accentColor: Colors.amber,
                      badgeText: 'GEMINI AI',
                      onTap: () => _openFlaggedAdsDialog(context),
                    ),
                    _buildAdminActionCard(
                      title: 'Payment Ledger',
                      subtitle: 'Revenue Logs & Verification',
                      icon: Icons.payment_rounded,
                      accentColor: const Color(0xFF10B981),
                      badgeText: 'VERIFIED',
                      onTap: () => _openManagePaymentsDialog(context),
                    ),
                    _buildAdminActionCard(
                      title: 'Add TV Billboard',
                      subtitle: 'Register New Screen / TV',
                      icon: Icons.add_location_alt_rounded,
                      accentColor: Colors.purpleAccent,
                      badgeText: 'NEW SCREEN',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddBillboardScreen(),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. IoT & Revenue Analytics Shortcut Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Colors.blueAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'IoT Analytics & Dwell Time',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Foot-traffic analytics, screen uptime, & broadcast playback stats.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnalyticsIotScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('OPEN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Recent Platform Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'RECENT PLATFORM ACTIVITY & NOTIFICATIONS',
                      style: TextStyle(
                        color: AppColors.accentPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Live Logs',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderSubtle.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: const [
                      _ActivityTile(
                        icon: Icons.check_circle_outline_rounded,
                        iconColor: Color(0xFF10B981),
                        title: 'New Billboard Configured: Douala Akwa LED',
                        subtitle: 'Owner: Douala Media Corp • QR Code Active',
                        timeText: '10m ago',
                      ),
                      Divider(color: AppColors.borderSubtle, height: 1),
                      _ActivityTile(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.accentLight,
                        title: 'AI Content Scanning: Brand Refresh Video',
                        subtitle: 'Gemini Safety Check: APPROVED (Confidence: 98.5%)',
                        timeText: '1h ago',
                      ),
                      Divider(color: AppColors.borderSubtle, height: 1),
                      _ActivityTile(
                        icon: Icons.payment_rounded,
                        iconColor: Colors.amber,
                        title: 'Payment Received: 280,000 FCFA via MTN MoMo',
                        subtitle: 'Booking #BK-4091 • SmartWatch X Launch',
                        timeText: '3h ago',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 0.7),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timeText;

  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
      ),
      trailing: Text(
        timeText,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    );
  }
}

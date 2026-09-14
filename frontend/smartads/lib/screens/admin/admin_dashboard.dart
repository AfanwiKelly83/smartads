import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/billboard_service.dart';
import '../../models/billboard_model.dart';
import '../owner/add_billboard_screen.dart';
import '../analytics_iot_screen.dart';
import '../../widgets/qr_code_dialog.dart';
import '../../widgets/role_guard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
          title: const Text(
            'Update User Account',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  dropdownColor: AppColors.surfaceDark,
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
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.surfaceDark,
                  items: const ['ACTIVE', 'SUSPENDED', 'BLOCKED']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
                  decoration: const InputDecoration(
                    labelText: 'Account status',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
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
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE CHANGES'),
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
        SnackBar(content: Text('Account status changed to $status.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status update failed: $error')));
    }
  }

  // ── Manage Users Dialog ───────────────────────────────────────────────────
  void _openManageUsersDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService().getAllUsers(),
            builder: (context, snapshot) {
              final users = snapshot.data ?? [];
              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 700,
                    maxHeight: 600,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.people_alt_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Manage Platform Users',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Registered Accounts: ${users.length} (Admin, Advertisers, Screen Owners)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: users.length,
                            separatorBuilder: (_, index) =>
                                const Divider(color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final u = users[index];
                              final role = (u['role'] ?? 'USER').toString();
                              final status = (u['accountStatus'] ?? 'ACTIVE')
                                  .toString()
                                  .toUpperCase();
                              final isCurrentAdmin =
                                  u['userId'].toString() ==
                                  AuthService().currentUser?.userId.toString();
                              Color roleColor = Colors.cyan;
                              if (role == 'ADMIN') {
                                roleColor = Colors.redAccent;
                              }
                              if (role == 'ADVERTISER') {
                                roleColor = const Color(0xFF10B981);
                              }
                              if (role.contains('OWNER')) {
                                roleColor = Colors.amber;
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: roleColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Icon(Icons.person, color: roleColor),
                                ),
                                title: Text(
                                  u['fullName'] ?? 'User #${u['userId']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${u['email']} • ${u['phoneNumber'] ?? '+237 600000000'}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Status: $status',
                                      style: TextStyle(
                                        color: status == 'ACTIVE'
                                            ? Colors.greenAccent
                                            : status == 'SUSPENDED'
                                            ? Colors.orangeAccent
                                            : Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: roleColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          color: roleColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: isCurrentAdmin
                                          ? 'Your admin account'
                                          : 'Edit account',
                                      onPressed: isCurrentAdmin
                                          ? null
                                          : () => _showEditUserDialog(
                                              context,
                                              u,
                                              () async => setModalState(() {}),
                                            ),
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: AppColors.accentLight,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Change account status',
                                      enabled: !isCurrentAdmin,
                                      onSelected: (nextStatus) =>
                                          _setUserStatus(
                                            context,
                                            u,
                                            nextStatus,
                                            () async => setModalState(() {}),
                                          ),
                                      itemBuilder: (context) => [
                                        if (status != 'ACTIVE')
                                          const PopupMenuItem(
                                            value: 'ACTIVE',
                                            child: Text('Activate account'),
                                          ),
                                        if (status != 'SUSPENDED')
                                          const PopupMenuItem(
                                            value: 'SUSPENDED',
                                            child: Text('Suspend account'),
                                          ),
                                        if (status != 'BLOCKED')
                                          const PopupMenuItem(
                                            value: 'BLOCKED',
                                            child: Text('Block account'),
                                          ),
                                      ],
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: isCurrentAdmin
                                            ? Colors.grey
                                            : AppColors.accentLight,
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

  // ── Manage Billboards Dialog ──────────────────────────────────────────────
  void _openManageBillboardsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<BillboardModel>>(
            future: BillboardService().getAllBillboards(),
            builder: (context, snapshot) {
              final billboards = snapshot.data ?? [];
              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 750,
                    maxHeight: 650,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.tv_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Manage Billboards & Print QR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AddBillboardScreen(),
                                    ),
                                  );
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.add_location_alt_rounded,
                                  size: 16,
                                ),
                                label: const Text('Add Billboard'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'As Admin, generate, download, or print location QR Codes to paste onto physical billboard displays.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      else if (billboards.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No digital billboards registered yet.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: billboards.length,
                            separatorBuilder: (_, index) =>
                                const Divider(color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final b = billboards[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.tv_rounded,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                title: Text(
                                  b.billboardName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${b.location} • ${b.hourlyRate.toStringAsFixed(0)} FCFA/hr • ${b.screenSize}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => QrCodeDialog(
                                        billboard: b,
                                        readOnly: false,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Print QR'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentPrimary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
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
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: ApiService().getAllPayments(),
            builder: (context, snapshot) {
              final payments = snapshot.data ?? [];
              double totalRevenue = 0;
              for (final p in payments) {
                totalRevenue += (p['amount'] is num)
                    ? (p['amount'] as num).toDouble()
                    : 0.0;
              }

              return Dialog(
                backgroundColor: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 720,
                    maxHeight: 600,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.payment_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Manage Payments & Transactions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF065F46,
                          ).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Verified Platform Revenue:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${totalRevenue.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: payments.length,
                            separatorBuilder: (_, index) =>
                                const Divider(color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final p = payments[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                title: Text(
                                  '${p['amount']} FCFA • ${p['paymentMethod']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${p['transactionReference']} • ${p['advertiserName'] ?? 'Advertiser'}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF065F46),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    p['paymentStatus'] ?? 'PAID',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return RoleGuard(
      allowedRoles: RoleAccess.admin,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Banner Header (distinct red accent)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.28),
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
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMINISTRATOR CONTROL PANEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome System Admin (${user?.fullName ?? 'Admin'})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Full platform oversight: users, billboard owners, advertisers, IoT hardware & financial statistics.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDesktop)
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 70,
                        color: Colors.redAccent,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'PLATFORM OVERVIEW & ANALYTICS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              // Stat Cards Grid (admin accents)
              GridView.count(
                crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 2.2,
                children: const [
                  StatCard(
                    title: 'Total Users',
                    value: '142',
                    subtitle: '85 Advertisers | 42 Owners',
                    icon: Icons.people_alt_rounded,
                    accentColor: Colors.redAccent,
                  ),
                  StatCard(
                    title: 'Total Digital Billboards',
                    value: '38',
                    subtitle: '35 Active | 3 Maintenance',
                    icon: Icons.tv_rounded,
                    accentColor: Colors.cyan,
                  ),
                  StatCard(
                    title: 'Active Campaigns',
                    value: '24',
                    subtitle: '18 Running | 6 Scheduled',
                    icon: Icons.campaign_rounded,
                    accentColor: Color(0xFF10B981),
                  ),
                  StatCard(
                    title: 'Platform Gross Revenue',
                    value: '4.85M FCFA',
                    subtitle: 'All Bookings & Payments',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Analytics Charts
              const Text(
                'REVENUE & BOOKING ANALYTICS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Center(
                  child: Text(
                    'Chart Data (Gross Revenue vs Time)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Admin Quick Actions
              const Text(
                'ADMIN CONTROL ACTIONS (ADMIN ONLY)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // 1. Add Billboard Button (Admin only)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddBillboardScreen(),
                        ),
                      );
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.add_location_alt_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add Billboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),

                  // 2. Manage Billboards Button (Admin only)
                  ElevatedButton.icon(
                    onPressed: () => _openManageBillboardsDialog(context),
                    icon: const Icon(Icons.tv_rounded, color: Colors.white),
                    label: const Text(
                      'Manage Billboards',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),

                  // 3. Manage Users Button (Admin only)
                  ElevatedButton.icon(
                    onPressed: () => _openManageUsersDialog(context),
                    icon: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Manage Users',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),

                  // 4. IoT Monitoring Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminIotMonitoringScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.router_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'IoT Monitoring',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                  // 4. Manage Payments Button (Admin only)
                  ElevatedButton.icon(
                    onPressed: () => _openManagePaymentsDialog(context),
                    icon: const Icon(
                      Icons.payment_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Manage Payments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),

                  // 5. Manage IoT Statistics Button (Admin only)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalyticsIotScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Manage IoT Statistics',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Recent Platform Activities Section
              const Text(
                'RECENT PLATFORM ACTIVITY & NOTIFICATIONS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    ListTile(
                      leading: Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                      ),
                      title: Text(
                        'New Billboard Registered: Douala Akwa LED',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Owner: Douala Media Corp | Status: QR Code Generated & Downloaded',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '10 mins ago',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Divider(color: AppColors.borderSubtle),
                    ListTile(
                      leading: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentLight,
                      ),
                      title: Text(
                        'AI Content Scanning Completed: Brand Refresh Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Result: APPROVED (Confidence: 98.5%)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '1 hour ago',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Divider(color: AppColors.borderSubtle),
                    ListTile(
                      leading: Icon(Icons.payment_rounded, color: Colors.amber),
                      title: Text(
                        'Payment Received: 280,000 FCFA via MTN MoMo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Booking #BK-4091 | Campaign: SmartWatch X Launch',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '3 hours ago',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

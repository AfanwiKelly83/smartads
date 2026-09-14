import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/billboard_model.dart';
import '../services/billboard_service.dart';
import '../widgets/billboard_card.dart';
import '../widgets/booking_flow.dart';
import 'owner/add_billboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/role_guard.dart';

class BillboardScreen extends StatefulWidget {
  const BillboardScreen({super.key});

  @override
  State<BillboardScreen> createState() => _BillboardScreenState();
}

class _BillboardScreenState extends State<BillboardScreen>
    with WidgetsBindingObserver {
  List<BillboardModel> _billboards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'ALL'; // 'ALL', 'ACTIVE', 'AVAILABLE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBillboards();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBillboards();
    }
  }

  Future<void> _loadBillboards() async {
    setState(() => _isLoading = true);
    final data = await BillboardService().getAllBillboards();
    if (mounted) {
      setState(() {
        _billboards = data;
        _isLoading = false;
      });
    }
  }

  void _handleBooking(BillboardModel billboard) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingFlowDialog(
        billboard: billboard,
        canManageAds: AuthService().currentUser?.isAdvertiser == true,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.cardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.accentPrimary),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.accentLight),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Booking completed for ${billboard.billboardName}!',
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

  void _openAddBillboardScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddBillboardScreen()),
    );

    if (result == true) {
      _loadBillboards();
    }
  }

  bool get _canManageBillboards {
    final user = AuthService().currentUser;
    return user?.isAdmin == true;
  }

  bool get _qrIsReadOnly {
    final user = AuthService().currentUser;
    return user?.isAdmin != true;
  }

  Widget _buildPageHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Digital Billboard Directory & QR Codes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Explore available digital billboards, view screen specs, and inspect location QR codes.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildAddBillboardButton() {
    return ElevatedButton.icon(
      onPressed: _openAddBillboardScreen,
      icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      label: const Text(
        'ADD BILLBOARD & QR',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accentLight),
        hintText: 'Search billboard by name or location...',
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppTheme.borderSubtle.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterStatus,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          icon: const Icon(
            Icons.filter_list_rounded,
            color: AppTheme.accentLight,
          ),
          onChanged: (value) {
            if (value != null) setState(() => _filterStatus = value);
          },
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('All Displays')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('Active Only')),
            DropdownMenuItem(value: 'AVAILABLE', child: Text('Available Only')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBillboards = _billboards.where((b) {
      final matchesSearch =
          b.billboardName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.location.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterStatus == 'ALL') return matchesSearch;
      if (_filterStatus == 'ACTIVE') {
        return matchesSearch && b.status.toUpperCase() == 'ACTIVE';
      }
      return matchesSearch && b.availabilityStatus == 'AVAILABLE';
    }).toList();
    final isCompact = MediaQuery.of(context).size.width < 600;

    return RoleGuard(
      allowedRoles: RoleAccess.adminAndAdvertiser,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: RefreshIndicator(
          onRefresh: _loadBillboards,
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Action Header
                isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeading(),
                          if (_canManageBillboards) ...[
                            const SizedBox(height: 16),
                            _buildAddBillboardButton(),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildPageHeading()),
                          if (_canManageBillboards) _buildAddBillboardButton(),
                        ],
                      ),
                const SizedBox(height: 24),

                // Search & Filter Controls
                isCompact
                    ? Column(
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 12),
                          _buildFilterDropdown(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 16),
                          _buildFilterDropdown(),
                        ],
                      ),
                const SizedBox(height: 28),

                // Content Body (Loading, Empty, or Grid)
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(60.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPrimary,
                      ),
                    ),
                  )
                else if (filteredBillboards.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderSubtle.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Digital Billboards Found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing search filters or click "Add Billboard" to create one.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 3;
                      if (width < 700) {
                        crossAxisCount = 1;
                      } else if (width < 1100) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBillboards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.88,
                        ),
                        itemBuilder: (context, index) {
                          final billboard = filteredBillboards[index];
                          return BillboardCard(
                            billboard: billboard,
                            onBookNow: () => _handleBooking(billboard),
                            qrReadOnly: _qrIsReadOnly,
                          );
                        },
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

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/booking_service.dart';
import '../../widgets/role_guard.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  List<BookingItemModel> _bookings = [];
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
      final list = await BookingService().getOwnerBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _bookings.where((b) {
      final matchesSearch = b.billboardName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.advertiserName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.billboardCode.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterStatus == 'ALL') return matchesSearch;
      return matchesSearch && b.status == _filterStatus;
    }).toList();

    return RoleGuard(
      allowedRoles: RoleAccess.adminAndOwner,
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
                          Icons.calendar_month_rounded,
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
                              'Billboard Bookings & Reservations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track advertiser reservations, active schedule slots, and confirmed bookings across your displays.',
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
                          hintText: 'Search by billboard, code, or advertiser...',
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
                          value: _filterStatus,
                          dropdownColor: AppColors.surfaceDark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(Icons.filter_list_rounded, color: AppColors.accentLight),
                          onChanged: (val) {
                            if (val != null) setState(() => _filterStatus = val);
                          },
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Bookings')),
                            DropdownMenuItem(value: 'CONFIRMED', child: Text('Confirmed')),
                            DropdownMenuItem(value: 'PENDING', child: Text('Pending Payment')),
                            DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
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
                        Icon(Icons.event_busy_rounded, size: 60, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'No Bookings Found',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'When advertisers book your digital billboards, their reservations will appear here.',
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
                      final item = filtered[index];
                      final isConfirmed = item.status == 'CONFIRMED';

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isConfirmed
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : AppColors.borderSubtle.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isConfirmed
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isConfirmed ? const Color(0xFF10B981) : Colors.amber,
                                    ),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color: isConfirmed ? const Color(0xFF10B981) : Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (item.billboardCode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPrimary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.billboardCode,
                                      style: const TextStyle(
                                        color: AppColors.accentLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  '${item.amount.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.billboardName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Advertiser: ${item.advertiserName}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                if (item.advertiserEmail.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.advertiserEmail,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 16, color: AppColors.accentLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.startDate}  •  ${item.startTime} - ${item.endTime}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (item.advertisementTitle != null)
                                    Text(
                                      'Ad: ${item.advertisementTitle}',
                                      style: const TextStyle(
                                        color: AppColors.accentLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
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

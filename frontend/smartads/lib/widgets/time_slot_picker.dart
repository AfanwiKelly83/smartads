import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class TimeSlotPickerModal extends StatefulWidget {
  final String billboardName;
  final double hourlyRate;
  final int? billboardId;
  final DateTime? selectedDate;
  final List<Map<String, dynamic>>? availableTimeSlots;
  final Function(String slotTime, String duration, double price) onSlotSelected;

  const TimeSlotPickerModal({
    super.key,
    required this.billboardName,
    required this.hourlyRate,
    this.billboardId,
    this.selectedDate,
    this.availableTimeSlots,
    required this.onSlotSelected,
  });

  @override
  State<TimeSlotPickerModal> createState() => _TimeSlotPickerModalState();
}

class _TimeSlotPickerModalState extends State<TimeSlotPickerModal> {
  int _selectedSlotIndex = -1;

  final List<Map<String, dynamic>> _defaultTimeSlots = [
    {
      'time': '06:00 AM - 07:00 AM',
      'label': 'Early Bird (Off-Peak)',
      'tier': 'OFF_PEAK',
      'price': 2000.0,
      'duration': '1 Hour',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '07:00 AM - 08:00 AM',
      'label': 'Morning Commute',
      'tier': 'STANDARD',
      'price': 3500.0,
      'duration': '1 Hour',
      'isFree': false,
      'occupant': 'Reserved (Orange Campaign)',
    },
    {
      'time': '08:00 AM - 10:00 AM',
      'label': 'Morning Prime Rush',
      'tier': 'PRIME',
      'price': 6000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '10:00 AM - 12:00 PM',
      'label': 'Mid-Day Business',
      'tier': 'STANDARD',
      'price': 5000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '12:00 PM - 02:00 PM',
      'label': 'Lunch Peak',
      'tier': 'PRIME',
      'price': 6500.0,
      'duration': '2 Hours',
      'isFree': false,
      'occupant': 'Reserved (MTN MoMo)',
    },
    {
      'time': '02:00 PM - 04:00 PM',
      'label': 'Afternoon Broadcast',
      'tier': 'STANDARD',
      'price': 4500.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '04:00 PM - 06:00 PM',
      'label': 'Evening Commute Rush',
      'tier': 'PRIME',
      'price': 7000.0,
      'duration': '2 Hours',
      'isFree': false,
      'occupant': 'Reserved (Tech Expo)',
    },
    {
      'time': '06:00 PM - 08:00 PM',
      'label': 'Evening Prime Peak',
      'tier': 'MEGA_PRIME',
      'price': 8000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '08:00 PM - 10:00 PM',
      'label': 'Night Life Prime',
      'tier': 'PRIME',
      'price': 5000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '10:00 PM - 12:00 AM',
      'label': 'Late Night (Off-Peak)',
      'tier': 'OFF_PEAK',
      'price': 2500.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
  ];

  late List<Map<String, dynamic>> _timeSlots;
  bool _isLoading = false;

  bool get _hasAvailableTimeSlots =>
      _timeSlots.any((slot) => slot['isFree'] == true);

  @override
  void initState() {
    super.initState();
    _timeSlots = widget.availableTimeSlots ?? _defaultTimeSlots;
    if (widget.billboardId != null && widget.availableTimeSlots == null) {
      _loadAvailability();
    }
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final slots = await ApiService().getBillboardAvailability(
        billboardId: widget.billboardId!,
        date: widget.selectedDate,
      );
      if (!mounted) return;
      if (slots.isNotEmpty) {
        setState(() => _timeSlots = slots);
      }
    } catch (_) {
      // Keep demo slots with attributed pricing visible
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _calculatedPrice {
    if (_selectedSlotIndex < 0 || _selectedSlotIndex >= _timeSlots.length) {
      return 0.0;
    }
    final slot = _timeSlots[_selectedSlotIndex];
    if (slot['price'] != null) {
      return (slot['price'] as num).toDouble();
    }
    return widget.hourlyRate;
  }

  String get _durationLabel {
    if (_selectedSlotIndex < 0 || _selectedSlotIndex >= _timeSlots.length) {
      return 'Not selected';
    }
    final slot = _timeSlots[_selectedSlotIndex];
    return slot['duration']?.toString() ?? 'Slot';
  }

  String get _dateDisplay {
    final d = widget.selectedDate ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.95,
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 750),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'TIME SLOT AVAILABILITY & ATTRIBUTED PRICING',
                              style: TextStyle(
                                color: AppColors.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                _dateDisplay,
                                style: const TextStyle(
                                  color: AppColors.accentLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.billboardName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Legend Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'OCCUPIED / BOOKED',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tap slot to reserve',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                )
              else if (!_hasAvailableTimeSlots)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No available time slots.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _timeSlots.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                  ),
                  itemBuilder: (context, index) {
                    final slot = _timeSlots[index];
                    final bool isFree = slot['isFree'] == true;
                    final bool isSelected = _selectedSlotIndex == index && isFree;
                    final slotPrice = slot['price'] != null
                        ? (slot['price'] as num).toDouble()
                        : widget.hourlyRate;
                    final slotLabel = slot['label'] ?? 'Standard Broadcast';

                    return InkWell(
                      onTap: isFree
                          ? () => setState(() => _selectedSlotIndex = index)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isFree
                              ? (isSelected
                                  ? AppColors.accentPrimary.withValues(alpha: 0.9)
                                  : AppColors.cardDark)
                              : AppColors.inputBg.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFree
                                ? (isSelected
                                    ? Colors.white
                                    : const Color(0xFF10B981).withValues(alpha: 0.7))
                                : const Color(0xFFEF4444).withValues(alpha: 0.4),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accentPrimary.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Time and Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        isFree
                                            ? Icons.access_time_filled_rounded
                                            : Icons.lock_clock_rounded,
                                        color: isFree
                                            ? (isSelected
                                                ? Colors.white
                                                : const Color(0xFF10B981))
                                            : const Color(0xFFEF4444),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          slot['time'] ?? '',
                                          style: TextStyle(
                                            color: isFree ? Colors.white : AppColors.textMuted,
                                            fontWeight: isSelected || !isFree
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? (isSelected
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : AppColors.accentPrimary.withValues(alpha: 0.2))
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${slotPrice.toStringAsFixed(0)} FCFA',
                                    style: TextStyle(
                                      color: isFree
                                          ? (isSelected ? Colors.white : AppColors.accentLight)
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Row: Tier Label and Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    slotLabel,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isFree
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isFree ? 'AVAILABLE' : (slot['occupant'] ?? 'OCCUPIED'),
                                    style: TextStyle(
                                      color: isFree ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Total Summary & Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATTRIBUTED SLOT PRICE',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedSlotIndex >= 0
                                ? '${_calculatedPrice.toStringAsFixed(0)} FCFA'
                                : 'Select a slot',
                            style: const TextStyle(
                              color: AppColors.accentLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (_selectedSlotIndex >= 0)
                            Text(
                              'Selected: ${_timeSlots[_selectedSlotIndex]['time']} (${_timeSlots[_selectedSlotIndex]['label'] ?? ''})',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedSlotIndex < 0 ||
                              _selectedSlotIndex >= _timeSlots.length
                          ? null
                          : () {
                              final chosen = _timeSlots[_selectedSlotIndex];
                              widget.onSlotSelected(
                                chosen['time'],
                                _durationLabel,
                                _calculatedPrice,
                              );
                              Navigator.pop(context);
                            },
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'CONFIRM TIME SLOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedSlotIndex < 0
                            ? Colors.grey.shade800
                            : AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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


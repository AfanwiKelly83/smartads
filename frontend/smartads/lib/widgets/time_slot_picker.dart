import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';

class TimeSlotPickerModal extends StatefulWidget {
  final String billboardName;
  final double hourlyRate;
  final int? billboardId;
  final List<Map<String, dynamic>>? availableTimeSlots;
  final Function(String slotTime, String duration, double price) onSlotSelected;

  const TimeSlotPickerModal({
    super.key,
    required this.billboardName,
    required this.hourlyRate,
    this.billboardId,
    this.availableTimeSlots,
    required this.onSlotSelected,
  });

  @override
  State<TimeSlotPickerModal> createState() => _TimeSlotPickerModalState();
}

class _TimeSlotPickerModalState extends State<TimeSlotPickerModal> {
  // -1 means no slot has been tapped yet — avoids index-out-of-range
  // or Bad-state errors when the list loads with occupied first slots.
  int _selectedSlotIndex = -1;

  final List<Map<String, dynamic>> _defaultTimeSlots = [
    {'time': '08:00 AM - 09:00 AM', 'isFree': true, 'occupant': null},
    {
      'time': '09:00 AM - 10:00 AM',
      'isFree': false,
      'occupant': 'Reserved (Orange Campaign)',
    },
    {'time': '10:00 AM - 11:00 AM', 'isFree': true, 'occupant': null},
    {'time': '11:00 AM - 12:00 PM', 'isFree': true, 'occupant': null},
    {
      'time': '12:00 PM - 01:00 PM',
      'isFree': false,
      'occupant': 'Reserved (MTN MoMo)',
    },
    {'time': '01:00 PM - 02:00 PM', 'isFree': true, 'occupant': null},
    {'time': '02:00 PM - 03:00 PM', 'isFree': true, 'occupant': null},
    {
      'time': '03:00 PM - 04:00 PM',
      'isFree': false,
      'occupant': 'Reserved (Tech Expo)',
    },
    {'time': '04:00 PM - 05:00 PM', 'isFree': true, 'occupant': null},
    {'time': '05:00 PM - 06:00 PM', 'isFree': true, 'occupant': null},
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
      );
      if (!mounted) return;
      setState(() => _timeSlots = slots);
    } catch (_) {
      // Keep the demo slots visible if the server is temporarily unavailable.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double? get _selectedDurationHours {
    if (_selectedSlotIndex < 0 || _selectedSlotIndex >= _timeSlots.length) {
      return null;
    }
    return _parseDurationHours(
      _timeSlots[_selectedSlotIndex]['time']?.toString(),
    );
  }

  double get _calculatedPrice =>
      widget.hourlyRate * (_selectedDurationHours ?? 0);

  String get _durationLabel {
    final hours = _selectedDurationHours;
    if (hours == null || hours <= 0) return 'Not selected';
    return '${hours == hours.roundToDouble() ? hours.toInt() : hours.toStringAsFixed(2)} ${hours == 1 ? 'hour' : 'hours'}';
  }

  double? _parseDurationHours(String? slot) {
    if (slot == null) return null;
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*([AP]M)?\s*-\s*(\d{1,2}):(\d{2})\s*([AP]M)?\s*$',
      caseSensitive: false,
    ).firstMatch(slot);
    if (match == null) return null;

    int toMinutes(String hourText, String minuteText, String? meridiem) {
      var hour = int.parse(hourText);
      final minute = int.parse(minuteText);
      if (meridiem != null) {
        final isPm = meridiem.toUpperCase() == 'PM';
        if (hour == 12) hour = 0;
        if (isPm) hour += 12;
      }
      return hour * 60 + minute;
    }

    final start = toMinutes(match.group(1)!, match.group(2)!, match.group(3));
    final end = toMinutes(match.group(4)!, match.group(5)!, match.group(6));
    final durationMinutes = end - start;
    if (durationMinutes <= 0) return null;
    return durationMinutes / 60;
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
        width: MediaQuery.sizeOf(context).width * 0.92,
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
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
                        const Text(
                          'TIME SLOT AVAILABILITY & PRICING',
                          style: TextStyle(
                            color: AppColors.accentPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.billboardName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
              const SizedBox(height: 20),

              // Time slots determine the booking duration and price.
              const Text(
                'SELECT AVAILABLE FREE TIME SLOT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Legend Indicator
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '🟢 FREE / AVAILABLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '🔴 OCCUPIED / BOOKED',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                    ),
                  ),
                )
              else if (!_hasAvailableTimeSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No available time slots.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final slot = _timeSlots[index];
                    final bool isFree = slot['isFree'] == true;
                    final bool isSelected =
                        _selectedSlotIndex == index && isFree;

                    return InkWell(
                      onTap: isFree
                          ? () => setState(() => _selectedSlotIndex = index)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isFree
                              ? (isSelected
                                    ? AppColors.accentPrimary
                                    : AppColors.cardDark)
                              : AppColors.inputBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFree
                                ? (isSelected
                                      ? AppColors.accentPrimary
                                      : const Color(0xFF10B981))
                                : const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.4),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    slot['time'],
                                    style: TextStyle(
                                      color: isFree
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: isSelected || !isFree
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFree
                                  ? 'AVAILABLE NOW'
                                  : (slot['occupant'] ?? 'OCCUPIED'),
                              style: TextStyle(
                                color: isFree
                                    ? (isSelected
                                          ? Colors.white70
                                          : const Color(0xFF10B981))
                                    : const Color(0xFFEF4444),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Total Summary & Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL CALCULATED RATE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_calculatedPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Price per hour: ${widget.hourlyRate.toStringAsFixed(0)} FCFA\nDuration: $_durationLabel',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    ElevatedButton.icon(
                      // Disabled until user taps a FREE slot
                      onPressed:
                          _selectedSlotIndex < 0 ||
                              _selectedSlotIndex >= _timeSlots.length
                          ? null
                          : () {
                              widget.onSlotSelected(
                                _timeSlots[_selectedSlotIndex]['time'],
                                _durationLabel,
                                _calculatedPrice,
                              );
                              Navigator.pop(context);
                            },
                      icon: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CONFIRM TIME SLOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedSlotIndex < 0
                            ? Colors.grey
                            : AppColors.accentPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
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

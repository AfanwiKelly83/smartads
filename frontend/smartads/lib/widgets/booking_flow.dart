import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/billboard_model.dart';
import '../services/advertisement_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/advertisement_model.dart';
import 'payment_modal.dart';
import '../theme/app_theme.dart';
import '../utils/app_colors.dart';
import 'primary_button.dart';

class BookingFlowDialog extends StatefulWidget {
  final BillboardModel billboard;
  final bool canManageAds;

  const BookingFlowDialog({
    super.key,
    required this.billboard,
    this.canManageAds = true,
  });

  @override
  State<BookingFlowDialog> createState() => _BookingFlowDialogState();
}

class _BookingFlowDialogState extends State<BookingFlowDialog> {
  int _step = 1;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  bool _isLoadingCapacity = false;
  AdvertisementModel? _uploadedAd;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  int _selectedPresetDays = 3;

  int _maxCapacity = 10;
  int _occupiedCapacity = 0;
  int _remainingCapacity = 10;
  bool _isCapacityAvailable = true;

  int _selectedSlotIndex = -1;
  String? _selectedSlot;
  String? _selectedSlotStartTime;
  String? _selectedSlotEndTime;
  String? _selectedSlotDuration;
  String? _selectedSlotLabel;
  double? _calculatedPrice;

  final List<Map<String, dynamic>> _defaultTimeSlots = [
    {
      'time': 'Full Day Dynamic Rotation (All Hours)',
      'startTime': '00:00',
      'endTime': '23:59',
      'label': 'Fair Shared Broadcast (Round-Robin)',
      'tier': 'PRIME',
      'price': 40000.0,
      'duration': 'Full Day',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '06:00 AM - 07:00 AM',
      'startTime': '06:00',
      'endTime': '07:00',
      'label': 'Early Bird (Off-Peak)',
      'tier': 'OFF_PEAK',
      'price': 2000.0,
      'duration': '1 Hour',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '07:00 AM - 08:00 AM',
      'startTime': '07:00',
      'endTime': '08:00',
      'label': 'Morning Commute',
      'tier': 'STANDARD',
      'price': 3500.0,
      'duration': '1 Hour',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '08:00 AM - 10:00 AM',
      'startTime': '08:00',
      'endTime': '10:00',
      'label': 'Morning Prime Rush',
      'tier': 'PRIME',
      'price': 6000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '10:00 AM - 12:00 PM',
      'startTime': '10:00',
      'endTime': '12:00',
      'label': 'Mid-Day Business',
      'tier': 'STANDARD',
      'price': 5000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '12:00 PM - 02:00 PM',
      'startTime': '12:00',
      'endTime': '14:00',
      'label': 'Lunch Peak',
      'tier': 'PRIME',
      'price': 6500.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '02:00 PM - 04:00 PM',
      'startTime': '14:00',
      'endTime': '16:00',
      'label': 'Afternoon Broadcast',
      'tier': 'STANDARD',
      'price': 4500.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '04:00 PM - 06:00 PM',
      'startTime': '16:00',
      'endTime': '18:00',
      'label': 'Evening Commute Rush',
      'tier': 'PRIME',
      'price': 7000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '06:00 PM - 08:00 PM',
      'startTime': '18:00',
      'endTime': '20:00',
      'label': 'Evening Prime Peak',
      'tier': 'MEGA_PRIME',
      'price': 8000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '08:00 PM - 10:00 PM',
      'startTime': '20:00',
      'endTime': '22:00',
      'label': 'Night Life Prime',
      'tier': 'PRIME',
      'price': 5000.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
    {
      'time': '10:00 PM - 12:00 AM',
      'startTime': '22:00',
      'endTime': '23:59',
      'label': 'Late Night (Off-Peak)',
      'tier': 'OFF_PEAK',
      'price': 2500.0,
      'duration': '2 Hours',
      'isFree': true,
      'occupant': null,
    },
  ];

  late List<Map<String, dynamic>> _timeSlots;

  String _mediaType = 'IMAGE';
  String? _fileName;
  String? _error;
  final _titleController = TextEditingController();

  int get _campaignDays {
    final diff = _endDate.difference(_startDate).inDays;
    return diff >= 0 ? diff + 1 : 1;
  }

  double get _computedTotalPrice {
    if (_calculatedPrice != null) {
      return _calculatedPrice! * _campaignDays;
    }
    final dailyBase = widget.billboard.hourlyRate * 4;
    return dailyBase * _campaignDays;
  }

  @override
  void initState() {
    super.initState();
    _maxCapacity = widget.billboard.maxActiveCampaigns;
    _remainingCapacity = _maxCapacity;
    _timeSlots = List.from(_defaultTimeSlots);
    _loadCapacityAndAvailability();
  }

  void _next() => setState(() {
        _error = null;
        _step += 1;
      });

  void _prev() => setState(() {
        _error = null;
        if (_step > 1) _step -= 1;
      });

  Future<void> _loadCapacityAndAvailability() async {
    setState(() {
      _isLoadingCapacity = true;
      _isLoadingSlots = true;
    });

    try {
      final capData = await ApiService().getBillboardCapacity(
        billboardId: widget.billboard.billboardId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      setState(() {
        _maxCapacity = capData['maxActiveCampaigns'] ?? widget.billboard.maxActiveCampaigns;
        _occupiedCapacity = capData['occupiedCampaignsCount'] ?? 0;
        _remainingCapacity = capData['remainingCapacity'] ?? (_maxCapacity - _occupiedCapacity);
        _isCapacityAvailable = capData['isAvailable'] ?? (_remainingCapacity > 0);
      });

      final slots = await ApiService().getBillboardAvailability(
        billboardId: widget.billboard.billboardId,
        date: _startDate,
      );

      if (!mounted) return;
      if (slots.isNotEmpty) {
        setState(() {
          _timeSlots = slots;
        });
      }
    } catch (_) {
      // Keep fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCapacity = false;
          _isLoadingSlots = false;
        });
      }
    }
  }

  void _selectPresetDays(int days) {
    setState(() {
      _selectedPresetDays = days;
      _endDate = _startDate.add(Duration(days: days - 1));
    });
    _loadCapacityAndAvailability();
  }

  Future<void> _uploadAd() async {
    if (_titleController.text.trim().isEmpty || _fileName == null) {
      setState(() => _error = 'Please provide an ad title and select a file.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ad = await AdvertisementService().uploadAdvertisement(
        title: _titleController.text.trim(),
        mediaType: _mediaType,
      );
      setState(() {
        _uploadedAd = ad;
      });
      _next();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_uploadedAd == null) {
      setState(() => _error = 'Missing advertisement creative');
      return;
    }

    if (!_isCapacityAvailable) {
      setState(() => _error = 'Billboard capacity is full for the selected dates. Please choose another date range.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final body = {
        'billboardId': widget.billboard.billboardId,
        'campaignId': 1,
        'advertisementId': _uploadedAd!.advertisementId,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate.toIso8601String().split('T')[0],
        'startTime': _selectedSlotStartTime ?? '00:00',
        'endTime': _selectedSlotEndTime ?? '23:59',
        'amount': _computedTotalPrice,
      };

      final res = await ApiService().post(ApiConfig.bookings, body);

      setState(() => _isLoading = false);

      if (res != null && res['success'] == true) {
        final bookingId = res['data']['bookingId'];

        if (!mounted) return;

        final paymentResult = await showDialog<bool>(
          context: context,
          builder: (context) => PaymentModal(
            bookingId: bookingId,
            amount: _computedTotalPrice,
            itemTitle:
                '${widget.billboard.billboardName} ($_campaignDays Days Campaign)',
          ),
        );

        if (paymentResult == true) {
          if (!mounted) return;
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _error = res?['message'] ?? 'Booking failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _buildStep1Date() {
    final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 1 — Campaign Period & Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select your broadcast schedule. Digital billboards rotate up to 10 concurrent campaigns in round-robin sequence.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Quick preset duration buttons
        const Text(
          'POPULAR CAMPAIGN DURATIONS',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 3, 7, 14, 30].map((days) {
            final isSelected = _selectedPresetDays == days;
            final label = days == 1 ? '1 Day' : days == 7 ? '1 Week' : days == 14 ? '2 Weeks' : days == 30 ? '1 Month (30d)' : '$days Days';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.accentPrimary,
              backgroundColor: AppColors.cardDark,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) _selectPresetDays(days);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Date selection cards
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('START DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setState(() {
                                _startDate = picked;
                                if (_endDate.isBefore(_startDate)) {
                                  _endDate = _startDate.add(Duration(days: _selectedPresetDays - 1));
                                }
                              });
                              _loadCapacityAndAvailability();
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.accentLight),
                                const SizedBox(width: 8),
                                Text(startStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('END DATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: _startDate.add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() {
                                _endDate = picked;
                                _selectedPresetDays = _endDate.difference(_startDate).inDays + 1;
                              });
                              _loadCapacityAndAvailability();
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.accentLight),
                                const SizedBox(width: 8),
                                Text(endStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: $_campaignDays ${_campaignDays == 1 ? "Day" : "Days"}',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Estimated Cost: ${_computedTotalPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: 'CONTINUE TO CAPACITY OVERVIEW',
          onPressed: () {
            _loadCapacityAndAvailability();
            _next();
          },
        ),
      ],
    );
  }

  Widget _buildStep2Time() {
    final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';
    final double occupancyPercent = _maxCapacity > 0 ? (_occupiedCapacity / _maxCapacity).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STEP 2 — Live Capacity & Schedule',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentPrimary),
              ),
              child: Text(
                '$startStr → $endStr',
                style: const TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live Billboard Capacity Status Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isCapacityAvailable
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : const Color(0xFFEF4444).withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.layers_rounded,
                        color: _isCapacityAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SHARED ROTATION CAPACITY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isCapacityAvailable
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isCapacityAvailable
                          ? 'AVAILABLE ($_remainingCapacity SPACES LEFT)'
                          : 'CAPACITY FULL (0 SPACES LEFT)',
                      style: TextStyle(
                        color: _isCapacityAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: occupancyPercent,
                  minHeight: 8,
                  backgroundColor: AppColors.inputBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    occupancyPercent >= 1.0
                        ? const Color(0xFFEF4444)
                        : occupancyPercent > 0.7
                            ? Colors.amber
                            : const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_occupiedCapacity of $_maxCapacity active campaigns occupied',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '$_remainingCapacity spots open',
                    style: const TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Optional specific broadcast slot selection
        const Text(
          'BROADCAST TIME PREFERENCE (OPTIONAL)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (_isLoadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary),
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
              final bool isSelected = _selectedSlotIndex == index;
              final slotPrice = slot['price'] != null
                  ? (slot['price'] as num).toDouble()
                  : widget.billboard.hourlyRate;
              final slotLabel = slot['label'] ?? 'Standard Broadcast';

              return InkWell(
                onTap: isFree
                    ? () {
                        setState(() {
                          _selectedSlotIndex = index;
                          _selectedSlot = slot['time'];
                          _selectedSlotStartTime = slot['startTime'] ?? '00:00';
                          _selectedSlotEndTime = slot['endTime'] ?? '23:59';
                          _selectedSlotDuration = slot['duration'] ?? '$_campaignDays Days';
                          _selectedSlotLabel = slotLabel;
                          _calculatedPrice = slotPrice;
                          _error = null;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPrimary.withValues(alpha: 0.85)
                        : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (isFree
                              ? const Color(0xFF10B981).withValues(alpha: 0.6)
                              : const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              slot['time'] ?? '',
                              style: TextStyle(
                                color: isFree ? Colors.white : AppColors.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${slotPrice.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.accentLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              slotLabel,
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                                fontSize: 8.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            isFree ? 'OPEN' : 'BUSY',
                            style: TextStyle(
                              color: isFree ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
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
        const SizedBox(height: 16),

        // Campaign Pricing Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CAMPAIGN TOTAL RATE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_computedTotalPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$_campaignDays ${_campaignDays == 1 ? "Day" : "Days"} Broadcast',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(widget.billboard.hourlyRate * 4).toStringAsFixed(0)} FCFA / day',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            TextButton(
              onPressed: _prev,
              child: const Text(
                'Back',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'CONTINUE TO UPLOAD',
                onPressed: () {
                  if (!_isCapacityAvailable) {
                    setState(() => _error = 'This billboard is full for the selected dates. Please choose another date range.');
                    return;
                  }
                  _next();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  PlatformFile? _pickedFile;

  Future<void> _pickMediaFile() async {
    try {
      final FileType fileType =
          _mediaType == 'VIDEO' ? FileType.video : FileType.image;
      final file = await FilePicker.pickFile(
        type: fileType,
      );

      if (file != null) {
        setState(() {
          _pickedFile = file;
          _fileName = file.name;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not access device storage: $e');
    }
  }

  Widget _buildStep3Upload() {
    final int? fileSize = _pickedFile?.lengthSync();
    final String fileSizeText = fileSize != null
        ? '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'
        : (_pickedFile != null ? 'Selected' : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 3 — Upload Advertisement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Campaign / Ad Title *',
            hintText: 'e.g. Summer Promo 2026',
            filled: true,
            fillColor: AppTheme.inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ChoiceChip(
              label: const Text('IMAGE (.PNG, .JPG)'),
              selected: _mediaType == 'IMAGE',
              selectedColor: AppTheme.accentPrimary,
              onSelected: (v) {
                setState(() {
                  _mediaType = 'IMAGE';
                  _fileName = null;
                  _pickedFile = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('VIDEO (.MP4, .MOV)'),
              selected: _mediaType == 'VIDEO',
              selectedColor: AppTheme.accentPrimary,
              onSelected: (v) {
                setState(() {
                  _mediaType = 'VIDEO';
                  _fileName = null;
                  _pickedFile = null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Device Storage Picker Button / Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pickedFile != null
                  ? AppTheme.accentPrimary
                  : AppTheme.borderSubtle,
              width: _pickedFile != null ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _mediaType == 'VIDEO'
                    ? Icons.video_file_rounded
                    : Icons.image_rounded,
                size: 40,
                color: _pickedFile != null
                    ? AppTheme.accentLight
                    : AppTheme.textMuted,
              ),
              const SizedBox(height: 10),
              Text(
                _fileName ?? 'No $_mediaType file selected yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _pickedFile != null
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontWeight: _pickedFile != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              if (fileSizeText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'File Size: $fileSizeText',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _pickMediaFile,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text(
                  _pickedFile != null
                      ? 'CHOOSE DIFFERENT FILE'
                      : 'BROWSE DEVICE STORAGE',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            TextButton(
              onPressed: _prev,
              child: const Text(
                'Back',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'UPLOAD & CONTINUE',
                isLoading: _isLoading,
                onPressed: _uploadAd,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Summary() {
    final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 4 — Campaign & Booking Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billboard: ${widget.billboard.billboardName} (${widget.billboard.billboardCode.isNotEmpty ? widget.billboard.billboardCode : "BILL-${widget.billboard.billboardId}"})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule: $startStr → $endStr',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_campaignDays ${_campaignDays == 1 ? "Day" : "Days"} Campaign',
                      style: const TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Display Capacity: $_occupiedCapacity / $_maxCapacity occupied • Round-robin dynamic playlist',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              if (_selectedSlot != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Time Focus: $_selectedSlot (${_selectedSlotLabel ?? ''})',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
              const Divider(color: AppTheme.borderSubtle, height: 28),
              if (_uploadedAd != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ad Creative:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${_uploadedAd!.title} (${_uploadedAd!.mediaType})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _uploadedAd!.isAiApproved
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (_uploadedAd!.isAiFlagged
                            ? Colors.amber.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _uploadedAd!.isAiApproved
                          ? const Color(0xFF10B981)
                          : (_uploadedAd!.isAiFlagged
                              ? Colors.amber
                              : Colors.redAccent),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _uploadedAd!.isAiApproved
                            ? Icons.verified_rounded
                            : (_uploadedAd!.isAiFlagged
                                ? Icons.warning_amber_rounded
                                : Icons.cancel_outlined),
                        color: _uploadedAd!.isAiApproved
                            ? const Color(0xFF10B981)
                            : (_uploadedAd!.isAiFlagged
                                ? Colors.amber
                                : Colors.redAccent),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _uploadedAd!.isAiApproved
                                  ? 'Gemini AI Safety Check: APPROVED'
                                  : (_uploadedAd!.isAiFlagged
                                      ? 'Gemini AI: MANUAL REVIEW REQUIRED'
                                      : 'Gemini AI Safety Check: REJECTED'),
                              style: TextStyle(
                                color: _uploadedAd!.isAiApproved
                                    ? const Color(0xFF10B981)
                                    : (_uploadedAd!.isAiFlagged
                                        ? Colors.amber
                                        : Colors.redAccent),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Confidence score: ${(_uploadedAd!.aiConfidence * 100).toInt()}% • Policy compliant for digital screens',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL DUE:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_computedTotalPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      color: AppTheme.accentPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: _prev,
              child: const Text(
                'Back',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'CONTINUE TO PAYMENT',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep5Payment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 5 — Payment & Activation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Proceed to secure payment to confirm your booking and schedule your campaign rotation on the digital billboard.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: _prev,
              child: const Text(
                'Back',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'PAY ${_computedTotalPrice.toStringAsFixed(0)} FCFA NOW',
                isLoading: _isLoading,
                onPressed: _processPayment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.live_tv_rounded,
                        color: AppColors.accentPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Book Billboard Ad — ${widget.billboard.billboardName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              if (_step == 1) _buildStep1Date(),
              if (_step == 2) _buildStep2Time(),
              if (_step == 3) _buildStep3Upload(),
              if (_step == 4) _buildStep4Summary(),
              if (_step == 5) _buildStep5Payment(),
            ],
          ),
        ),
      ),
    );
  }
}

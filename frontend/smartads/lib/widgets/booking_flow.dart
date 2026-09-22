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
  AdvertisementModel? _uploadedAd;

  DateTime? _selectedDate = DateTime.now();
  int _selectedSlotIndex = -1;
  String? _selectedSlot;
  String? _selectedSlotStartTime;
  String? _selectedSlotEndTime;
  String? _selectedSlotDuration;
  String? _selectedSlotLabel;
  double? _calculatedPrice;

  final List<Map<String, dynamic>> _defaultTimeSlots = [
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
      'isFree': false,
      'occupant': 'Reserved (Orange Campaign)',
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
      'isFree': false,
      'occupant': 'Reserved (MTN MoMo)',
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
      'isFree': false,
      'occupant': 'Reserved (Tech Expo)',
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

  @override
  void initState() {
    super.initState();
    _timeSlots = List.from(_defaultTimeSlots);
  }

  void _next() => setState(() {
        _error = null;
        _step += 1;
      });

  void _prev() => setState(() {
        _error = null;
        if (_step > 1) _step -= 1;
      });

  Future<void> _loadAvailability() async {
    if (_selectedDate == null) return;
    setState(() => _isLoadingSlots = true);
    try {
      final slots = await ApiService().getBillboardAvailability(
        billboardId: widget.billboard.billboardId,
        date: _selectedDate,
      );
      if (!mounted) return;
      if (slots.isNotEmpty) {
        setState(() {
          _timeSlots = slots;
          _selectedSlotIndex = -1;
          _selectedSlot = null;
          _calculatedPrice = null;
        });
      }
    } catch (_) {
      // Fallback to default slots
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
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
    if (_uploadedAd == null || _selectedDate == null || _selectedSlot == null) {
      setState(() => _error = 'Missing booking details');
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
        'startDate': _selectedDate!.toIso8601String().split('T')[0],
        'endDate': _selectedDate!.toIso8601String().split('T')[0],
        'startTime': _selectedSlotStartTime ?? '08:00',
        'endTime': _selectedSlotEndTime ?? '10:00',
        'amount': _calculatedPrice,
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
            amount: _calculatedPrice ?? (widget.billboard.hourlyRate * 2),
            itemTitle:
                '${widget.billboard.billboardName} | ${_selectedSlot ?? ''}',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 1 — Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          padding: const EdgeInsets.all(8),
          child: CalendarDatePicker(
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            onDateChanged: (date) {
              setState(() => _selectedDate = date);
            },
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'CONTINUE TO TIME SLOTS',
          onPressed: () {
            if (_selectedDate != null) {
              _loadAvailability();
              _next();
            } else {
              setState(() => _error = 'Please select a date');
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2Time() {
    final dateStr = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padStart(2, '0')}-${_selectedDate!.day.toString().padStart(2, '0')}'
        : 'Today';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STEP 2 — Select Time Slot & Attributed Price',
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
                dateStr,
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

        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.3),
            ),
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
              const SizedBox(width: 18),
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
                'Select free slot',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_isLoadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
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
              final bool isSelected = _selectedSlotIndex == index && isFree;
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
                          _selectedSlotStartTime = slot['startTime'] ??
                              (slot['time']?.toString().split(' - ')[0] ??
                                  '08:00');
                          _selectedSlotEndTime = slot['endTime'] ??
                              (slot['time']?.toString().split(' - ')[1] ??
                                  '10:00');
                          _selectedSlotDuration =
                              slot['duration'] ?? 'Standard';
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
                    color: isFree
                        ? (isSelected
                            ? AppColors.accentPrimary.withValues(alpha: 0.85)
                            : AppColors.cardDark)
                        : AppColors.inputBg.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFree
                          ? (isSelected
                              ? Colors.white
                              : const Color(0xFF10B981)
                                  .withValues(alpha: 0.7))
                          : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentPrimary
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
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
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    slot['time'] ?? '',
                                    style: TextStyle(
                                      color: isFree
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: isSelected || !isFree
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? (isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : AppColors.accentPrimary
                                          .withValues(alpha: 0.2))
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${slotPrice.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                color: isFree
                                    ? (isSelected
                                        ? Colors.white
                                        : AppColors.accentLight)
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom Row: Tier Label and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              slotLabel,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.2)
                                  : const Color(0xFFEF4444)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isFree
                                  ? 'AVAILABLE'
                                  : (slot['occupant'] ?? 'OCCUPIED'),
                              style: TextStyle(
                                color: isFree
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 7.5,
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
        const SizedBox(height: 16),

        // Price preview banner
        if (_selectedSlotIndex >= 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      'ATTRIBUTED SLOT PRICE',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_calculatedPrice?.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_selectedSlot ?? ''} (${_selectedSlotLabel ?? ''})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
                  if (_selectedSlot != null) {
                    _next();
                  } else {
                    setState(
                      () => _error =
                          'Please select an available time slot to continue',
                    );
                  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STEP 4 — Booking Summary',
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
                'Billboard: ${widget.billboard.billboardName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${_selectedDate?.toIso8601String().split('T')[0]}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Time Slot: $_selectedSlot (${_selectedSlotLabel ?? ''})',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${_selectedSlotDuration ?? '2 Hours'}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
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
                const SizedBox(height: 12),
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
                    '${_calculatedPrice?.toStringAsFixed(0)} FCFA',
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
          'STEP 5 — Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Proceed to secure payment to confirm your booking and schedule the advertisement on the digital billboard.',
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
                text:
                    'PAY ${_calculatedPrice != null ? "${_calculatedPrice!.toStringAsFixed(0)} FCFA" : "NOW"}',
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

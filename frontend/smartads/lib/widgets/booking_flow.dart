import 'package:flutter/material.dart';
import '../models/billboard_model.dart';
import '../services/advertisement_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/advertisement_model.dart';
import 'time_slot_picker.dart';
import 'payment_modal.dart';
import '../theme/app_theme.dart';
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
  AdvertisementModel? _uploadedAd;
  
  DateTime? _selectedDate;
  String? _selectedSlot;
  String? _selectedDuration = '2 hours';
  double? _calculatedPrice;
  
  String _mediaType = 'IMAGE';
  String? _fileName;
  String? _error;
  final _titleController = TextEditingController();

  void _next() => setState(() { _error = null; _step += 1; });
  void _prev() => setState(() { _error = null; if (_step > 1) _step -= 1; });

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
    
    setState(() { _isLoading = true; _error = null; });
    
    try {
      final body = {
        'billboardId': widget.billboard.billboardId,
        'campaignId': 1,
        'advertisementId': _uploadedAd!.advertisementId,
        'startDate': _selectedDate!.toIso8601String().split('T')[0],
        'endDate': _selectedDate!.toIso8601String().split('T')[0],
        'startTime': _selectedSlot?.split(' - ')[0] ?? '08:00',
        'endTime': _selectedSlot?.split(' - ')[1] ?? '10:00',
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
            itemTitle: '\ | \',
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
        const Text('STEP 1 — Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onDateChanged: (date) {
            setState(() => _selectedDate = date);
          },
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'CONTINUE',
          onPressed: () {
            if (_selectedDate != null) {
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
    final slots = [
      '08:00 - 10:00',
      '10:00 - 12:00',
      '12:00 - 14:00',
      '14:00 - 16:00',
      '16:00 - 18:00',
      '18:00 - 20:00',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 2 — Select Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return ChoiceChip(
              label: Text(slot),
              selected: isSelected,
              selectedColor: AppTheme.accentPrimary,
              onSelected: (val) {
                setState(() {
                  _selectedSlot = slot;
                  _calculatedPrice = widget.billboard.hourlyRate * 2; // Fixed 2-hour slots for demo
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: _prev, child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary))),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'CONTINUE',
                onPressed: () {
                  if (_selectedSlot != null) {
                    _next();
                  } else {
                    setState(() => _error = 'Please select a time slot');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Upload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STEP 3 — Upload Advertisement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Ad Title'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ChoiceChip(
              label: const Text('IMAGE'),
              selected: _mediaType == 'IMAGE',
              selectedColor: AppTheme.accentPrimary,
              onSelected: (v) => setState(() => _mediaType = 'IMAGE'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('VIDEO'),
              selected: _mediaType == 'VIDEO',
              selectedColor: AppTheme.accentPrimary,
              onSelected: (v) => setState(() => _mediaType = 'VIDEO'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => setState(() => _fileName = 'selected_ad_file.\'),
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(_fileName ?? 'SELECT \'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: const BorderSide(color: AppTheme.accentPrimary),
            foregroundColor: Colors.white
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: _prev, child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary))),
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
        const Text('STEP 4 — Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
              Text('Billboard: \', style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Date: \', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Time: \', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Duration: \', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Price: \ FCFA/hour', style: const TextStyle(color: AppTheme.textSecondary)),
              const Divider(color: AppTheme.borderSubtle, height: 32),
              Text('Total: \ FCFA', style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: _prev, child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary))),
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
        const Text('STEP 5 — Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        const Text('Proceed to secure payment to confirm your booking and schedule the advertisement.', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: _prev, child: const Text('Back', style: TextStyle(color: AppTheme.textSecondary))),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'PAY NOW',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Book Advertisement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
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

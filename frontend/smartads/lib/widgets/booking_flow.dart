import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/billboard_model.dart';
import '../services/advertisement_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/advertisement_model.dart';
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
            itemTitle: '${widget.billboard.billboardName} | ${_selectedSlot ?? ''}',
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
                  color: _pickedFile != null ? Colors.white : AppTheme.textSecondary,
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
              Text('Billboard: ${widget.billboard.billboardName}', style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Date: ${_selectedDate?.toIso8601String().split('T')[0]}', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Time: $_selectedSlot', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Duration: 2 hours', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Text('Price: ${widget.billboard.hourlyRate} FCFA/hour', style: const TextStyle(color: AppTheme.textSecondary)),
              const Divider(color: AppTheme.borderSubtle, height: 32),
              if (_uploadedAd != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ad Creative:', style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      '${_uploadedAd!.title} (${_uploadedAd!.mediaType})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _uploadedAd!.isAiApproved
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (_uploadedAd!.isAiFlagged ? Colors.amber.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _uploadedAd!.isAiApproved
                          ? const Color(0xFF10B981)
                          : (_uploadedAd!.isAiFlagged ? Colors.amber : Colors.redAccent),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _uploadedAd!.isAiApproved
                            ? Icons.verified_rounded
                            : (_uploadedAd!.isAiFlagged ? Icons.warning_amber_rounded : Icons.cancel_outlined),
                        color: _uploadedAd!.isAiApproved
                            ? const Color(0xFF10B981)
                            : (_uploadedAd!.isAiFlagged ? Colors.amber : Colors.redAccent),
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
                                    : (_uploadedAd!.isAiFlagged ? Colors.amber : Colors.redAccent),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Confidence score: ${(_uploadedAd!.aiConfidence * 100).toInt()}% • Policy compliant for digital screens',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Total: ${_calculatedPrice?.toStringAsFixed(0)} FCFA', style: const TextStyle(color: AppTheme.accentPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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

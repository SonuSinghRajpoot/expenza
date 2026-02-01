import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/utils/image_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../core/constants/expense_constants.dart';
import 'package:collection/collection.dart';
import '../../services/gemini_service.dart';
import '../../data/repositories/gemini_repository.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/error_handler.dart';
import '../../core/utils/permission_utils.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final int tripId;
  final Expense? expense;
  final String? initialHead;
  final String? initialSubHead;
  final Map<String, dynamic>? initialData;

  const ExpenseFormScreen({
    super.key,
    required this.tripId,
    this.expense,
    this.initialHead,
    this.initialSubHead,
    this.initialData,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _cityController;
  late TextEditingController _toCityController;
  late TextEditingController _notesController;
  late TextEditingController _paxController;

  String _selectedHead = 'Food';

  String? _selectedSubHead;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<String> _billPaths = []; // Multiple bill images/pages

  bool get _showPaxField =>
      _selectedHead == 'Accommodation' ||
      _selectedHead == 'Travel' ||
      _selectedHead == 'Food';

  @override
  void initState() {
    super.initState();
    String amountText = '';
    String cityText = '';
    String toCityText = '';
    String notesText = '';
    String paxText = '1';

    if (widget.expense != null) {
      amountText = widget.expense!.amount.toString();
      cityText = widget.expense!.city;
      toCityText = widget.expense!.toCity ?? '';
      cityText = widget.expense!.city;
      toCityText = widget.expense!.toCity ?? '';
      notesText = widget.expense!.notes ?? '';
      paxText = widget.expense!.pax?.toString() ?? '1';
      _selectedHead = widget.expense!.head;
      _selectedSubHead = widget.expense!.subHead; // Restore subHead
      _startDate = widget.expense!.startDate;
      _endDate = widget.expense!.endDate;
      _billPaths = List<String>.from(widget.expense!.billPaths);
    } else if (widget.initialData != null) {
      final data = widget.initialData!;
      amountText = data['amount']?.toString() ?? '';
      cityText = data['fromCity'] ?? data['city'] ?? '';
      toCityText = data['toCity'] ?? cityText;
      notesText = data['notes'] ?? '';

      // Normalize Category mapping from AI
      final aiHead = data['head']?.toString();
      if (aiHead != null) {
        final matchedHead = ExpenseConstants.heads.firstWhere(
          (h) => h.toLowerCase() == aiHead.toLowerCase(),
          orElse: () => _selectedHead,
        );
        _selectedHead = matchedHead;
      }

      // Normalize Sub-category mapping from AI
      final aiSubHead = data['subHead']?.toString();
      if (aiSubHead != null) {
        final subs = ExpenseConstants.subHeads[_selectedHead] ?? [];
        final matchedSub = subs
            .where((s) => s.toLowerCase() == aiSubHead.toLowerCase())
            .firstOrNull;
        _selectedSubHead = matchedSub;
      }

      if (data['date'] != null) {
        try {
          _startDate = DateTime.parse(data['date']);
          _endDate = _startDate; // Default matches start
        } catch (_) {}
      }
      if (data['endDate'] != null) {
        try {
          _endDate = DateTime.parse(data['endDate']);
        } catch (_) {}
      }
      // Note: Dates from initialData will be clamped in post-frame callback
      if (data['billPaths'] != null) {
        _billPaths = List<String>.from(data['billPaths']);
      } else if (data['billPath'] != null) {
        _billPaths = [data['billPath']];
      }
    } else if (widget.initialHead != null) {
      _selectedHead = widget.initialHead!;
      if (widget.initialSubHead != null) {
        _selectedSubHead = widget.initialSubHead;
      }
    }

    _amountController = TextEditingController(text: amountText);
    _cityController = TextEditingController(text: cityText);
    _toCityController = TextEditingController(text: toCityText);
    _notesController = TextEditingController(text: notesText);
    _paxController = TextEditingController(text: paxText);

    // Ensure default dates are within trip date range
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripsAsync = ref.read(tripListProvider);
      tripsAsync.whenData((trips) {
        final trip = trips.where((t) => t.id == widget.tripId).firstOrNull;
        if (trip != null && widget.expense == null) {
          // Clamp dates to trip range (for both new expenses and initialData)
          setState(() {
            _startDate = _clampDateToTripRange(_startDate, trip);
            _endDate = _clampDateToTripRange(_endDate, trip);
            // Ensure end date is not before start date
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate;
            }
          });
        }
      });

      // Check for auto-analyze from sharing
      if (widget.initialData?['autoAnalyze'] == true && _billPaths.isNotEmpty) {
        _analyzeSharedFiles();
      }
    });
  }

  Future<void> _analyzeSharedFiles() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final geminiRepo = GeminiRepository();
      final keys = await geminiRepo.getKeys();
      final activeKey = keys.firstWhereOrNull((k) => k.isActive);

      if (activeKey == null) {
        if (mounted) {
          Navigator.pop(context); // Pop loader
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active Gemini API Key found.')),
          );
        }
        return;
      }

      // Get trip to access cities
      final tripsAsync = ref.read(tripListProvider);
      final trip = tripsAsync.maybeWhen(
        data: (trips) => trips.firstWhereOrNull((t) => t.id == widget.tripId),
        orElse: () => null,
      );
      final tripCities = trip?.cities ?? [];

      final geminiService = GeminiService();
      // Send first 2 pages (e.g. PDF) so from/to can be read from itinerary
      final result = await geminiService.analyzeBill(
        apiKey: activeKey.apiKey,
        imagePaths: _billPaths.take(2).toList(),
        availableHeads: ExpenseConstants.heads,
        availableSubHeads: ExpenseConstants.subHeads,
        tripLocations: tripCities,
      );

      if (mounted) {
        Navigator.pop(context); // Pop loader

        if (result != null) {
          setState(() {
            if (result['amount'] != null) {
              _amountController.text = result['amount'].toString();
            }
            if (result['date'] != null) {
              try {
                final parsedDate = DateTime.parse(result['date']);
                if (trip != null) {
                  _startDate = _clampDateToTripRange(parsedDate, trip);
                  _endDate = _startDate;
                } else {
                  _startDate = parsedDate;
                  _endDate = _startDate;
                }
              } catch (_) {}
            }
            if (result['endDate'] != null) {
              try {
                final parsedEndDate = DateTime.parse(result['endDate']);
                if (trip != null) {
                  _endDate = _clampDateToTripRange(parsedEndDate, trip);
                  // Ensure end date is not before start date
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate;
                  }
                } else {
                  _endDate = parsedEndDate;
                }
              } catch (_) {}
            }
            if (result['head'] != null) {
              final matchedHead = ExpenseConstants.heads.firstWhere(
                (h) =>
                    h.toLowerCase() == result['head'].toString().toLowerCase(),
                orElse: () => _selectedHead,
              );
              _selectedHead = matchedHead;
            }
            if (result['subHead'] != null) {
              final subs = ExpenseConstants.subHeads[_selectedHead] ?? [];
              final matchedSub = subs.firstWhereOrNull(
                (s) =>
                    s.toLowerCase() ==
                    result['subHead'].toString().toLowerCase(),
              );
              _selectedSubHead = matchedSub;
            }
            if (result['fromCity'] != null) {
              _cityController.text = result['fromCity'];
            }
            if (result['toCity'] != null) {
              _toCityController.text = result['toCity'];
            } else if (_cityController.text.isNotEmpty) {
              _toCityController.text = _cityController.text;
            }
            _notesController.text =
                GeminiService.buildNotesFromExtractedFields(result);
            if (result['pax'] != null) {
              _paxController.text = result['pax'].toString();
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill analyzed successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not analyze the document.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loader
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cityController.dispose();
    _toCityController.dispose();
    _notesController.dispose();
    _paxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripListProvider);
    final trip = tripsAsync.maybeWhen(
      data: (trips) => trips.firstWhere((t) => t.id == widget.tripId),
      orElse: () => null,
    );
    final tripCities = trip?.cities ?? [];

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add Expense' : 'Edit Expense'),
        actions: [
          if (widget.expense != null)
            IconButton(
              onPressed: _deleteExpense,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppDesign.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                  label: 'Expense Head',
                  value: _selectedHead,
                  items: ExpenseConstants.heads,
                  onChanged: (val) {
                    setState(() {
                      _selectedHead = val!;
                      _selectedSubHead = null; // Reset subhead
                      final showPax = val == 'Accommodation' ||
                          val == 'Travel' ||
                          val == 'Food';
                      if (showPax) {
                        final n = int.tryParse(_paxController.text);
                        if (_paxController.text.isEmpty ||
                            n == null ||
                            n < 1) {
                          _paxController.text = '1';
                        }
                      }
                    });
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const Gap(16),
                if (ExpenseConstants.subHeads[_selectedHead] != null)
                  _buildDropdown(
                    key: ValueKey('subhead_$_selectedHead'),
                    label: 'Sub Head',
                    value: _selectedSubHead,
                    items: ExpenseConstants.subHeads[_selectedHead]!,
                    onChanged: (val) => setState(() => _selectedSubHead = val),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                if (ExpenseConstants.subHeads[_selectedHead] != null)
                  const Gap(16),
                _buildDatePicker(
                  label: 'Start Date',
                  date: _startDate,
                  onTap: () => _pickDate(true),
                ),
                const Gap(16),
                _buildDatePicker(
                  label: 'End Date',
                  date: _endDate,
                  onTap: () => _pickDate(false),
                ),
                const Gap(16),
                if (_selectedHead == 'Travel') ...[
                  _buildCityDropdown(tripCities, true),
                  const Gap(16),
                  _buildCityDropdown(tripCities, false),
                ] else ...[
                  _buildCityDropdown(tripCities, true),
                ],
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      flex: _showPaxField ? 2 : 1,
                      child: TextFormField(
                        controller: _amountController,
                        decoration: _inputDecoration('Amount', prefix: '₹ '),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    if (_showPaxField) ...[
                      const Gap(12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _paxController,
                          decoration: _inputDecoration('Pax', prefix: '')
                              .copyWith(
                                suffixIcon: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final current =
                                            int.tryParse(_paxController.text) ??
                                            1;
                                        _paxController.text =
                                            (current + 1).toString();
                                        setState(() {});
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_up,
                                        size: 20,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        final current =
                                            int.tryParse(_paxController.text) ??
                                            1;
                                        if (current > 1) {
                                          _paxController.text =
                                              (current - 1).toString();
                                          setState(() {});
                                        }
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (val) {
                            if (!_showPaxField) return null;
                            if (val == null || val.isEmpty) return 'Required';
                            final n = int.tryParse(val);
                            if (n == null || n < 1) return 'Min 1';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(16),
                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('Notes (Optional)'),
                  maxLines: 2,
                ),
                const Gap(16),
                _buildSectionHeader('Evidence'),
                _buildEvidenceList(),
                const Gap(16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppDesign.borderDefault),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _saveExpense,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                    ),
                  ),
                  child: const Text(
                    'Save Expense',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: true,
      fillColor: AppDesign.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        borderSide: const BorderSide(color: AppDesign.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        borderSide: const BorderSide(color: AppDesign.borderDefault),
      ),
    );
  }

  Widget _buildCityDropdown(List<String> cities, bool isFrom) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Full width: screen horizontal padding 12*2=24
    final dropdownWidth = screenWidth - (AppDesign.screenHorizontalPadding * 2);

    return FormField<String>(
      validator: (_) {
        final text = isFrom ? _cityController.text : _toCityController.text;
        return text.trim().isEmpty ? 'Required' : null;
      },
      builder: (state) {
        return DropdownMenu<String>(
          width: dropdownWidth,
          controller: isFrom ? _cityController : _toCityController,
          label: Text(
            _selectedHead == 'Travel'
                ? (isFrom ? 'From' : 'To')
                : _selectedHead == 'Accommodation'
                    ? 'Location'
                    : 'City',
          ),
          errorText: state.errorText,
          enableFilter: true,
          requestFocusOnTap: true,
          enableSearch: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          textStyle: AppTextStyles.bodyLarge,
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            elevation: WidgetStateProperty.all(8),
          ),
          onSelected: (newValue) {
            state.didChange(newValue); // clear error on selection
            if (newValue != null) {
              if (isFrom) {
                _cityController.text = newValue;
                // Copy From to To by default
                if (_toCityController.text.isEmpty ||
                    _toCityController.text == _cityController.text) {
                  _toCityController.text = newValue;
                }
              } else {
                _toCityController.text = newValue;
              }
              setState(() {});
            }
          },
          dropdownMenuEntries: cities
              .map(
                (e) => DropdownMenuEntry<String>(
                  value: e,
                  label: e,
                  style: MenuItemButton.styleFrom(
                    textStyle: AppTextStyles.bodyLarge,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDropdown({
    Key? key,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Match Notes and other full-width fields: screen horizontal padding 12*2
    final dropdownWidth = screenWidth - (AppDesign.screenHorizontalPadding * 2);

    return FormField<String>(
      key: key,
      initialValue: value,
      validator: validator,
      builder: (state) {
        return DropdownMenu<String>(
          width: dropdownWidth,
          initialSelection: value,
          errorText: state.errorText,
          label: Text(label),
          onSelected: (newValue) {
            onChanged(newValue);
            state.didChange(newValue);
          },
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          textStyle: AppTextStyles.bodyLarge,
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            elevation: WidgetStateProperty.all(8),
          ),
          dropdownMenuEntries: items
              .map(
                (e) => DropdownMenuEntry<String>(
                  value: e,
                  label: e,
                  style: MenuItemButton.styleFrom(
                    textStyle: AppTextStyles.bodyLarge,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Text(
          DateFormat('dd MMM yyyy').format(date),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Clamps a date to be within the trip's start and end date range.
  DateTime _clampDateToTripRange(DateTime date, Trip trip) {
    DateTime clamped = date;
    
    // Clamp to trip start date
    if (clamped.isBefore(trip.startDate)) {
      clamped = trip.startDate;
    }
    
    // Clamp to trip end date (if exists)
    if (trip.endDate != null && clamped.isAfter(trip.endDate!)) {
      clamped = trip.endDate!;
    }
    
    return clamped;
  }

  /// Returns a valid date for the date picker.
  /// If currentDate is within trip range, returns it.
  /// Otherwise, returns the nearest valid date (today if within range, otherwise trip start date or end date).
  DateTime _getValidInitialDate(DateTime currentDate, bool isStart, Trip trip) {
    // Normalize dates to date-only for comparison
    final currentDateOnly = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );
    final tripStartOnly = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final tripEndOnly = trip.endDate != null
        ? DateTime(
            trip.endDate!.year,
            trip.endDate!.month,
            trip.endDate!.day,
          )
        : null;
    
    // Check if current date is within trip range
    if (currentDateOnly.compareTo(tripStartOnly) >= 0) {
      if (tripEndOnly == null || currentDateOnly.compareTo(tripEndOnly) <= 0) {
        return currentDate;
      }
    }
    
    // Current date is outside trip range, find nearest valid date
    final today = DateTime.now();
    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );
    
    // If today is within trip range, use today
    if (todayOnly.compareTo(tripStartOnly) >= 0) {
      if (tripEndOnly == null || todayOnly.compareTo(tripEndOnly) <= 0) {
        return today;
      }
    }
    
    // If today is before trip start, use trip start
    if (todayOnly.isBefore(tripStartOnly)) {
      return trip.startDate;
    }
    
    // If today is after trip end (and trip has end date), use trip end
    if (tripEndOnly != null && todayOnly.isAfter(tripEndOnly)) {
      return trip.endDate!;
    }
    
    // Fallback to trip start date
    return trip.startDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final tripsAsync = ref.read(tripListProvider);
    final trip = tripsAsync.maybeWhen(
      data: (trips) => trips.where((t) => t.id == widget.tripId).firstOrNull,
      orElse: () => null,
    );

    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 450,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppDesign.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Text(
              isStart ? 'Select Start Date' : 'Select End Date',
              style: AppTextStyles.headline2.copyWith(
                fontSize: 18,
              ),
            ),
            const Gap(8),
            Expanded(
              child: Builder(
                builder: (builderContext) {
                  final firstDate = trip?.startDate ?? DateTime(2020);
                  final lastDate = trip?.endDate ?? DateTime(2030);
                  final initialDate = trip != null
                      ? _getValidInitialDate(
                          isStart ? _startDate : _endDate,
                          isStart,
                          trip,
                        )
                      : (isStart ? _startDate : _endDate);
                  
                  // Ensure initialDate is within the valid range
                  final validInitialDate = initialDate.isBefore(firstDate)
                      ? firstDate
                      : (initialDate.isAfter(lastDate) ? lastDate : initialDate);
                  
                  return CalendarDatePicker(
                    initialDate: validInitialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onDateChanged: (date) {
                      Navigator.pop(ctx, date);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null && trip != null) {
      setState(() {
        if (isStart) {
          // Clamp start date to trip range
          DateTime clampedStart = picked;
          if (clampedStart.isBefore(trip.startDate)) {
            clampedStart = trip.startDate;
          }
          if (trip.endDate != null && clampedStart.isAfter(trip.endDate!)) {
            clampedStart = trip.endDate!;
          }
          _startDate = clampedStart;
          // Smart Logic: Automatically update end date to start date
          _endDate = clampedStart;
        } else {
          // Clamp end date to trip range
          DateTime clampedEnd = picked;
          if (clampedEnd.isBefore(trip.startDate)) {
            clampedEnd = trip.startDate;
          }
          if (trip.endDate != null && clampedEnd.isAfter(trip.endDate!)) {
            clampedEnd = trip.endDate!;
          }
          _endDate = clampedEnd;
          // If end is before start, move start
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(expensesProvider(widget.tripId).notifier)
            .deleteExpense(widget.expense!.id!);
        if (mounted) {
          Navigator.pop(context); // Close form
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final tripsAsync = ref.read(tripListProvider);
      final trip = tripsAsync.maybeWhen(
        data: (trips) => trips.where((t) => t.id == widget.tripId).firstOrNull,
        orElse: () => null,
      );

      if (trip != null) {
        // Compare only date parts
        final tripStart = DateTime(
          trip.startDate.year,
          trip.startDate.month,
          trip.startDate.day,
        );
        final tripEnd = trip.endDate != null
            ? DateTime(
                trip.endDate!.year,
                trip.endDate!.month,
                trip.endDate!.day,
              )
            : null;
        final expenseStart = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        );
        final expenseEnd = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
        );

        // Validate start date
        if (expenseStart.isBefore(tripStart)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense start date cannot be before trip start date (${DateFormat('dd MMM yyyy').format(trip.startDate)})',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        // Validate end date against trip end date (if trip has end date)
        if (tripEnd != null && expenseStart.isAfter(tripEnd)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense start date cannot be after trip end date (${DateFormat('dd MMM yyyy').format(trip.endDate!)})',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        // Validate expense end date
        if (expenseEnd.isBefore(tripStart)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense end date cannot be before trip start date (${DateFormat('dd MMM yyyy').format(trip.startDate)})',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        if (tripEnd != null && expenseEnd.isAfter(tripEnd)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Expense end date cannot be after trip end date (${DateFormat('dd MMM yyyy').format(trip.endDate!)})',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final cityName = _cityController.text.trim();
      final destinationName = _toCityController.text.isNotEmpty
          ? _toCityController.text.trim()
          : null;

      // Ensure all bill paths are copied to persistent storage before saving
      final persistentBillPaths = await ImageUtils.copyToBillsDir(_billPaths);

      final expense = Expense(
        id: widget.expense?.id,
        tripId: widget.tripId,
        head: _selectedHead,
        subHead: _selectedSubHead,
        startDate: _startDate,
        endDate: _endDate,
        city: cityName,
        toCity: destinationName,
        pax: _showPaxField
            ? (int.tryParse(_paxController.text) ?? 1)
            : null,
        amount: double.parse(_amountController.text),
        billPaths: persistentBillPaths,
        notes: _notesController.text,
        createdAt: widget.expense?.createdAt ?? DateTime.now(),
      );

      // Check for Duplicates
      final existingExpenses = await ref.read(
        expensesProvider(widget.tripId).future,
      );
      final isDuplicate = existingExpenses.any((e) {
        if (e.id == expense.id) return false; // Don't compare with self

        final sameHead = e.head == expense.head;
        final sameSubHead = e.subHead == expense.subHead;
        // Use tolerance for currency (avoid floating-point equality issues)
        final sameAmount = (e.amount - expense.amount).abs() < 0.01;

        final sameDate =
            e.startDate.year == expense.startDate.year &&
            e.startDate.month == expense.startDate.month &&
            e.startDate.day == expense.startDate.day;

        final sameCity = e.city.trim().toLowerCase() ==
            expense.city.trim().toLowerCase();

        final sameToCity =
            (e.toCity ?? '').trim().toLowerCase() ==
            (expense.toCity ?? '').trim().toLowerCase();

        return sameHead &&
            sameSubHead &&
            sameAmount &&
            sameDate &&
            sameCity &&
            sameToCity;
      });

      if (isDuplicate && mounted) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Duplicate Expense?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This expense matches an existing entry with the following details:',
                ),
                const Gap(12),
                _buildDuplicateDetailRow(
                  'Category',
                  '$_selectedHead${_selectedSubHead != null ? ' - $_selectedSubHead' : ''}',
                ),
                _buildDuplicateDetailRow(
                  'Amount',
                  '₹ ${_amountController.text}',
                ),
                _buildDuplicateDetailRow(
                  'Date',
                  DateFormat('dd MMM yyyy').format(_startDate),
                ),
                _buildDuplicateDetailRow(
                  'Location',
                  '$cityName${destinationName != null ? ' -> $destinationName' : ''}',
                ),
                const Gap(16),
                const Text('Do you still want to add this?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add Anyway'),
              ),
            ],
          ),
        );

        if (shouldProceed != true) return;
      }

      try {
        if (widget.expense == null) {
          await ref
              .read(expensesProvider(widget.tripId).notifier)
              .addExpense(expense);
        } else {
          await ref
              .read(expensesProvider(widget.tripId).notifier)
              .updateExpense(expense);
        }

        // Update trip cities if new
        final tripsAsync = ref.read(tripListProvider);
        tripsAsync.whenData((trips) async {
          final trip = trips.where((t) => t.id == widget.tripId).firstOrNull;
          if (trip == null) return;

          final List<String> newCities = [cityName];
          if (destinationName != null) newCities.add(destinationName);

          final currentCities = List<String>.from(trip.cities);
          bool modified = false;

          for (final city in newCities) {
            if (!currentCities.any(
              (c) => c.toLowerCase() == city.toLowerCase(),
            )) {
              currentCities.add(city);
              modified = true;
            }
          }

          if (modified) {
            final updatedTrip = trip.copyWith(
              cities: currentCities,
              lastModifiedAt: DateTime.now(),
            );
            await ref.read(tripListProvider.notifier).updateTrip(updatedTrip);
          }
        });

        if (mounted) {
          Navigator.pop(context, expense);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
  }

  Widget _buildEvidenceList() {
    return Column(
      children: [
        if (_billPaths.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _billPaths.length + 1,
              itemBuilder: (context, index) {
                if (index == _billPaths.length) {
                  return _buildAddMoreEvidence();
                }
                return _buildEvidenceThumbnail(index);
              },
            ),
          )
        else
          GestureDetector(
            onTap: () => _pickImage(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: AppDesign.cardDecoration(
                borderRadius: AppDesign.buttonBorderRadius,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: AppDesign.primary,
                  ),
                  const Gap(8),
                  Text(
                    'Add Evidence (Images or PDF)',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppDesign.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEvidenceThumbnail(int index) {
    final path = _billPaths[index];
    final isPdf = path.toLowerCase().endsWith('.pdf');

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        border: Border.all(color: AppDesign.borderDefault),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _viewFullImage(path, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isPdf
                  ? Container(
                      width: 100,
                      height: 120,
                      color: AppDesign.error.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 32,
                          color: AppDesign.error,
                        ),
                      ),
                    )
                  : _isBillFileMissing(path)
                      ? Container(
                          width: 100,
                          height: 120,
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 32),
                              const Gap(4),
                              Text(
                                'No longer available',
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        )
                      : Image(
                          image: _getImageProvider(path),
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 32),
                            );
                          },
                        ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _billPaths.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(String path, int initialIndex) {
    final imagePaths = _billPaths.where((p) => !p.toLowerCase().endsWith('.pdf')).toList();
    
    // If clicking on a PDF or no images, show simple dialog
    if (path.toLowerCase().endsWith('.pdf') || imagePaths.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: path.toLowerCase().endsWith('.pdf')
                    ? Container(
                        padding: EdgeInsets.all(
                            AppDesign.screenHorizontalPadding * 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: AppDesign.error,
                            ),
                            const Gap(16),
                            Text(
                              'PDF Document',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(8),
                            Text(
                              path.split(RegExp(r'[/\\]')).last,
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, size: 64),
                            const Gap(12),
                            Text(
                              'Image no longer available',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Find the index in the image paths list
    final imageIndex = imagePaths.indexWhere((p) => p == path);
    final startIndex = imageIndex >= 0 ? imageIndex : 0;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _ImageViewerDialog(
        imagePaths: imagePaths,
        initialIndex: startIndex,
        getImageProvider: _getImageProvider,
        isBillFileMissing: _isBillFileMissing,
      ),
    );
  }

  Widget _buildAddMoreEvidence() {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.blue),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppDesign.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(12),
            Text(
              'Add Evidence',
              style: AppTextStyles.headline2.copyWith(
                fontSize: 18,
              ),
            ),
            const Gap(16),
            _buildPickerOption(
              icon: Icons.document_scanner_outlined,
              label: 'Smart Scan (Documents)',
              onTap: () async {
                final granted = await PermissionUtils.requestCamera(context);
                if (!granted) return;
                Navigator.pop(ctx);
                final paths = await ImageUtils.scanDocument(context);
                if (paths.isNotEmpty && mounted) {
                  setState(() => _billPaths.addAll(paths));
                }
              },
            ),
            _buildPickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () async {
                final granted = await PermissionUtils.requestGallery(context);
                if (!granted) return;
                Navigator.pop(ctx);
                final paths = await ImageUtils.pickMultipleImagesFromGallery();
                if (paths.isNotEmpty && mounted) {
                  setState(() => _billPaths.addAll(paths));
                }
              },
            ),
            _buildPickerOption(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Upload PDF Document',
              onTap: () async {
                final granted = await PermissionUtils.requestStorageForFiles(context);
                if (!granted) return;
                Navigator.pop(ctx);
                final paths = await ImageUtils.pickPdfAndConvert();
                if (paths.isNotEmpty && mounted) {
                  setState(() => _billPaths.addAll(paths));
                }
              },
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppDesign.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius + 2),
        ),
        child: Icon(icon, color: AppDesign.primary),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium,
      ),
      onTap: onTap,
    );
  }

  bool _isBillFileMissing(String path) =>
      !kIsWeb && path.isNotEmpty && !path.startsWith('http') && !File(path).existsSync();

  ImageProvider _getImageProvider(String path) {
    if (kIsWeb) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  Widget _buildDuplicateDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppDesign.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final ImageProvider Function(String) getImageProvider;
  final bool Function(String) isBillFileMissing;

  const _ImageViewerDialog({
    required this.imagePaths,
    required this.initialIndex,
    required this.getImageProvider,
    required this.isBillFileMissing,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, TransformationController> _transformationControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    for (var controller in _transformationControllers.values) {
      controller.dispose();
    }
    _transformationControllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  TransformationController _getControllerForIndex(int index) {
    if (!_transformationControllers.containsKey(index)) {
      _transformationControllers[index] = TransformationController();
    }
    return _transformationControllers[index]!;
  }

  bool _isZoomed(int index) {
    final controller = _transformationControllers[index];
    if (controller == null) return false;
    return controller.value.getMaxScaleOnAxis() > 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with PageView for swiping
          PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final path = widget.imagePaths[index];
              
              if (widget.isBillFileMissing(path)) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        const Gap(12),
                        Text(
                          'Image no longer available',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: InteractiveViewer(
                  transformationController: _getControllerForIndex(index),
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Image(
                    image: widget.getImageProvider(path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Close button - top right with safe area padding
          Positioned(
            top: safePadding.top + 8,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ),
          ),

          // Image counter - bottom center (only if multiple images)
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: safePadding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imagePaths.length}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

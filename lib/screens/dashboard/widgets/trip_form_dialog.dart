import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../models/trip.dart';
import '../../../providers/trip_provider.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/theme/app_text_styles.dart';

class TripFormDialog extends ConsumerStatefulWidget {
  final Trip? trip;
  const TripFormDialog({super.key, this.trip});

  @override
  ConsumerState<TripFormDialog> createState() => _TripFormDialogState();
}

class _TripFormDialogState extends ConsumerState<TripFormDialog> {
  late final TextEditingController _nameController;
  final _citySearchController = TextEditingController();
  late List<String> _selectedCities;
  late DateTime _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip?.name ?? '');
    _selectedCities = List.from(widget.trip?.cities ?? []);
    _startDate = widget.trip?.startDate ?? DateTime.now();
    _endDate = widget.trip?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
        title: Text(
          'Select Start Date',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: CalendarDatePicker(
            initialDate: _startDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) {
              Navigator.pop(ctx, date);
            },
          ),
        ),
        actions: const [],
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, reset it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: AppDesign.screenHorizontalPadding,
          vertical: AppDesign.screenVerticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        ),
        title: Text(
          'Select End Date',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 320,
          child: CalendarDatePicker(
            initialDate: _endDate ?? _startDate,
            firstDate: _startDate,
            lastDate: DateTime(2030),
            onDateChanged: (date) {
              Navigator.pop(ctx, date);
            },
          ),
        ),
        actions: const [],
      ),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _addCity(String city) {
    final trimmed = city.trim();
    if (trimmed.isNotEmpty && !_selectedCities.contains(trimmed)) {
      setState(() {
        _selectedCities.add(trimmed);
        _citySearchController.clear();
        _searchQuery = '';
      });
    }
  }

  void _removeCity(String city) async {
    if (widget.trip != null) {
      final expenses = await ref.read(
        expensesProvider(widget.trip!.id!).future,
      );
      final isUsed = expenses.any((e) => e.city == city);
      if (isUsed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot delete "$city" because it has expenses.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }
    setState(() => _selectedCities.remove(city));
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(citySuggestionsProvider);
    final filteredSuggestions = suggestions
        .where(
          (c) =>
              c.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !_selectedCities.contains(c),
        )
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppDesign.screenHorizontalPadding,
        vertical: AppDesign.screenVerticalPadding,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius)),
      title: Text(
        widget.trip == null ? 'New Trip' : 'Edit Trip',
        style: AppTextStyles.headline2,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogWidth.clamp(300.0, 500.0),
          maxWidth: 500,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldHeading('Trip Name'),
              const Gap(8),
              TextField(
                controller: _nameController,
                decoration: AppDesign.inputDecoration('e.g. Client Meeting'),
                style: AppTextStyles.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
              ),
              const Gap(20),
              _buildFieldHeading('Start Date'),
              const Gap(8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                child: InputDecorator(
                  decoration: AppDesign.inputDecoration('Pick travel date'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppDesign.primary,
                      ),
                      const Gap(12),
                      Text(
                        DateFormat('dd MMM yyyy').format(_startDate),
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(20),
              _buildFieldHeading('End Date'),
              const Gap(8),
              InkWell(
                onTap: _pickEndDate,
                borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                child: InputDecorator(
                  decoration: AppDesign.inputDecoration('Pick end date (optional)'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppDesign.primary,
                      ),
                      const Gap(12),
                      Text(
                        _endDate != null
                            ? DateFormat('dd MMM yyyy').format(_endDate!)
                            : 'Not set',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: _endDate != null ? null : AppDesign.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              _buildFieldHeading('Locations (Multiple Allowed)'),
              const Gap(6),
              Visibility(
                visible: _selectedCities.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _selectedCities
                        .map(
                          (c) => Chip(
                            key: ValueKey('chip_$c'),
                            label: Text(
                              c,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            onDeleted: () => _removeCity(c),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            deleteIconColor: AppDesign.textSecondary,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            backgroundColor: AppDesign.primary.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              TextField(
                controller: _citySearchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                onSubmitted: (val) => _addCity(val),
                textInputAction: TextInputAction.next,
                style: AppTextStyles.bodyLarge,
                decoration: AppDesign.inputDecoration('Type and press enter or +')
                    .copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => _addCity(_citySearchController.text),
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: AppDesign.primary,
                        ),
                        tooltip: 'Add City',
                      ),
                    ),
                textCapitalization: TextCapitalization.words,
              ),
              const Gap(6),
              Visibility(
                visible: filteredSuggestions.isNotEmpty,
                maintainState: true,
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    key: const ValueKey('city_suggestions_container'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: AppDesign.cardDecoration(
                      borderRadius: AppDesign.buttonBorderRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select from previous trips',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Gap(4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: filteredSuggestions.map((city) {
                            return ActionChip(
                              key: ValueKey('suggestion_$city'),
                              label: Text(
                                city,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              onPressed: () => _addCity(city),
                              backgroundColor: AppDesign.surfaceElevated,
                              side: const BorderSide(color: AppDesign.borderDefault),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _selectedCities.isNotEmpty) {
              final trip =
                  (widget.trip ??
                          Trip(
                            name: '',
                            cities: [],
                            startDate: _startDate,
                            endDate: _endDate,
                            lastModifiedAt: DateTime.now(),
                          ))
                      .copyWith(
                        name: _nameController.text,
                        cities: _selectedCities,
                        startDate: _startDate,
                        endDate: _endDate,
                        lastModifiedAt: DateTime.now(),
                      );
              if (widget.trip == null) {
                ref.read(tripListProvider.notifier).addTrip(trip);
              } else {
                ref.read(tripListProvider.notifier).updateTrip(trip);
              }
              Navigator.pop(context, trip);
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
            ),
          ),
          child: Text(widget.trip == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildFieldHeading(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

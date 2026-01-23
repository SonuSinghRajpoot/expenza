import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/error_handler.dart';

class ExpenseDetailViewScreen extends ConsumerStatefulWidget {
  final Expense expense;
  final Trip trip;

  const ExpenseDetailViewScreen({
    super.key,
    required this.expense,
    required this.trip,
  });

  @override
  ConsumerState<ExpenseDetailViewScreen> createState() =>
      _ExpenseDetailViewScreenState();
}

class _ExpenseDetailViewScreenState
    extends ConsumerState<ExpenseDetailViewScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        backgroundColor: AppDesign.surfaceElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Details',
          style: AppTextStyles.headline2,
        ),
        actions: widget.trip.status == 'Active'
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: OutlinedButton(
                    onPressed: () => _deleteExpense(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(expense),
            const Gap(20),

            // Expense Details
            _buildSection('Expense Information', [
              _buildDetailRow('Category', expense.head),
              if (expense.subHead != null)
                _buildDetailRow('Sub-Category', expense.subHead!),
              _buildDetailRow(
                'Date',
                dateFormat.format(expense.startDate),
              ),
              if (expense.startDate != expense.endDate)
                _buildDetailRow(
                  'End Date',
                  dateFormat.format(expense.endDate),
                ),
              _buildDetailRow(
                expense.head == 'Travel' ? 'From Location' : 'Location',
                expense.city,
              ),
              if (expense.head == 'Travel' && expense.toCity != null)
                _buildDetailRow('To Location', expense.toCity!),
              if (expense.pax != null)
                _buildDetailRow('Number of Guests (PAX)', expense.pax.toString()),
              _buildDetailRow(
                'Amount',
                '₹ ${expense.amount.toStringAsFixed(2)}',
                isAmount: true,
              ),
            ]),

            // Notes
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const Gap(20),
              _buildSection('Notes', [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    expense.notes!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppDesign.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ]),
            ],

            // Evidence/Bills
            if (expense.billPaths.isNotEmpty) ...[
              const Gap(20),
              _buildEvidenceSection(expense.billPaths),
            ],

            // Metadata
            const Gap(20),
            _buildSection('Metadata', [
              _buildDetailRow(
                'Created At',
                '${_dateFormat.format(expense.createdAt)} at ${_timeFormat.format(expense.createdAt)}',
              ),
              if (expense.createdBy != null)
                _buildDetailRow('Created By', expense.createdBy!),
            ]),
            const Gap(40),
          ],
        ),
      ),
      floatingActionButton: widget.trip.status == 'Active'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pop(context, true); // Return true to indicate edit
              },
              backgroundColor: AppDesign.primary,
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeaderCard(Expense expense) {
    final categoryColor = _getCategoryColor(expense.head);
    final categoryIcon = _getCategoryIcon(expense.head);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.itemBorderRadius,
      ).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 32,
            ),
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.subHead ?? expense.head,
                  style: AppTextStyles.headline2.copyWith(
                    fontSize: 20,
                  ),
                ),
                const Gap(4),
                Text(
                  '₹ ${expense.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.headline1.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.itemBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: AppDesign.borderDefault),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppDesign.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isAmount ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(List<String> billPaths) {
    return Container(
      decoration: AppDesign.cardDecoration(
        borderRadius: AppDesign.itemBorderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Evidence (${billPaths.length})',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppDesign.borderDefault),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: billPaths.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return _buildEvidenceThumbnail(path, index, billPaths.length);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceThumbnail(String path, int index, int total) {
    final isPdf = path.toLowerCase().endsWith('.pdf');

    return GestureDetector(
      onTap: () => _viewFullImage(path, index),
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
          border: Border.all(color: AppDesign.borderDefault),
          color: AppDesign.surface,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isPdf
                  ? Container(
                      color: AppDesign.error.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: AppDesign.error,
                        ),
                      ),
                    )
                  : _isBillFileMissing(path)
                      ? Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, size: 48),
                              const Gap(8),
                              Text(
                                'No longer available',
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : Image(
                          image: _getImageProvider(path),
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                        ),
            ),
            if (total > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}/$total',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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

  void _viewFullImage(String path, int initialIndex) {
    final billPaths = widget.expense.billPaths;
    final imagePaths = billPaths.where((p) => !p.toLowerCase().endsWith('.pdf')).toList();
    
    // If clicking on a PDF or no images, show simple dialog
    if (path.toLowerCase().endsWith('.pdf') || imagePaths.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: path.toLowerCase().endsWith('.pdf')
                    ? Container(
                        padding: EdgeInsets.all(AppDesign.screenHorizontalPadding * 2),
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
                    onPressed: () => Navigator.pop(context),
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
      builder: (context) => _ImageViewerDialog(
        imagePaths: imagePaths,
        initialIndex: startIndex,
        getImageProvider: _getImageProvider,
        isBillFileMissing: _isBillFileMissing,
      ),
    );
  }

  Color _getCategoryColor(String head) {
    switch (head) {
      case 'Travel':
        return AppDesign.categoryTravel;
      case 'Accommodation':
        return AppDesign.categoryAccommodation;
      case 'Food':
        return AppDesign.categoryFood;
      case 'Event':
        return AppDesign.categoryEvent;
      case 'Miscellaneous':
        return AppDesign.categoryMisc;
      default:
        return AppDesign.categoryMisc;
    }
  }

  IconData _getCategoryIcon(String head) {
    switch (head) {
      case 'Travel':
        return Icons.directions_car_outlined;
      case 'Accommodation':
        return Icons.hotel_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Event':
        return Icons.event_outlined;
      case 'Miscellaneous':
        return Icons.receipt_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Future<void> _deleteExpense(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense entry? This action cannot be undone and the record will be permanently removed from the database.',
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
            .read(expensesProvider(widget.trip.id!).notifier)
            .deleteExpense(widget.expense.id!);
        
        if (mounted) {
          Navigator.pop(context); // Close detail view
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, e);
        }
      }
    }
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

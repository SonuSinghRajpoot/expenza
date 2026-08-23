import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../models/expense.dart';
import '../../../models/advance.dart';
import '../../../core/constants/expense_icons.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/theme/app_text_styles.dart';

class ExpenseListItemWidget extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseListItemWidget({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppDesign.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.borderOf(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.head).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    getExpenseIcon(expense.head, expense.subHead),
                    color: _getCategoryColor(expense.head),
                    size: 20,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expense.subHead ?? expense.head,
                        style: AppTextStyles.bodyLargeOf(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '${dateFormat.format(expense.startDate).toUpperCase()} • ${expense.city}${expense.toCity != null && expense.toCity != expense.city ? ' \u2192 ${expense.toCity}' : ''}',
                        style: AppTextStyles.bodySmallOf(context),
                      ),
                      if (expense.notes != null && expense.notes!.trim().isNotEmpty) ...[
                        const Gap(2),
                        Text(
                          expense.notes!.trim(),
                          style: AppTextStyles.bodySmallOf(context).copyWith(
                            color: AppDesign.textTertiaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹ ${expense.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.headline2Of(context).copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const Gap(2),
                    _buildAttachmentIcon(context, expense.billPaths),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentIcon(BuildContext context, List<String> paths) {
    if (paths.isEmpty) {
      return Icon(
        Icons.file_open_outlined,
        size: 12,
        color: AppDesign.borderOf(context),
      );
    }

    final path = paths.first;
    IconData icon;
    Color color;

    if (path.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf_outlined;
      color = AppDesign.error;
    } else {
      icon = paths.length > 1
          ? Icons.collections_outlined
          : Icons.image_outlined;
      color = Theme.of(context).colorScheme.primary;
    }

    return Icon(icon, size: 12, color: color);
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
      default:
        return AppDesign.categoryMisc;
    }
  }
}

class AdvanceListItemWidget extends StatelessWidget {
  final Advance advance;
  final VoidCallback? onTap;

  const AdvanceListItemWidget({
    required this.advance,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppDesign.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.borderOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Advance',
                      style: AppTextStyles.bodyLargeOf(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      dateFormat.format(advance.date).toUpperCase(),
                      style: AppTextStyles.bodySmallOf(context),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${advance.amount.round()}',
                    style: AppTextStyles.headline2Of(context).copyWith(
                      fontSize: 16,
                    ),
                  ),
                  if (advance.notes != null && advance.notes!.isNotEmpty) ...[
                    const Gap(2),
                    Icon(
                      Icons.notes_rounded,
                      size: 12,
                      color: AppDesign.textTertiaryOf(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

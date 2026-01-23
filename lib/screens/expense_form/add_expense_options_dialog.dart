import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/gemini_provider.dart';
import '../../core/constants/expense_constants.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';

class AddExpenseOptionsDialog extends ConsumerStatefulWidget {
  final List<String> heads;
  final Function(String? selectedHead, String? selectedSubHead, bool isAiScan) onOptionSelected;

  const AddExpenseOptionsDialog({
    super.key,
    required this.heads,
    required this.onOptionSelected,
  });

  @override
  ConsumerState<AddExpenseOptionsDialog> createState() => _AddExpenseOptionsDialogState();
}

class _AddExpenseOptionsDialogState extends ConsumerState<AddExpenseOptionsDialog> {
  String? _selectedHead;
  String? _selectedSubHead;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final activeKeyAsync = ref.watch(activeGeminiKeyProvider);
    final hasValidGeminiKey = activeKeyAsync.maybeWhen(
      data: (key) => key != null,
      orElse: () => false,
    );
    final showAiScan = isOnline && hasValidGeminiKey;
    
    final subHeads = _selectedHead != null 
        ? ExpenseConstants.subHeads[_selectedHead] 
        : null;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppDesign.screenHorizontalPadding,
        vertical: AppDesign.screenVerticalPadding,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius)),
      child: Padding(
        padding: EdgeInsets.all(AppDesign.screenHorizontalPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Expense',
              style: AppTextStyles.headline2,
              textAlign: TextAlign.center,
            ),
            const Gap(24),

            // AI Scan Option - only show if online and has valid Gemini key
            if (showAiScan) ...[
              _buildOptionButton(
                context: context,
                icon: Icons.auto_awesome_outlined,
                label: 'AI-Scan Receipt',
                subtitle: 'Auto-fill form using Gemini AI',
                color: AppDesign.primary,
                isEnabled: true,
                onTap: () {
                  Navigator.pop(context);
                  widget.onOptionSelected(null, null, true);
                },
              ),
              const Gap(24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR MANUAL ENTRY',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const Gap(16),
            ] else if (!hasValidGeminiKey && isOnline) ...[
              // Show info message when online but no Gemini key
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesign.primary.withValues(alpha: 0.08),
                      AppDesign.primary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
                  border: Border.all(
                    color: AppDesign.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppDesign.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppDesign.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDesign.smallBorderRadius),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_outlined,
                            color: AppDesign.primary,
                            size: 20,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            'Unlock AI-Powered Scanning',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        'Add a valid Gemini API key in your Profile settings to enable AI-Scan feature that automatically fills expense forms from receipt photos.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),
            ],

            // Manual Heads
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.heads
                  .map((head) => _buildHeadButton(context, head))
                  .toList(),
            ),

            // Show sub-heads when a head is selected
            if (_selectedHead != null && subHeads != null) ...[
              const Gap(20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'SELECT SUB-CATEGORY',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const Gap(12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: subHeads
                    .map((subHead) => _buildSubHeadButton(context, subHead))
                    .toList(),
              ),
            ],

            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_selectedHead != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedHead = null;
                        _selectedSubHead = null;
                      });
                    },
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled
                ? color.withValues(alpha: 0.2)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isEnabled
              ? color.withValues(alpha: 0.05)
              : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? color : AppDesign.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isEnabled
                          ? AppDesign.textSecondary
                          : AppDesign.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isEnabled ? Icons.chevron_right_rounded : Icons.cloud_off_rounded,
              color: isEnabled ? color : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadButton(BuildContext context, String head) {
    final isSelected = _selectedHead == head;
    final primaryColor = AppDesign.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedHead = head;
          _selectedSubHead = null;
        });
      },
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            head == 'Event'
                ? PremiumIcon(
                    svgPath: AppIcons.square3Stack3d,
                    size: 20,
                    color: isSelected ? primaryColor : Colors.blueGrey,
                  )
                : Icon(
                    _getCategoryIcon(head),
                    size: 20,
                    color: isSelected ? primaryColor : Colors.blueGrey,
                  ),
            const Gap(10),
            Text(
              head,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : AppDesign.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeadButton(BuildContext context, String subHead) {
    final isSelected = _selectedSubHead == subHead;
    final primaryColor = AppDesign.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubHead = subHead;
        });
        // Navigate to form with selected head and sub-head
        Navigator.pop(context);
        widget.onOptionSelected(_selectedHead, subHead, false);
      },
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
                      borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        ),
        child: Text(
          subHead,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppDesign.textPrimary,
          ),
        ),
      ),
    );
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
        return Icons.palette_outlined;
      case 'Miscellaneous':
        return Icons.receipt_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }
}

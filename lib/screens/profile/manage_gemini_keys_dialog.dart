import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../models/gemini_key.dart';
import '../../providers/gemini_provider.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/error_handler.dart';

class ManageGeminiKeysDialog extends ConsumerStatefulWidget {
  const ManageGeminiKeysDialog({super.key});

  @override
  ConsumerState<ManageGeminiKeysDialog> createState() =>
      _ManageGeminiKeysDialogState();
}

class _ManageGeminiKeysDialogState
    extends ConsumerState<ManageGeminiKeysDialog> {
  final _labelController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _labelController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _labelController.clear();
    _keyController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  Future<void> _addKey() async {
    if (_labelController.text.isEmpty || _keyController.text.isEmpty) return;

    // Check if this is the first key being added
    final currentKeys = ref.read(geminiKeysProvider).value ?? [];
    final isFirstKey = currentKeys.isEmpty;

    final newKey = GeminiKey(
      id: const Uuid().v4(),
      label: _labelController.text,
      apiKey: _keyController.text,
      isActive: isFirstKey, // Enable first key by default
    );

    await ref.read(geminiKeysProvider.notifier).addKey(newKey);
    _resetForm();
  }

  Future<void> _toggleActive(GeminiKey key) async {
    if (key.isActive) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Active Key',
          style: AppTextStyles.headline2,
        ),
        content: Text(
          'Enabling "${key.label}" will disable the current active key. Do you want to proceed?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(geminiKeysProvider.notifier).setActive(key.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(geminiKeysProvider);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppDesign.screenHorizontalPadding,
        vertical: AppDesign.screenVerticalPadding,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Gemini API Keys',
            style: AppTextStyles.headline2,
          ),
          IconButton(
            icon: Icon(_isAdding ? Icons.list_rounded : Icons.add_rounded),
            onPressed: () => setState(() => _isAdding = !_isAdding),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 400,
        child: _isAdding ? _buildAddForm() : _buildKeysList(keysAsync),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_isAdding)
          FilledButton(onPressed: _addKey, child: const Text('Save Key')),
      ],
    );
  }

  Widget _buildAddForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _labelController,
          decoration: _inputDecoration(
            'Key Label (e.g. Work, Personal)',
            Icons.label_outline,
          ),
        ),
        const Gap(16),
        TextFormField(
          controller: _keyController,
          decoration: _inputDecoration(
            'Gemini API Key',
            Icons.vpn_key_outlined,
          ),
          obscureText: true,
        ),
        const Gap(16),
        Text(
          'Keys are stored securely and will be masked after saving.',
          style: AppTextStyles.bodySmall.copyWith(color: AppDesign.textTertiary),
        ),
      ],
    );
  }

  Widget _buildKeysList(AsyncValue<List<GeminiKey>> keysAsync) {
    return keysAsync.when(
      data: (keys) {
        if (keys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: 48,
                  color: Colors.blueGrey.shade200,
                ),
                const Gap(16),
                Text(
                  'No Gemini keys found',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppDesign.textTertiary),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys[index];
            return Card(
              elevation: 0,
              color: key.isActive ? AppDesign.primary.withValues(alpha: 0.05) : AppDesign.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
                side: BorderSide(
                  color: key.isActive
                      ? AppDesign.primary
                      : AppDesign.borderDefault,
                ),
              ),
              child: ListTile(
                title: Text(
                  key.label,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  key.maskedKey,
                  style: AppTextStyles.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: key.isActive,
                        onChanged: (_) => _toggleActive(key),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ref
                          .read(geminiKeysProvider.notifier)
                          .deleteKey(key.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(ErrorHandler.getUserFriendlyMessage(e))),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

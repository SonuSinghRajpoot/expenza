import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../models/gemini_key.dart';
import '../../providers/gemini_provider.dart';
import '../../data/repositories/gemini_repository.dart';
import '../../services/gemini_service.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/error_handler.dart';

class ManageGeminiKeysDialog extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ManageGeminiKeysDialog({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ManageGeminiKeysDialog> createState() =>
      _ManageGeminiKeysDialogState();
}

class _ManageGeminiKeysDialogState extends ConsumerState<ManageGeminiKeysDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GeminiService _geminiService = GeminiService();

  // Keys tab state
  final _labelController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isAddingKey = false;
  bool _isTestingKey = false;
  ({bool success, String message})? _keyTestResult;
  String? _testedKeyId;

  // Model tab state
  final _customModelController = TextEditingController();
  bool _isCustomModelSelected = false;
  bool _isTestingModel = false;
  ({bool success, String message})? _modelTestResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _labelController.dispose();
    _keyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  void _resetKeyForm() {
    _labelController.clear();
    _keyController.clear();
    setState(() {
      _isAddingKey = false;
      _keyTestResult = null;
      _isTestingKey = false;
    });
  }

  Future<void> _testEnteredKey() async {
    final apiKey = _keyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _keyTestResult = (
          success: false,
          message: 'Please enter an API key first.',
        );
      });
      return;
    }

    setState(() {
      _isTestingKey = true;
      _keyTestResult = null;
    });

    final activeModel =
        ref.read(geminiModelProvider).value ?? GeminiRepository.defaultModel;
    final result = await _geminiService.testConnection(
      apiKey: apiKey,
      modelName: activeModel,
    );

    if (mounted) {
      setState(() {
        _isTestingKey = false;
        _keyTestResult = result;
      });
    }
  }

  Future<void> _testSavedKey(GeminiKey key) async {
    setState(() {
      _testedKeyId = key.id;
    });

    final activeModel =
        ref.read(geminiModelProvider).value ?? GeminiRepository.defaultModel;
    final result = await _geminiService.testConnection(
      apiKey: key.apiKey,
      modelName: activeModel,
    );

    if (mounted) {
      setState(() {
        _testedKeyId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  '${key.label}: ${result.message}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: result.success ? AppDesign.success : AppDesign.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _testModel(String modelName) async {
    final activeKeyAsync = ref.read(activeGeminiKeyProvider);
    final activeKey = activeKeyAsync.value;

    if (activeKey == null || activeKey.apiKey.trim().isEmpty) {
      setState(() {
        _modelTestResult = (
          success: false,
          message: 'No active API key found. Please activate an API key first.',
        );
      });
      return;
    }

    setState(() {
      _isTestingModel = true;
      _modelTestResult = null;
    });

    final result = await _geminiService.testConnection(
      apiKey: activeKey.apiKey,
      modelName: modelName.trim(),
    );

    if (mounted) {
      setState(() {
        _isTestingModel = false;
        _modelTestResult = result;
      });
    }
  }

  Future<void> _addKey() async {
    if (_labelController.text.trim().isEmpty ||
        _keyController.text.trim().isEmpty) {
      return;
    }

    final currentKeys = ref.read(geminiKeysProvider).value ?? [];
    final isFirstKey = currentKeys.isEmpty;

    final newKey = GeminiKey(
      id: const Uuid().v4(),
      label: _labelController.text.trim(),
      apiKey: _keyController.text.trim(),
      isActive: isFirstKey,
    );

    await ref.read(geminiKeysProvider.notifier).addKey(newKey);
    _resetKeyForm();
  }

  Future<void> _toggleActiveKey(GeminiKey key) async {
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

  Future<void> _selectModel(String model) async {
    setState(() {
      _isCustomModelSelected = false;
      _modelTestResult = null;
    });
    await ref.read(geminiModelProvider.notifier).setModel(model);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active Gemini model set to $model'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveCustomModel() async {
    final customName = _customModelController.text.trim();
    if (customName.isEmpty) return;

    await ref.read(geminiModelProvider.notifier).setModel(customName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active Gemini model set to $customName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(geminiKeysProvider);
    final currentModelAsync = ref.watch(geminiModelProvider);
    final activeModel =
        currentModelAsync.value ?? GeminiRepository.defaultModel;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppDesign.screenHorizontalPadding,
        vertical: AppDesign.screenVerticalPadding,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gemini Settings',
                style: AppTextStyles.headline2,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Gap(8),
          TabBar(
            controller: _tabController,
            labelColor: AppDesign.primary,
            unselectedLabelColor: AppDesign.textSecondary,
            indicatorColor: AppDesign.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Icon(Icons.vpn_key_outlined, size: 18),
                text: 'API Keys',
              ),
              Tab(
                icon: Icon(Icons.psychology_outlined, size: 18),
                text: 'AI Model',
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 430,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: API Keys
            _isAddingKey ? _buildAddKeyForm() : _buildKeysList(keysAsync),

            // Tab 2: AI Model Selection
            _buildModelSelectionView(activeModel),
          ],
        ),
      ),
      actions: [
        if (_tabController.index == 0 && _isAddingKey)
          TextButton(
            onPressed: _resetKeyForm,
            child: const Text('Cancel'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (_tabController.index == 0 && _isAddingKey)
          FilledButton(onPressed: _addKey, child: const Text('Save Key')),
      ],
    );
  }

  Widget _buildAddKeyForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(12),
          Text(
            'Add New Gemini Key',
            style: AppTextStyles.headline3Of(context),
          ),
          const Gap(14),
          TextFormField(
            controller: _labelController,
            style: AppTextStyles.bodyMediumOf(context),
            decoration: _inputDecoration(
              'Key Label (e.g. Work, Personal)',
              Icons.label_outline,
            ),
          ),
          const Gap(14),
          TextFormField(
            controller: _keyController,
            style: AppTextStyles.bodyMediumOf(context),
            decoration: _inputDecoration(
              'Gemini API Key',
              Icons.vpn_key_outlined,
            ),
            obscureText: true,
          ),
          const Gap(12),

          // Test Connection Button
          OutlinedButton.icon(
            onPressed: _isTestingKey ? null : _testEnteredKey,
            icon: _isTestingKey
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cable, size: 18),
            label: Text(
              _isTestingKey ? 'Testing Connection...' : 'Test Connection',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),

          // Test Result Display
          if (_keyTestResult != null) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _keyTestResult!.success
                    ? AppDesign.success.withValues(alpha: 0.1)
                    : AppDesign.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _keyTestResult!.success
                      ? AppDesign.success
                      : AppDesign.error,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _keyTestResult!.success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _keyTestResult!.success
                        ? AppDesign.success
                        : AppDesign.error,
                    size: 18,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _keyTestResult!.message,
                      style: AppTextStyles.bodySmallOf(context).copyWith(
                        color: _keyTestResult!.success
                            ? AppDesign.success
                            : AppDesign.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Gap(12),
          Text(
            'Keys are stored securely on your device and will be masked after saving.',
            style: AppTextStyles.bodySmallOf(context).copyWith(
              color: AppDesign.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeysList(AsyncValue<List<GeminiKey>> keysAsync) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configured Keys',
                style: AppTextStyles.bodyMediumOf(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppDesign.textSecondaryOf(context),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isAddingKey = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Key'),
              ),
            ],
          ),
        ),
        Expanded(
          child: keysAsync.when(
            data: (keys) {
              if (keys.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.vpn_key_outlined,
                        size: 48,
                        color: AppDesign.textTertiaryOf(context),
                      ),
                      const Gap(16),
                      Text(
                        'No Gemini keys found',
                        style: AppTextStyles.bodyMediumOf(context).copyWith(
                          color: AppDesign.textTertiaryOf(context),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isThisKeyTesting = _testedKeyId == key.id;

                  return Card(
                    elevation: 0,
                    color: key.isActive
                        ? primaryColor.withValues(alpha: 0.08)
                        : AppDesign.surfaceElevatedOf(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDesign.buttonBorderRadius,
                      ),
                      side: BorderSide(
                        color: key.isActive
                            ? primaryColor
                            : AppDesign.borderOf(context),
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        key.label,
                        style: AppTextStyles.bodyLargeOf(context).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        key.maskedKey,
                        style: AppTextStyles.bodySmallOf(context),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: isThisKeyTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cable, size: 18),
                            tooltip: 'Test Connection',
                            onPressed: isThisKeyTesting
                                ? null
                                : () => _testSavedKey(key),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: key.isActive,
                              onChanged: (_) => _toggleActiveKey(key),
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
            error: (e, _) => Center(
              child: Text(ErrorHandler.getUserFriendlyMessage(e)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelectionView(String activeModel) {
    final presets = GeminiRepository.presetModels;
    final isPreset = presets.contains(activeModel);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(12),
          Text(
            'Select Active Model',
            style: AppTextStyles.bodyMediumOf(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesign.textSecondaryOf(context),
            ),
          ),
          const Gap(4),
          Text(
            'Choose or enter the Gemini model for receipt scanning.',
            style: AppTextStyles.bodySmallOf(context).copyWith(
              color: AppDesign.textTertiaryOf(context),
            ),
          ),
          const Gap(12),

          // Presets list
          ...presets.map((preset) {
            final isSelected = activeModel == preset && !_isCustomModelSelected;
            return Card(
              elevation: 0,
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.08)
                  : AppDesign.surfaceElevatedOf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDesign.buttonBorderRadius,
                ),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : AppDesign.borderOf(context),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => _selectModel(preset),
                borderRadius: BorderRadius.circular(
                  AppDesign.buttonBorderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? primaryColor
                            : AppDesign.textTertiaryOf(context),
                        size: 20,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset,
                              style: AppTextStyles.bodyMediumOf(context).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? primaryColor
                                    : AppDesign.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              _getModelDescription(preset),
                              style: AppTextStyles.captionOf(context).copyWith(
                                color: AppDesign.textTertiaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (preset == 'gemini-3.7-flash')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: AppTextStyles.captionOf(context).copyWith(
                              color: AppDesign.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Custom Model Option
          Card(
            elevation: 0,
            color: (!isPreset || _isCustomModelSelected)
                ? primaryColor.withValues(alpha: 0.08)
                : AppDesign.surfaceElevatedOf(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDesign.buttonBorderRadius,
              ),
              side: BorderSide(
                color: (!isPreset || _isCustomModelSelected)
                    ? primaryColor
                    : AppDesign.borderOf(context),
                width: (!isPreset || _isCustomModelSelected) ? 1.5 : 1.0,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCustomModelSelected = true;
                        _modelTestResult = null;
                        if (!isPreset) {
                          _customModelController.text = activeModel;
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          (!isPreset || _isCustomModelSelected)
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: (!isPreset || _isCustomModelSelected)
                              ? primaryColor
                              : AppDesign.textTertiaryOf(context),
                          size: 20,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            'Custom / Future Model...',
                            style: AppTextStyles.bodyMediumOf(context).copyWith(
                              fontWeight: (!isPreset || _isCustomModelSelected)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: (!isPreset || _isCustomModelSelected)
                                  ? primaryColor
                                  : AppDesign.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPreset || _isCustomModelSelected) ...[
                    const Gap(10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _customModelController,
                            style: AppTextStyles.bodyMediumOf(context),
                            decoration: InputDecoration(
                              hintText: 'e.g. gemini-3.8-flash, gemini-3.7-pro',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppDesign.borderOf(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppDesign.borderOf(context)),
                              ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        OutlinedButton(
                          onPressed: _isTestingModel
                              ? null
                              : () => _testModel(_customModelController.text),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          child: _isTestingModel
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Test'),
                        ),
                        const Gap(6),
                        FilledButton(
                          onPressed: _saveCustomModel,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Test Preset Model Button (for selected model)
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingModel
                      ? null
                      : () => _testModel(activeModel),
                  icon: _isTestingModel
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cable, size: 16),
                  label: Text(
                    _isTestingModel
                        ? 'Testing "$activeModel"...'
                        : 'Test Connection to "$activeModel"',
                  ),
                ),
              ),
            ],
          ),

          // Model Test Result Display
          if (_modelTestResult != null) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _modelTestResult!.success
                    ? AppDesign.success.withValues(alpha: 0.1)
                    : AppDesign.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _modelTestResult!.success
                      ? AppDesign.success
                      : AppDesign.error,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _modelTestResult!.success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _modelTestResult!.success
                        ? AppDesign.success
                        : AppDesign.error,
                    size: 18,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _modelTestResult!.message,
                      style: AppTextStyles.bodySmallOf(context).copyWith(
                        color: _modelTestResult!.success
                            ? AppDesign.success
                            : AppDesign.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Gap(16),
        ],
      ),
    );
  }

  String _getModelDescription(String model) {
    switch (model) {
      case 'gemini-3.7-flash':
        return 'Latest generation with hybrid reasoning & multimodal accuracy';
      case 'gemini-2.5-flash':
        return 'Fast, balanced performance for receipts and invoices';
      case 'gemini-2.5-pro':
        return 'High reasoning capability for complex or low-quality documents';
      default:
        return 'Custom Gemini model';
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppDesign.surfaceElevatedOf(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        borderSide: BorderSide(color: AppDesign.borderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
        borderSide: BorderSide(color: AppDesign.borderOf(context)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

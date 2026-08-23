import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import 'edit_profile_dialog.dart';
import 'package:intl/intl.dart';
import '../../providers/gemini_provider.dart';
import '../../data/repositories/gemini_repository.dart';
import '../../core/services/account_backup_service.dart';
import 'manage_gemini_keys_dialog.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import '../../core/services/error_handler.dart';
import '../../core/constants/build_info.dart';
import '../../core/services/biometric_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppDesign.surfaceOf(context),
      body: profileAsync.when(
        data: (profile) => _buildProfileBody(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(ErrorHandler.getUserFriendlyMessage(err))),
      ),
    );
  }

  Widget _buildProfileBody(BuildContext context, UserProfile? profile) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: true,
          pinned: true,
          backgroundColor: AppDesign.surfaceElevatedOf(context),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: AppDesign.screenHorizontalPadding,
              bottom: AppDesign.elementSpacing,
            ),
            title: Text(
              'Accounts',
              style: AppTextStyles.headline1Of(context),
            ),
            background: Container(color: AppDesign.surfaceElevatedOf(context)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.screenHorizontalPadding,
              vertical: AppDesign.sectionSpacing,
            ),
            child: Column(
              children: [
                _buildProfileHeader(context, profile),
                const Gap(32),
                _buildAppearanceSection(context),
                const Gap(24),
                _buildSecuritySection(context),
                const Gap(24),
                _buildSettingsGroup(
                  context,
                  'OFFICIAL PROFILE',
                  [
                    _InfoItem(
                      svgPath: AppIcons.account,
                      label: 'Full Name',
                      value: profile?.fullName ?? 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.idCard,
                      label: 'Employee ID',
                      value: profile?.employeeId ?? 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.email,
                      label: 'Email Address',
                      value: profile?.email ?? 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.business,
                      label: 'Company',
                      value: profile?.company ?? 'Not set',
                    ),
                  ],
                  onEdit: () => _showEditProfileDialog(
                    context,
                    profile,
                    EditProfileSection.official,
                  ),
                ),
                const Gap(24),
                _buildSettingsGroup(
                  context,
                  'CONTACT INFORMATION',
                  [
                    _InfoItem(
                      svgPath: AppIcons.phone,
                      label: 'Phone Number',
                      value: profile?.phoneNumber ?? 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.whatsapp,
                      label: 'WhatsApp',
                      value: profile?.whatsappNumber ?? 'Not set',
                    ),
                  ],
                  onEdit: () => _showEditProfileDialog(
                    context,
                    profile,
                    EditProfileSection.contact,
                  ),
                ),
                const Gap(24),
                _buildSettingsGroup(
                  context,
                  'BANK DETAILS',
                  [
                    _InfoItem(
                      svgPath: AppIcons.account,
                      label: 'Account Name',
                      value: profile?.accountName?.isNotEmpty == true
                          ? profile!.accountName!
                          : 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.commandLine,
                      label: 'Account Number',
                      value: profile?.accountNumber?.isNotEmpty == true
                          ? profile!.accountNumber!
                          : 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.key,
                      label: 'IFSC Code',
                      value: profile?.ifscCode?.isNotEmpty == true
                          ? profile!.ifscCode!
                          : 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.bank,
                      label: 'Bank Name',
                      value: profile?.bankName?.isNotEmpty == true
                          ? profile!.bankName!
                          : 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.location,
                      label: 'Branch',
                      value: profile?.branch?.isNotEmpty == true
                          ? profile!.branch!
                          : 'Not set',
                    ),
                  ],
                  onEdit: () => _showEditProfileDialog(
                    context,
                    profile,
                    EditProfileSection.bank,
                  ),
                ),
                const Gap(24),
                _buildSettingsGroup(
                  context,
                  'UPI DETAILS',
                  [
                    _InfoItem(
                      svgPath: AppIcons.upi,
                      label: 'UPI ID',
                      value: profile?.upiId?.isNotEmpty == true
                          ? profile!.upiId!
                          : 'Not set',
                    ),
                    _InfoItem(
                      svgPath: AppIcons.account,
                      label: 'UPI Name',
                      value: profile?.upiName?.isNotEmpty == true
                          ? profile!.upiName!
                          : 'Not set',
                    ),
                  ],
                  onEdit: () => _showEditProfileDialog(
                    context,
                    profile,
                    EditProfileSection.upi,
                  ),
                ),
                const Gap(24),
                _buildGeminiSection(context),
                const Gap(24),
                _buildAccountBackupSection(context),
                const Gap(24),
                _buildDataStorageNotice(context),
                const Gap(40),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'LOG OUT',
                    style: AppTextStyles.captionOf(context).copyWith(
                      color: AppDesign.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Gap(20),
                const _AppVersionInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'APPEARANCE & THEME',
            style: AppTextStyles.captionOf(context).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppDesign.cardDecoration(
            context: context,
            borderRadius: AppDesign.itemBorderRadius,
          ),
          padding: const EdgeInsets.all(AppDesign.cardInternalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDesign.smallBorderRadius),
                    ),
                    child: Icon(
                      currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : currentThemeMode == ThemeMode.light
                              ? Icons.light_mode_rounded
                              : Icons.brightness_auto_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: AppTextStyles.bodyMediumOf(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentThemeMode == ThemeMode.system
                              ? 'Auto (System: ${isDark ? 'Dark' : 'Light'})'
                              : currentThemeMode == ThemeMode.dark
                                  ? 'Always Dark'
                                  : 'Always Light',
                          style: AppTextStyles.captionOf(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 16),
                      label: Text('System'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 16),
                      label: Text('Light'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 16),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final isAppLockEnabled = ref.watch(appLockEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'SECURITY & PRIVACY',
            style: AppTextStyles.captionOf(context).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: AppDesign.cardDecoration(
            context: context,
            borderRadius: AppDesign.itemBorderRadius,
          ),
          padding: const EdgeInsets.all(AppDesign.cardInternalPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDesign.smallBorderRadius),
                ),
                child: const PremiumIcon(
                  svgPath: AppIcons.lock,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Lock (Biometrics / PIN)',
                      style: AppTextStyles.bodyMediumOf(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Require authentication when opening app',
                      style: AppTextStyles.captionOf(context),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAppLockEnabled,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) async {
                  final success =
                      await ref.read(appLockEnabledProvider.notifier).toggle(val);
                  if (!success && val && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Authentication cancelled or not available on device.',
                        ),
                        backgroundColor: AppDesign.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile? profile) {
    final hasImage = profile?.profilePictureBase64 != null;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !hasImage
                    ? const LinearGradient(
                        colors: [AppDesign.primary, AppDesign.secondary],
                      )
                    : null,
                border: Border.all(
                  color: AppDesign.surfaceElevatedOf(context),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x332563EB),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: hasImage
                    ? DecorationImage(
                        image: MemoryImage(
                          base64Decode(profile!.profilePictureBase64!),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasImage
                  ? const Center(
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    )
                  : null,
            ),
            InkWell(
              onTap: () => _showEditProfileDialog(
                context,
                profile,
                EditProfileSection.profilePicture,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppDesign.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Gap(16),
        Text(
          profile?.nickName.isNotEmpty == true
              ? profile!.nickName
              : profile?.fullName ?? 'New User',
          style: AppTextStyles.headline1Of(context),
        ),
        if (profile?.nickName.isNotEmpty == true)
          Text(
            profile?.fullName ?? '',
            style: AppTextStyles.bodyLargeOf(context).copyWith(
              color: AppDesign.textSecondaryOf(context),
            ),
          ),
        const Gap(4),
        Text(
          profile?.employeeId.isNotEmpty == true
              ? 'ID: ${profile!.employeeId}'
              : 'ID: Pending',
          style: AppTextStyles.bodyMediumOf(context).copyWith(
            color: AppDesign.textTertiaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    String title,
    List<Widget> items, {
    VoidCallback? onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.captionOf(context).copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onEdit,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
        Container(
          decoration: AppDesign.cardDecoration(
            context: context,
            borderRadius: AppDesign.itemBorderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDesign.elementSpacing,
              horizontal: AppDesign.cardInternalPadding,
            ),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _buildGeminiSection(BuildContext context) {
    final activeKeyAsync = ref.watch(activeGeminiKeyProvider);
    final activeModelAsync = ref.watch(geminiModelProvider);
    final currentModel =
        activeModelAsync.value ?? GeminiRepository.defaultModel;

    return _buildSettingsGroup(
      context,
      'GEMINI CONFIGURATION',
      [
        activeKeyAsync.when(
          data: (key) => _InfoItem(
            svgPath: AppIcons.gemini,
            label: key != null ? 'Active Key: ${key.label}' : 'No active key',
            value: key?.maskedKey ?? 'Configure your Gemini key',
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: LinearProgressIndicator()),
          ),
          error: (err, _) => const _InfoItem(
            svgPath: AppIcons.error,
            label: 'Gemini Key',
            value: 'Error loading key',
          ),
        ),
        _InfoItem(
          svgPath: AppIcons.commandLine,
          label: 'Model Version',
          value: currentModel,
        ),
      ],
      onEdit: () => _showManageGeminiKeysDialog(context),
    );
  }

  Widget _buildAccountBackupSection(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: AccountBackupService().getLastBackupTime(),
      builder: (context, snapshot) {
        final lastBackup = snapshot.data;
        final timeStr = lastBackup != null
            ? DateFormat('MMM dd, yyyy • hh:mm a').format(lastBackup)
            : 'Auto-sync active';

        return Column(
          children: [
            _buildSettingsGroup(context, 'LOCAL BACKUP & PERSISTENCE', [
              _InfoItem(
                svgPath: AppIcons.check,
                label: 'Persistent Storage',
                value: 'Documents/Expenza/expenza_account_config.json',
              ),
              _InfoItem(
                svgPath: AppIcons.calendar,
                label: 'Last Synced',
                value: timeStr,
              ),
            ]),
            const Gap(10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AccountBackupService().syncAccountBackup();
                      setState(() {});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Account profile & Gemini keys backed up to device storage!',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.backup_outlined, size: 16),
                    label: const Text('Backup Now'),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final result =
                          await AccountBackupService().manualRestore();
                      if (result.restored) {
                        ref.invalidate(userProfileProvider);
                        ref.invalidate(geminiKeysProvider);
                        ref.invalidate(geminiModelProvider);
                        setState(() {});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Account configuration restored successfully!',
                              ),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No local backup file found to restore.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore_outlined, size: 16),
                    label: const Text('Restore Backup'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataStorageNotice(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.shade900.withValues(alpha: 0.18)
            : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
        border: Border.all(
          color: isDark ? Colors.amber.shade700 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
            size: 22,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data storage',
                  style: AppTextStyles.bodyMediumOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your trips and expenses are stored locally. Clearing app data or storage in device settings will permanently delete all your data. Export your trips regularly to keep a backup.',
                  style: AppTextStyles.bodySmallOf(context).copyWith(
                    color: AppDesign.textSecondaryOf(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManageGeminiKeysDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ManageGeminiKeysDialog(),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserProfile? profile,
    EditProfileSection section,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          EditProfileDialog(profile: profile, section: section),
    );
  }
}

class _AppVersionInfo extends StatelessWidget {
  static const _githubReleasesUrl =
      'https://github.com/SonuSinghRajpoot/expenza/releases';

  const _AppVersionInfo();

  Future<void> _openGitHubReleases(BuildContext context) async {
    final uri = Uri.parse(_githubReleasesUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '—';
        final buildNumber = snapshot.data?.buildNumber;
        final versionText = buildNumber != null && buildNumber.isNotEmpty
            ? '$version+$buildNumber'
            : version;
        final hasTimestamp = buildTimestamp.isNotEmpty;

        return GestureDetector(
          onTap: () => _openGitHubReleases(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'App Version $versionText',
                style: AppTextStyles.bodySmallOf(context).copyWith(
                  color: AppDesign.textTertiaryOf(context),
                  decoration: TextDecoration.underline,
                  decorationColor: AppDesign.textTertiaryOf(context),
                ),
              ),
              if (hasTimestamp) ...[
                const Gap(4),
                Text(
                  'Rolled out: $buildTimestamp',
                  style: AppTextStyles.bodySmallOf(context).copyWith(
                    color: AppDesign.textTertiaryOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String svgPath;
  final String label;
  final String value;

  const _InfoItem({
    required this.svgPath,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppDesign.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PremiumIcon(
              svgPath: svgPath,
              size: 20,
              color: AppDesign.textSecondaryOf(context),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmallOf(context),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

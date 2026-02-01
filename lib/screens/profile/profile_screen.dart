import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import 'edit_profile_dialog.dart';
import 'dart:convert';
import '../../providers/gemini_provider.dart';
import 'manage_gemini_keys_dialog.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/premium_icon.dart';
import '../../core/services/error_handler.dart';

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
      backgroundColor: AppDesign.surface,
      body: profileAsync.when(
        data: (profile) => _buildProfileBody(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(ErrorHandler.getUserFriendlyMessage(err))),
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
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: AppDesign.screenHorizontalPadding,
              bottom: AppDesign.elementSpacing,
            ),
            title: Text(
              'Accounts',
              style: AppTextStyles.headline1,
            ),
            background: Container(color: AppDesign.surfaceElevated),
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
                _buildSettingsGroup(
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
                _buildDataStorageNotice(),
                const Gap(40),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'LOG OUT',
                    style: AppTextStyles.caption.copyWith(
                      color: AppDesign.error,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Gap(20),
                Text(
                  'App Version 2.1.0',
                  style: AppTextStyles.bodySmall.copyWith(
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
                    ? LinearGradient(
                        colors: [AppDesign.primary, AppDesign.secondary],
                      )
                    : null,
                border: Border.all(color: Colors.white, width: 4),
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
                decoration: BoxDecoration(
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
          style: AppTextStyles.headline1,
        ),
        if (profile?.nickName.isNotEmpty == true)
          Text(
            profile?.fullName ?? '',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppDesign.textSecondary,
            ),
          ),
        const Gap(4),
        Text(
          profile?.employeeId.isNotEmpty == true
              ? 'ID: ${profile!.employeeId}'
              : 'ID: Pending',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesign.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(
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
                style: AppTextStyles.caption.copyWith(
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
                  color: AppDesign.primary,
                ),
            ],
          ),
        ),
        Container(
          decoration: AppDesign.cardDecoration(
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

    return _buildSettingsGroup('GEMINI CONFIGURATION', [
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
    ], onEdit: () => _showManageGeminiKeysDialog(context));
  }

  Widget _buildDataStorageNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.itemBorderRadius),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 22),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data storage',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your trips and expenses are stored locally. Clearing app data or storage in device settings will permanently delete all your data. Export your trips regularly to keep a backup.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppDesign.textSecondary,
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
              color: AppDesign.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: PremiumIcon(
              svgPath: svgPath,
              size: 20,
              color: AppDesign.textSecondary,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
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

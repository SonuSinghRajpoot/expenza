import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/app_design.dart';
import '../../core/theme/app_text_styles.dart';

enum EditProfileSection { official, contact, bank, upi, profilePicture }

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile? profile;
  final EditProfileSection section;
  const EditProfileDialog({super.key, this.profile, required this.section});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nickNameController;
  late TextEditingController _idController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;

  // Bank Details Controllers
  late TextEditingController _accountNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscCodeController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchController;

  // UPI Controllers
  late TextEditingController _upiIdController;
  late TextEditingController _upiNameController;

  late bool _isWhatsappSame;
  String? _profilePicBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile?.fullName ?? '',
    );
    _nickNameController = TextEditingController(
      text: widget.profile?.nickName ?? '',
    );
    _idController = TextEditingController(
      text: widget.profile?.employeeId ?? '',
    );
    _emailController = TextEditingController(text: widget.profile?.email ?? '');
    _companyController = TextEditingController(
      text: widget.profile?.company ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile?.phoneNumber ?? '',
    );
    _whatsappController = TextEditingController(
      text: widget.profile?.whatsappNumber ?? '',
    );

    _accountNameController = TextEditingController(
      text: widget.profile?.accountName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.profile?.accountNumber ?? '',
    );
    _ifscCodeController = TextEditingController(
      text: widget.profile?.ifscCode ?? '',
    );
    _bankNameController = TextEditingController(
      text: widget.profile?.bankName ?? '',
    );
    _branchController = TextEditingController(
      text: widget.profile?.branch ?? '',
    );

    _upiIdController = TextEditingController(text: widget.profile?.upiId ?? '');
    _upiNameController = TextEditingController(
      text: widget.profile?.upiName ?? '',
    );

    _isWhatsappSame = widget.profile?.isWhatsappSameAsPhone ?? false;
    _profilePicBase64 = widget.profile?.profilePictureBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nickNameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _upiIdController.dispose();
    _upiNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await Permission.photos.request();
        } catch (_) {}
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) return;
      if (mounted) {
        setState(() => _profilePicBase64 = base64Encode(bytes));
      }
    } catch (e) {
      debugPrint('Profile image pick error: $e');
    }
  }

  ImageProvider? _profileImageProvider() {
    if (_profilePicBase64 == null || _profilePicBase64!.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(_profilePicBase64!));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Edit Profile';
    switch (widget.section) {
      case EditProfileSection.official:
        title = 'Official Details';
        break;
      case EditProfileSection.contact:
        title = 'Contact Information';
        break;
      case EditProfileSection.bank:
        title = 'Bank Details';
        break;
      case EditProfileSection.upi:
        title = 'UPI Details';
        break;
      case EditProfileSection.profilePicture:
        title = 'Profile Picture';
        break;
    }

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppDesign.screenHorizontalPadding,
        vertical: AppDesign.screenVerticalPadding,
      ),
      title: Text(
        title,
        style: AppTextStyles.headline2,
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildFields(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveProfile,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  List<Widget> _buildFields() {
    switch (widget.section) {
      case EditProfileSection.official:
        return [
          TextFormField(
            controller: _nickNameController,
            decoration: _inputDecoration('Nick Name', Icons.face_outlined),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              'Full Name (Official)',
              Icons.person_outline,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _idController,
            decoration: _inputDecoration('Employee ID', Icons.badge_outlined),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration(
              'Email ID (Official)',
              Icons.email_outlined,
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: _companyController,
            decoration: _inputDecoration('Company', Icons.business_outlined),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
        ];
      case EditProfileSection.contact:
        return [
          TextFormField(
            controller: _phoneController,
            decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
            onChanged: (v) {
              if (_isWhatsappSame) {
                _whatsappController.text = v;
              }
            },
          ),
          const Gap(16),
          Row(
            children: [
              Checkbox(
                value: _isWhatsappSame,
                onChanged: (v) {
                  setState(() {
                    _isWhatsappSame = v ?? false;
                    if (_isWhatsappSame) {
                      _whatsappController.text = _phoneController.text;
                    }
                  });
                },
              ),
              Text(
                'WhatsApp is same as Phone',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const Gap(8),
          TextFormField(
            controller: _whatsappController,
            decoration: _inputDecoration(
              'WhatsApp Number',
              FontAwesomeIcons.whatsapp,
            ),
            enabled: !_isWhatsappSame,
          ),
        ];
      case EditProfileSection.bank:
        return [
          TextFormField(
            controller: _accountNameController,
            decoration: _inputDecoration(
              'Account Name',
              Icons.account_circle_outlined,
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: _accountNumberController,
            decoration: _inputDecoration(
              'Account Number',
              Icons.account_balance_outlined,
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: _ifscCodeController,
            decoration: _inputDecoration('IFSC Code', Icons.code_rounded),
          ),
          const Gap(16),
          TextFormField(
            controller: _bankNameController,
            decoration: _inputDecoration(
              'Bank Name',
              Icons.account_balance_rounded,
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: _branchController,
            decoration: _inputDecoration('Branch', Icons.location_on_outlined),
          ),
        ];
      case EditProfileSection.upi:
        return [
          TextFormField(
            controller: _upiIdController,
            decoration: _inputDecoration(
              'UPI ID',
              Icons.alternate_email_rounded,
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: _upiNameController,
            decoration: _inputDecoration('UPI Name', Icons.person_pin_outlined),
          ),
        ];
      case EditProfileSection.profilePicture:
        return [
          const Gap(10),
          _buildImagePicker(),
          const Gap(20),
          Text(
            'Tap the camera icon to pick a new profile picture.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppDesign.textTertiary),
          ),
        ];
    }
  }

  Widget _buildImagePicker() {
    final imageProvider = _profileImageProvider();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppDesign.primary,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        InkWell(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppDesign.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ],
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

  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final profile = UserProfile(
        fullName: _nameController.text,
        nickName: _nickNameController.text,
        employeeId: _idController.text,
        email: _emailController.text,
        company: _companyController.text,
        phoneNumber: _phoneController.text,
        whatsappNumber: _whatsappController.text,
        isWhatsappSameAsPhone: _isWhatsappSame,
        profilePictureBase64: _profilePicBase64,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscCodeController.text,
        bankName: _bankNameController.text,
        branch: _branchController.text,
        upiId: _upiIdController.text,
        upiName: _upiNameController.text,
      );

      await ref.read(userProfileProvider.notifier).updateProfile(profile);
      if (mounted) Navigator.pop(context);
    }
  }
}

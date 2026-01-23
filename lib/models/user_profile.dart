class UserProfile {
  final String fullName;
  final String nickName;
  final String employeeId;
  final String email;
  final String phoneNumber;
  final String whatsappNumber;
  final String company;
  final bool isWhatsappSameAsPhone;
  final String? profilePictureBase64;

  // Bank Details
  final String? accountName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? branch;

  // UPI Details
  final String? upiId;
  final String? upiName;

  UserProfile({
    required this.fullName,
    required this.nickName,
    required this.employeeId,
    required this.email,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.company,
    this.isWhatsappSameAsPhone = false,
    this.profilePictureBase64,
    this.accountName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.branch,
    this.upiId,
    this.upiName,
  });

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      'nick_name': nickName,
      'employee_id': employeeId,
      'email': email,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'company': company,
      'is_whatsapp_same_as_phone': isWhatsappSameAsPhone ? 1 : 0,
      'profile_picture_base64': profilePictureBase64,
      'account_name': accountName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'bank_name': bankName,
      'branch': branch,
      'upi_id': upiId,
      'upi_name': upiName,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['full_name'] ?? '',
      nickName: map['nick_name'] ?? '',
      employeeId: map['employee_id'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      whatsappNumber: map['whatsapp_number'] ?? '',
      company: map['company'] ?? '',
      isWhatsappSameAsPhone: (map['is_whatsapp_same_as_phone'] ?? 0) == 1,
      profilePictureBase64: map['profile_picture_base64'],
      accountName: map['account_name'],
      accountNumber: map['account_number'],
      ifscCode: map['ifsc_code'],
      bankName: map['bank_name'],
      branch: map['branch'],
      upiId: map['upi_id'],
      upiName: map['upi_name'],
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? nickName,
    String? employeeId,
    String? email,
    String? phoneNumber,
    String? whatsappNumber,
    String? company,
    bool? isWhatsappSameAsPhone,
    String? profilePictureBase64,
    String? accountName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? branch,
    String? upiId,
    String? upiName,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      nickName: nickName ?? this.nickName,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      company: company ?? this.company,
      isWhatsappSameAsPhone:
          isWhatsappSameAsPhone ?? this.isWhatsappSameAsPhone,
      profilePictureBase64: profilePictureBase64 ?? this.profilePictureBase64,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
    );
  }
}

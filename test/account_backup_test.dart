import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_expense_manager/models/user_profile.dart';
import 'package:field_expense_manager/models/gemini_key.dart';
import 'package:field_expense_manager/core/services/account_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountBackupService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    tearDown(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('syncs full profile and Gemini keys and auto-restores when empty', () async {
      final service = AccountBackupService();

      final profile = UserProfile(
        fullName: 'Sonu Singh',
        nickName: 'Sonu',
        employeeId: 'EMP123',
        email: 'sonu@example.com',
        phoneNumber: '9876543210',
        whatsappNumber: '9876543210',
        company: 'Expenza Tech',
        accountName: 'Sonu Singh',
        accountNumber: '1234567890',
        ifscCode: 'HDFC0001234',
        bankName: 'HDFC Bank',
        branch: 'Tech Park',
        upiId: 'sonu@upi',
        upiName: 'Sonu Singh',
      );

      final keys = [
        GeminiKey(
          id: 'key-1',
          label: 'Primary Key',
          apiKey: 'AIzaSyFakeKey123',
          isActive: true,
        ),
      ];

      // 1. Sync backup
      await service.syncAccountBackup(
        profile: profile,
        keys: keys,
        activeModel: 'gemini-3.7-flash',
      );

      // 2. Verify timestamp is recorded
      final lastBackup = await service.getLastBackupTime();
      expect(lastBackup, isNotNull);

      // 3. Perform restore
      final restoreResult = await service.autoRestoreIfEmpty();
      expect(restoreResult.restored, isTrue);
      expect(restoreResult.profile, isNotNull);
      expect(restoreResult.profile!.fullName, equals('Sonu Singh'));
      expect(restoreResult.profile!.nickName, equals('Sonu'));
      expect(restoreResult.profile!.employeeId, equals('EMP123'));
      expect(restoreResult.profile!.bankName, equals('HDFC Bank'));
      expect(restoreResult.profile!.upiId, equals('sonu@upi'));
      expect(restoreResult.activeModel, equals('gemini-3.7-flash'));
      expect(restoreResult.keys, isNotEmpty);
      expect(restoreResult.keys!.first.apiKey, equals('AIzaSyFakeKey123'));
    });

    test('returns false when no backup exists', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final service = AccountBackupService();
      final restoreResult = await service.autoRestoreIfEmpty();
      expect(restoreResult.restored, isFalse);
      expect(restoreResult.profile, isNull);
    });
  });
}

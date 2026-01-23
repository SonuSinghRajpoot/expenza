import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gemini_key.dart';
import '../data/repositories/gemini_repository.dart';

final geminiRepositoryProvider = Provider((ref) => GeminiRepository());

final geminiKeysProvider =
    AsyncNotifierProvider<GeminiKeysNotifier, List<GeminiKey>>(() {
      return GeminiKeysNotifier();
    });

class GeminiKeysNotifier extends AsyncNotifier<List<GeminiKey>> {
  late final GeminiRepository _repository;

  @override
  Future<List<GeminiKey>> build() async {
    _repository = ref.watch(geminiRepositoryProvider);
    return _repository.getKeys();
  }

  Future<void> addKey(GeminiKey key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.saveKey(key);
      return _repository.getKeys();
    });
  }

  Future<void> updateKey(GeminiKey key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.saveKey(key);
      return _repository.getKeys();
    });
  }

  Future<void> deleteKey(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteKey(id);
      return _repository.getKeys();
    });
  }

  Future<void> setActive(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.setActive(id);
      return _repository.getKeys();
    });
  }
}

final activeGeminiKeyProvider = Provider<AsyncValue<GeminiKey?>>((ref) {
  final keysAsync = ref.watch(geminiKeysProvider);
  return keysAsync.whenData((keys) {
    try {
      return keys.firstWhere((k) => k.isActive);
    } catch (_) {
      return null;
    }
  });
});

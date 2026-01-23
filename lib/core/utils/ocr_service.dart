import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR and sufficiency checks for receipt text.
/// Used to decide whether to send text-only (cheap) or image (fallback) to Gemini.
class OcrService {
  static const int _minOcrLength = 80;

  /// Runs ML Kit Text Recognition on the image at [imagePath].
  /// Returns extracted text, or null if OCR is not available (web), fails, or returns empty.
  static Future<String?> extractTextFromImagePath(String imagePath) async {
    if (kIsWeb) return null;
    if (imagePath.isEmpty) return null;

    TextRecognizer? recognizer;
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      return text.isEmpty ? null : text;
    } catch (e) {
      debugPrint('OcrService.extractTextFromImagePath error: $e');
      return null;
    } finally {
      recognizer?.close();
    }
  }

  /// Returns true if [text] is good enough to send to Gemini as text-only input.
  /// Requires: non-null, non-empty, length >= 80, and at least one digit.
  static bool isOcrSufficient(String? text) {
    if (text == null || text.isEmpty) return false;
    final t = text.trim();
    if (t.length < _minOcrLength) return false;
    if (!RegExp(r'\d').hasMatch(t)) return false;
    return true;
  }
}

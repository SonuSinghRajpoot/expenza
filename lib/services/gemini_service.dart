import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class GeminiService {
  static String _buildLocationBlock(List<String>? tripLocations) {
    if (tripLocations != null && tripLocations.isNotEmpty) {
      return 'Trip locations (prefer for fromCity/toCity): ${tripLocations.join(', ')}. Match when confident; else use receipt. toCity only for travel.';
    }
    return 'fromCity/toCity from receipt. toCity=null for non-travel.';
  }

  static String _buildSubHeadsBlock(Map<String, List<String>> m) {
    return m.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('; ');
  }

  static String _buildImagePrompt(
    List<String> availableHeads,
    Map<String, List<String>> availableSubHeads,
    String loc, {
    int imageCount = 1,
  }) {
    final subHeadsBlock = _buildSubHeadsBlock(availableSubHeads);
    final multiPageHint = imageCount > 1
        ? ' Two images (page 1 and 2): fromCity/toCity often on page 2 (itinerary).'
        : '';
    return 'Extract from this receipt/document into JSON: head (one of $availableHeads), subHead (MANDATORY: one of SubHeads for the chosen head), amount, date (YYYY-MM-DD), endDate, fromCity, toCity (null if non-travel), notes. $loc\n'
        'SubHeads: $subHeadsBlock\n'
        'Meal: Breakfast 4-12, Lunch 12-16, Snacks 16-19, Dinner 19-4. No time: infer. Amount=Total/Balance due.$multiPageHint';
  }

  static Map<String, dynamic>? _parseJsonResponse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final cleanText = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
    if (cleanText.isEmpty) return null;
    try {
      final decoded = jsonDecode(cleanText);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) return first;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeFromImage(
    String apiKey,
    List<String> imagePaths,
    List<String> availableHeads,
    Map<String, List<String>> availableSubHeads,
    List<String>? tripLocations,
  ) async {
    try {
      final model = gai.GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        generationConfig: gai.GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
      final toSend = imagePaths.take(2).toList();
      final parts = <gai.Part>[gai.TextPart(_buildImagePrompt(
        availableHeads, availableSubHeads,
        _buildLocationBlock(tripLocations),
        imageCount: toSend.length,
      ))];
      for (final path in toSend) {
        var bytes = await XFile(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null &&
            (decoded.width > 768 || decoded.height > 768)) {
          final resized = decoded.width >= decoded.height
              ? img.copyResize(decoded, width: 768)
              : img.copyResize(decoded, height: 768);
          bytes = img.encodeJpg(resized, quality: 85);
        }
        parts.add(gai.DataPart('image/jpeg', bytes));
      }
      final response = await model.generateContent([
        gai.Content.multi(parts),
      ]);
      return _parseJsonResponse(response.text);
    } catch (e) {
      debugPrint('GeminiService._analyzeFromImage error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeBill({
    required String apiKey,
    required List<String> imagePaths,
    required List<String> availableHeads,
    required Map<String, List<String>> availableSubHeads,
    List<String>? tripLocations,
  }) async {
    if (imagePaths.isEmpty) return null;
    return _analyzeFromImage(
      apiKey, imagePaths, availableHeads, availableSubHeads, tripLocations,
    );
  }
}

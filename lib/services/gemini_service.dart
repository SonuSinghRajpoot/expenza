import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../core/constants/expense_constants.dart';

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
    return 'Extract from this receipt/document into JSON: head (one of $availableHeads), subHead (MANDATORY: one of SubHeads for the chosen head), amount, date (YYYY-MM-DD), endDate, fromCity, toCity (null if non-travel), pax (number of people; null if not applicable). Do NOT extract notes. $loc\n'
        'SubHeads: $subHeadsBlock\n'
        'Amount: Use final total/balance due; if multiple totals, use the grand total.\n'
        'Meal: Breakfast 4-12, Lunch 12-16, Snacks 16-19, Dinner 19-4. No time: infer.\n'
        'Merchant logic: Be smart with merchant names. If Uber, Ola, Rapido, BluSmart, or similar cab/bike keywords appear, infer Travel head with Cab or Bike subHead. Swiggy/Zomato -> Food. OYO/MakeMyTrip (hotels) -> Accommodation. Use merchant context to infer appropriate head and subHead from the allowed list.\n'
        'If a field cannot be determined, use null. Do not guess dates or amounts.$multiPageHint';
  }

  static gai.Schema _buildResponseSchema(List<String> availableHeads) {
    final allSubHeads = <String>{};
    for (final subs in ExpenseConstants.subHeads.values) {
      allSubHeads.addAll(subs);
    }
    return gai.Schema.object(
      properties: {
        'head': gai.Schema.enumString(
          enumValues: availableHeads,
          description: 'Expense category',
        ),
        'subHead': gai.Schema.enumString(
          enumValues: allSubHeads.toList()..sort(),
          description: 'Sub-category for the chosen head',
          nullable: true,
        ),
        'amount': gai.Schema.number(
          description: 'Final total/balance due amount',
          nullable: true,
        ),
        'date': gai.Schema.string(
          description: 'Date in YYYY-MM-DD format',
          nullable: true,
        ),
        'endDate': gai.Schema.string(
          description: 'End date in YYYY-MM-DD for multi-day; null if same as date',
          nullable: true,
        ),
        'fromCity': gai.Schema.string(
          description: 'From location / city',
          nullable: true,
        ),
        'toCity': gai.Schema.string(
          description: 'To city for travel; null if non-travel',
          nullable: true,
        ),
        'pax': gai.Schema.integer(
          description: 'Number of people; null if not applicable',
          nullable: true,
        ),
      },
      requiredProperties: ['head', 'subHead'],
    );
  }

  /// Builds notes from extracted fields instead of from receipt text.
  /// Examples: "{fromCity} to {toCity} flight ticket for {pax} person",
  /// "Accommodation for {pax} person", "Event Fee", "Stationary".
  static String buildNotesFromExtractedFields(Map<String, dynamic> data) {
    final head = data['head']?.toString();
    final subHead = data['subHead']?.toString();
    final fromCity = data['fromCity']?.toString();
    final toCity = data['toCity']?.toString();
    final pax = data['pax'];
    final paxNum = pax is int
        ? pax
        : (pax != null ? int.tryParse(pax.toString()) : null);
    final paxStr = paxNum != null
        ? (paxNum == 1 ? '1 person' : '$paxNum persons')
        : null;

    if (head == null) return '';

    switch (head) {
      case 'Travel':
        if (fromCity != null && toCity != null && subHead != null) {
          final subLower = subHead.toLowerCase();
          if (subLower == 'flight') {
            return paxStr != null
                ? '$fromCity to $toCity flight ticket for $paxStr'
                : '$fromCity to $toCity flight ticket';
          }
          return paxStr != null
              ? '$fromCity to $toCity $subHead for $paxStr'
              : '$fromCity to $toCity $subHead';
        }
        return subHead ?? 'Travel';
      case 'Accommodation':
        return paxStr != null
            ? '${subHead ?? 'Accommodation'} for $paxStr'
            : (subHead ?? 'Accommodation');
      case 'Event':
        return subHead ?? 'Event';
      case 'Miscellaneous':
        return subHead ?? 'Miscellaneous';
      case 'Food':
        return paxStr != null
            ? '${subHead ?? 'Meal'} for $paxStr'
            : (subHead ?? 'Meal');
      default:
        return subHead ?? head;
    }
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
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: gai.GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _buildResponseSchema(availableHeads),
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
      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) {
        debugPrint(
          'GeminiService: empty response. candidates=${response.candidates?.length ?? 0}',
        );
        return null;
      }
      return _parseJsonResponse(rawText);
    } catch (e, st) {
      debugPrint('GeminiService._analyzeFromImage error: $e');
      debugPrint('GeminiService stack: $st');
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

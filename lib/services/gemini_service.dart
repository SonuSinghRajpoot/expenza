import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../core/constants/expense_constants.dart';
import '../core/utils/ocr_service.dart';
import '../data/repositories/gemini_repository.dart';

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
        ? ' Document spans $imageCount pages/images: itinerary, hotel folios, check-in/out and grand totals may appear on any page.'
        : '';
    return 'Extract from this receipt/document into JSON: head (one of $availableHeads), subHead (MANDATORY: one of SubHeads for the chosen head), amount, date (YYYY-MM-DD), endDate, fromCity, toCity (null if non-travel), pax (number of people; null if not applicable). Do NOT extract notes. $loc\n'
        'SubHeads: $subHeadsBlock\n\n'
        'CRITICAL AMOUNT & DEDUCTION RULES:\n'
        '1. Search for all price figures: Base Fare / Item price, Subtotal, Taxes/GST, Ancillary fees (Convenience fee, Seat selection, Meal add-on, Baggage fee, Service charge), Gross Amount, Discounts, Coupons, Promo Codes, and Amount Paid.\n'
        '2. ALWAYS return the FINAL NET AMOUNT PAID / TOTAL AMOUNT CHARGED after applying all deductions, discounts, promo codes, cashback, or coupons.\n'
        '3. For Flight Tickets & Travel Invoices (MakeMyTrip, Indigo, EaseMyTrip, Air India, Cleartrip, IRCTC, etc.):\n'
        '   - Identify Base Fare vs Gross Total vs Instant Discount vs Convenience/Platform Fee.\n'
        '   - Return the actual final amount deducted/charged (Total Amount Paid / Net Paid / Amount Charged to Bank/Card/UPI), NOT the gross total or base fare before discount.\n'
        '4. For Hotel Folios & Restaurant Bills:\n'
        '   - Return the Net Amount Paid / Balance Settled after applying any advance payment, promo voucher, or coupon.\n'
        '5. Never return the pre-discount total or base fare when discounts/deductions are present.\n\n'
        'Meal: Breakfast 4-12, Lunch 12-16, Snacks 16-19, Dinner 19-4. No time: infer.\n'
        'Merchant logic: Be smart with merchant names. If Uber, Ola, Rapido, BluSmart, or similar cab/bike keywords appear, infer Travel head with Cab or Bike subHead. Swiggy/Zomato -> Food. OYO/MakeMyTrip (hotels) -> Accommodation. Use merchant context to infer appropriate head and subHead from the allowed list.\n'
        'If a field cannot be determined, use null. Do not guess dates or amounts.$multiPageHint';
  }

  static String _buildTextPrompt(
    String ocrText,
    List<String> availableHeads,
    Map<String, List<String>> availableSubHeads,
    String loc,
  ) {
    final subHeadsBlock = _buildSubHeadsBlock(availableSubHeads);
    return 'Extract from this receipt text into JSON: head (one of $availableHeads), subHead (MANDATORY: one of SubHeads for the chosen head), amount, date (YYYY-MM-DD), endDate, fromCity, toCity (null if non-travel), pax (number of people; null if not applicable). Do NOT extract notes. $loc\n'
        'SubHeads: $subHeadsBlock\n\n'
        'CRITICAL AMOUNT & DEDUCTION RULES:\n'
        '1. Search for all price figures: Base Fare / Item price, Subtotal, Taxes/GST, Ancillary fees (Convenience fee, Seat selection, Meal add-on, Baggage fee, Service charge), Gross Amount, Discounts, Coupons, Promo Codes, and Amount Paid.\n'
        '2. ALWAYS return the FINAL NET AMOUNT PAID / TOTAL AMOUNT CHARGED after applying all deductions, discounts, promo codes, cashback, or coupons.\n'
        '3. For Flight Tickets & Travel Invoices (MakeMyTrip, Indigo, EaseMyTrip, Air India, Cleartrip, IRCTC, etc.):\n'
        '   - Identify Base Fare vs Gross Total vs Instant Discount vs Convenience/Platform Fee.\n'
        '   - Return the actual final amount deducted/charged (Total Amount Paid / Net Paid / Amount Charged to Bank/Card/UPI), NOT the gross total or base fare before discount.\n'
        '4. For Hotel Folios & Restaurant Bills:\n'
        '   - Return the Net Amount Paid / Balance Settled after applying any advance payment, promo voucher, or coupon.\n'
        '5. Never return the pre-discount total or base fare when discounts/deductions are present.\n\n'
        'Meal: Breakfast 4-12, Lunch 12-16, Snacks 16-19, Dinner 19-4. No time: infer.\n'
        'Merchant logic: Be smart with merchant names. If Uber, Ola, Rapido, BluSmart, or similar cab/bike keywords appear, infer Travel head with Cab or Bike subHead. Swiggy/Zomato -> Food. OYO/MakeMyTrip (hotels) -> Accommodation. Use merchant context to infer appropriate head and subHead from the allowed list.\n'
        'If a field cannot be determined, use null. Do not guess dates or amounts.\n\n'
        '--- RECEIPT OCR TEXT ---\n'
        '$ocrText';
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
          description:
              'Final net total amount paid after all deductions, discounts, promo codes, taxes, and fees',
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

  Future<Map<String, dynamic>?> _analyzeFromText(
    String apiKey,
    String ocrText,
    List<String> availableHeads,
    Map<String, List<String>> availableSubHeads,
    List<String>? tripLocations, {
    String? modelName,
  }) async {
    try {
      final selectedModel = (modelName != null && modelName.trim().isNotEmpty)
          ? modelName.trim()
          : GeminiRepository.defaultModel;

      final model = gai.GenerativeModel(
        model: selectedModel,
        apiKey: apiKey,
        generationConfig: gai.GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _buildResponseSchema(availableHeads),
        ),
      );

      final prompt = _buildTextPrompt(
        ocrText,
        availableHeads,
        availableSubHeads,
        _buildLocationBlock(tripLocations),
      );

      final response = await model.generateContent([
        gai.Content.text(prompt),
      ]);

      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) {
        return null;
      }
      return _parseJsonResponse(rawText);
    } catch (e) {
      debugPrint('GeminiService._analyzeFromText error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _analyzeFromImage(
    String apiKey,
    List<String> imagePaths,
    List<String> availableHeads,
    Map<String, List<String>> availableSubHeads,
    List<String>? tripLocations, {
    String? modelName,
  }) async {
    try {
      final selectedModel = (modelName != null && modelName.trim().isNotEmpty)
          ? modelName.trim()
          : GeminiRepository.defaultModel;

      final model = gai.GenerativeModel(
        model: selectedModel,
        apiKey: apiKey,
        generationConfig: gai.GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _buildResponseSchema(availableHeads),
        ),
      );
      // Support multi-page hotel folios and itinerary tickets up to 6 pages
      final toSend = imagePaths.take(6).toList();
      final parts = <gai.Part>[gai.TextPart(_buildImagePrompt(
        availableHeads, availableSubHeads,
        _buildLocationBlock(tripLocations),
        imageCount: toSend.length,
      ))];
      for (final path in toSend) {
        var bytes = await XFile(path).readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null &&
            (decoded.width > 1280 || decoded.height > 1280)) {
          final resized = decoded.width >= decoded.height
              ? img.copyResize(decoded, width: 1280)
              : img.copyResize(decoded, height: 1280);
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
          'GeminiService: empty response. candidates=${response.candidates.length}',
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
    String? modelName,
  }) async {
    if (imagePaths.isEmpty) return null;

    // Smart Hybrid Pipeline: Try fast on-device OCR first for single printed receipts
    if (imagePaths.length == 1 && !kIsWeb) {
      try {
        final ocrText = await OcrService.extractTextFromImagePath(imagePaths.first);
        if (ocrText != null && OcrService.isOcrSufficient(ocrText)) {
          debugPrint('GeminiService: High quality OCR text extracted (${ocrText.length} chars), using fast text prompt');
          final result = await _analyzeFromText(
            apiKey,
            ocrText,
            availableHeads,
            availableSubHeads,
            tripLocations,
            modelName: modelName,
          );
          if (result != null && result['amount'] != null) {
            return result;
          }
          debugPrint('GeminiService: Text analysis incomplete, falling back to Vision');
        }
      } catch (e) {
        debugPrint('GeminiService: OCR check failed ($e), falling back to Vision');
      }
    }

    // Multimodal Vision Fallback & Multi-page document handling
    return _analyzeFromImage(
      apiKey,
      imagePaths,
      availableHeads,
      availableSubHeads,
      tripLocations,
      modelName: modelName,
    );
  }

  /// Performs a lightweight connectivity test with the given API key and model.
  /// Sends a minimal "Ping" request to verify authorization, quota, and model existence.
  Future<({bool success, String message})> testConnection({
    required String apiKey,
    String? modelName,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return (success: false, message: 'API key cannot be empty');
    }

    final selectedModel = (modelName != null && modelName.trim().isNotEmpty)
        ? modelName.trim()
        : GeminiRepository.defaultModel;

    try {
      final model = gai.GenerativeModel(
        model: selectedModel,
        apiKey: key,
      );

      final response = await model.generateContent([
        gai.Content.text('Ping'),
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        return (
          success: true,
          message: 'Connection successful! "$selectedModel" is ready.',
        );
      } else {
        return (
          success: false,
          message: 'Received empty response from Gemini.',
        );
      }
    } catch (e) {
      final err = e.toString();
      if (err.contains('404') ||
          err.contains('not found') ||
          err.contains('NotFound') ||
          err.contains('is not found')) {
        return (
          success: false,
          message: 'Model "$selectedModel" not found or not yet available (404).',
        );
      } else if (err.contains('400') ||
          err.contains('API_KEY_INVALID') ||
          err.contains('API key not valid') ||
          err.contains('invalid api key')) {
        return (
          success: false,
          message: 'Invalid Gemini API key (400).',
        );
      } else if (err.contains('429') ||
          err.contains('RESOURCE_EXHAUSTED') ||
          err.contains('quota')) {
        return (
          success: false,
          message: 'Quota exceeded or rate limit reached (HTTP 429).',
        );
      } else if (err.contains('SocketException') ||
          err.contains('Failed host lookup') ||
          err.contains('Network is unreachable')) {
        return (
          success: false,
          message: 'Network error. Please check your internet connection.',
        );
      }
      return (
        success: false,
        message: 'Connection failed: $e',
      );
    }
  }
}

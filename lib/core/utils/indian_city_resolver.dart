import 'dart:math' as math;

import '../constants/indian_cities.dart';

class IndianCity {
  final String name;
  final String state;

  const IndianCity(this.name, this.state);

  @override
  String toString() => name;
}

/// Maps free text (AI output, user input, receipt addresses) to a canonical
/// Indian city, or null when no city can be identified with confidence.
///
/// Resolution is deterministic: the same input always gives the same output.
/// Order of attempts:
///   1. Explicit airport / railway station code
///   2. Exact match of the whole text, then of each comma-separated part
///      (after removing words like "Airport", "Terminal 1D", "Junction")
///   3. A city name at the start or end of a part ("Kempegowda Bengaluru")
///   4. Upper-case codes inside the text ("Delhi (DEL)")
///   5. Close spelling match ("Banglore" → Bengaluru), stricter unless the
///      match is one of the [preferred] trip cities
class IndianCityResolver {
  IndianCityResolver._();

  static final Map<String, IndianCity> _byKey = {};
  static final Map<String, IndianCity> _byCode = {};
  static final List<IndianCity> _cities = [];

  /// Words that describe a place within a city rather than the city itself.
  static const Set<String> _noiseWords = {
    'airport', 'international', 'intl', 'domestic', 'terminal', 'term',
    't1', 't2', 't3', 't1d', 't1c', '1d', '1c', '2', '3',
    'railway', 'rly', 'station', 'stn', 'junction', 'jn', 'jct', 'junc',
    'cantt', 'cantonment', 'central', 'city', 'bus', 'stand', 'depot',
    'isbt', 'metro', 'district', 'dist', 'india', 'ind',
  };

  /// City names that are also everyday words or common personal names.
  /// They still match when they are the whole text, but are not picked out
  /// of longer text such as "Ratna Sagar Hotel" or "Anand Vihar".
  static const Set<String> _ambiguousWords = {
    'anand', 'sagar', 'mandi', 'basti', 'hassan', 'rampur', 'banda', 'kota',
    'puri', 'pali', 'guna', 'durg', 'gaya', 'salem', 'diu', 'leh',
    'orai', 'etah', 'moga', 'tonk', 'jind', 'beed', 'karad', 'angul', 'dewas',
    'sirsa', 'kolar', 'gadag', 'hampi', 'daman', 'dwarka', 'nalanda', 'bhind',
    'katra', 'manipal', 'amaravati', 'ramgarh', 'kangra', 'chamba', 'solan',
  };

  static void _ensureLoaded() {
    if (_cities.isNotEmpty) return;
    for (final rawLine in indianCitiesData.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length < 2) continue;
      final city = IndianCity(parts[0].trim(), parts[1].trim());
      _cities.add(city);
      _byKey.putIfAbsent(normalize(city.name), () => city);
      if (parts.length > 2) {
        for (final alias in parts[2].split(',')) {
          final key = normalize(alias);
          if (key.isNotEmpty) _byKey.putIfAbsent(key, () => city);
        }
      }
      if (parts.length > 3) {
        for (final code in parts[3].split(',')) {
          final c = code.trim().toUpperCase();
          if (c.isNotEmpty) _byCode.putIfAbsent(c, () => city);
        }
      }
    }
  }

  static List<String>? _sortedNames;

  /// All canonical city names, sorted alphabetically.
  static List<String> get allCityNames {
    _ensureLoaded();
    return _sortedNames ??= List.unmodifiable(
      _cities.map((c) => c.name).toList()..sort(),
    );
  }

  /// Lower-case, letters/digits only, single spaces.
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static String _stripNoise(String normalized) {
    return normalized
        .split(' ')
        .where((w) => w.isNotEmpty && !_noiseWords.contains(w))
        .join(' ');
  }

  /// Resolves [text] (and optional airport/station [code]) to a city.
  /// When [preferred] cities are given (e.g. the trip's cities), a fuzzy or
  /// partial match that agrees with one of them wins over other candidates.
  static IndianCity? resolve(
    String? text, {
    String? code,
    Iterable<String> preferred = const [],
  }) {
    _ensureLoaded();

    if (code != null) {
      final byCode = _byCode[code.trim().toUpperCase()];
      if (byCode != null) return byCode;
    }
    if (text == null) return null;
    final raw = text.trim();
    if (raw.isEmpty) return null;

    final preferredNames = <String>{};
    for (final p in preferred) {
      final city = _byKey[normalize(p)];
      if (city != null) preferredNames.add(city.name);
    }

    // Candidate segments: whole text, text outside brackets, text inside
    // brackets, then comma / slash / hyphen separated parts.
    final segments = <String>[raw];
    final outside = raw.replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]'), ' ');
    segments.add(outside);
    for (final m in RegExp(r'\(([^)]*)\)').allMatches(raw)) {
      segments.add(m.group(1)!);
    }
    segments.addAll(outside.split(RegExp(r'[,/;|\n]| - | – ')));

    final normalizedSegments = <String>[];
    for (final s in segments) {
      final n = normalize(s);
      if (n.isEmpty) continue;
      normalizedSegments.add(n);

      // 2. Exact match, with and without noise words.
      final exact = _byKey[n] ?? _byKey[_stripNoise(n)];
      if (exact != null) return exact;
    }

    // 3. City name at the start or end of a segment.
    final windowMatches = <IndianCity>[];
    for (final n in normalizedSegments) {
      final words = _stripNoise(n).split(' ').where((w) => w.isNotEmpty).toList();
      for (var len = math.min(3, words.length); len >= 1; len--) {
        for (final window in [
          words.sublist(words.length - len), // suffix
          words.sublist(0, len), // prefix
        ]) {
          if (len == 1) {
            final w = window.first;
            if (w.length < 3 || _ambiguousWords.contains(w)) continue;
          }
          final city = _byKey[window.join(' ')];
          if (city != null) windowMatches.add(city);
        }
      }
    }
    if (windowMatches.isNotEmpty) {
      return windowMatches.firstWhere(
        (c) => preferredNames.contains(c.name),
        orElse: () => windowMatches.first,
      );
    }

    // 4. Upper-case code tokens in the original text, e.g. "Delhi (DEL)".
    for (final m in RegExp(r'\b[A-Z]{3,5}\b').allMatches(raw)) {
      final city = _byCode[m.group(0)!];
      if (city != null) return city;
    }

    // 5. Close spelling match on whole segments.
    return _fuzzyMatch(normalizedSegments, preferredNames);
  }

  /// Spelling-tolerant match. A near miss is accepted readily when it is one
  /// of the [preferredNames] (trip cities), otherwise only when it is very
  /// close and clearly better than any other city. This keeps real small
  /// towns (e.g. "Jaitpur") from being turned into a nearby big city.
  static IndianCity? _fuzzyMatch(
    List<String> normalizedSegments,
    Set<String> preferredNames,
  ) {
    const preferredThreshold = 0.90;
    const generalThreshold = 0.975;
    const minMargin = 0.01;

    IndianCity? best;
    var bestScore = 0.0;
    var runnerUpScore = 0.0;

    for (final n in normalizedSegments) {
      final candidate = _stripNoise(n);
      if (candidate.length < 5) continue;
      for (final entry in _byKey.entries) {
        if (entry.key.length < 5) continue;
        final score = jaroWinkler(candidate, entry.key);
        if (score > bestScore) {
          if (best != null && best != entry.value) runnerUpScore = bestScore;
          bestScore = score;
          best = entry.value;
        } else if (entry.value != best && score > runnerUpScore) {
          runnerUpScore = score;
        }
      }
    }
    if (best == null) return null;
    if (preferredNames.contains(best.name) && bestScore >= preferredThreshold) {
      return best;
    }
    if (bestScore >= generalThreshold && bestScore - runnerUpScore >= minMargin) {
      return best;
    }
    return null;
  }

  /// Canonical city name for [text], or null when it is not a recognised city.
  static String? canonicalName(
    String? text, {
    String? code,
    Iterable<String> preferred = const [],
  }) =>
      resolve(text, code: code, preferred: preferred)?.name;

  /// Comparison key: canonical name when recognised, otherwise normalised text.
  /// "New Delhi", "DELHI" and "Delhi (DEL)" all give the same key.
  static String comparisonKey(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    return (resolve(text)?.name ?? normalize(text)).toLowerCase();
  }

  /// Jaro-Winkler similarity in [0, 1].
  static double jaroWinkler(String s1, String s2) {
    if (s1 == s2) return 1.0;
    final len1 = s1.length;
    final len2 = s2.length;
    if (len1 == 0 || len2 == 0) return 0.0;

    final matchDistance = math.max(0, math.max(len1, len2) ~/ 2 - 1);
    final s1Matches = List<bool>.filled(len1, false);
    final s2Matches = List<bool>.filled(len2, false);
    var matches = 0;
    for (var i = 0; i < len1; i++) {
      final start = math.max(0, i - matchDistance);
      final end = math.min(i + matchDistance + 1, len2);
      for (var j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }
    if (matches == 0) return 0.0;

    var transpositions = 0;
    var k = 0;
    for (var i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) {
        k++;
      }
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }
    final m = matches.toDouble();
    final jaro =
        (m / len1 + m / len2 + (m - transpositions / 2) / m) / 3.0;

    var prefix = 0;
    for (var i = 0; i < math.min(4, math.min(len1, len2)); i++) {
      if (s1[i] != s2[i]) break;
      prefix++;
    }
    return jaro + prefix * 0.1 * (1 - jaro);
  }
}

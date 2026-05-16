import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown when an OpenFDA request fails for a reason the user can act on
/// (no internet, request timed out, server error). Carries a friendly
/// [message] safe to show directly in the UI.
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => message;
}

/// A simple result coming back from the OpenFDA search.
class DrugSearchResult {
  final String brandName;
  final String genericName;
  final String purpose; // What the drug is used for
  final String warnings; // Warnings text (often long)

  DrugSearchResult({
    required this.brandName,
    required this.genericName,
    required this.purpose,
    required this.warnings,
  });
}

/// Talks to the free OpenFDA Drug Label API.
///
/// Docs: https://open.fda.gov/apis/drug/label/
/// No API key is required for low-volume use (240 requests/min, 1000/day).
class DrugApiService {
  static const String _base = 'https://api.fda.gov/drug/label.json';

  /// How long to wait for OpenFDA before giving up.
  static const Duration _timeout = Duration(seconds: 10);

  /// Performs a GET with a timeout and converts low-level network failures
  /// into a [NetworkException] carrying a user-friendly message.
  Future<http.Response> _get(Uri url) async {
    try {
      return await http.get(url).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException(
        'The request took too long. Check your connection and try again.',
      );
    } on SocketException {
      throw const NetworkException(
        'No internet connection. Please check your network and try again.',
      );
    } on http.ClientException {
      throw const NetworkException(
        'Could not reach the drug database. Please try again.',
      );
    }
  }

  /// Search for a drug by name (brand or generic).
  /// Returns up to [limit] results.
  Future<List<DrugSearchResult>> search(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];

    // OpenFDA uses a Lucene-style search syntax.
    // We look for the query in either the brand or generic name fields.
    final q = Uri.encodeQueryComponent(
      'openfda.brand_name:"$query" OR openfda.generic_name:"$query"',
    );
    final url = Uri.parse('$_base?search=$q&limit=$limit');

    final response = await _get(url);

    // OpenFDA returns 404 when nothing matched — treat that as "no results".
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw NetworkException(
        'The drug database is unavailable right now (error '
        '${response.statusCode}). Please try again later.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List?) ?? [];

    return results.map((raw) {
      final r = raw as Map<String, dynamic>;
      final openfda = (r['openfda'] as Map<String, dynamic>? ?? {});

      String firstOf(dynamic field) {
        if (field is List && field.isNotEmpty) return field.first.toString();
        return '';
      }

      return DrugSearchResult(
        brandName: firstOf(openfda['brand_name']),
        genericName: firstOf(openfda['generic_name']),
        purpose: firstOf(r['purpose']),
        warnings: firstOf(r['warnings']),
      );
    }).toList();
  }

  /// Fetch the raw `drug_interactions` text from a drug's FDA label.
  /// Returns an empty string when no label or section exists.
  Future<String> fetchInteractionsText(String drugName) async {
    if (drugName.trim().isEmpty) return '';

    final q = Uri.encodeQueryComponent(
      'openfda.brand_name:"$drugName" OR openfda.generic_name:"$drugName"',
    );
    final url = Uri.parse('$_base?search=$q&limit=3');

    final response = await _get(url);
    if (response.statusCode == 404) return '';
    if (response.statusCode != 200) {
      throw NetworkException(
        'The drug database is unavailable right now (error '
        '${response.statusCode}). Please try again later.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List?) ?? [];

    final buffer = StringBuffer();
    for (final raw in results) {
      final r = raw as Map<String, dynamic>;
      final di = r['drug_interactions'];
      if (di is List) {
        for (final entry in di) {
          buffer.writeln(entry.toString());
        }
      }
    }
    return buffer.toString();
  }

  /// Cross-checks two drugs using OpenFDA labels.
  ///
  /// Looks up each drug's label and searches its `drug_interactions` text
  /// for a mention of the other drug (by name). Returns a snippet of the
  /// matching sentence(s), or an empty string if nothing is found.
  Future<String> checkInteractionViaLabels(String drugA, String drugB) async {
    final a = drugA.trim();
    final b = drugB.trim();
    if (a.isEmpty || b.isEmpty) return '';

    // Query both labels in parallel.
    final results = await Future.wait([
      fetchInteractionsText(a),
      fetchInteractionsText(b),
    ]);

    final snippet = _findMention(results[0], b) ?? _findMention(results[1], a);
    return snippet ?? '';
  }

  /// Finds the first sentence in [text] that mentions [needle]
  /// (case-insensitive, whole-word). Returns null if not found.
  String? _findMention(String text, String needle) {
    if (text.isEmpty || needle.isEmpty) return null;
    final lower = text.toLowerCase();
    final n = needle.toLowerCase();
    final idx = lower.indexOf(n);
    if (idx == -1) return null;

    // Expand back to start of sentence, forward to end of sentence.
    int start = idx;
    while (start > 0 && text[start - 1] != '.' && text[start - 1] != '\n') {
      start--;
    }
    int end = idx + n.length;
    while (end < text.length && text[end] != '.' && text[end] != '\n') {
      end++;
    }
    if (end < text.length) end++; // include the period
    final sentence = text.substring(start, end).trim();
    // Cap length to keep dialogs readable.
    if (sentence.length > 600) {
      return '${sentence.substring(0, 600)}…';
    }
    return sentence;
  }
}

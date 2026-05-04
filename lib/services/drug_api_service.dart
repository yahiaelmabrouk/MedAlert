import 'dart:convert';
import 'package:http/http.dart' as http;

/// A simple result coming back from the OpenFDA search.
class DrugSearchResult {
  final String brandName;
  final String genericName;
  final String purpose;       // What the drug is used for
  final String warnings;      // Warnings text (often long)

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

    final response = await http.get(url);

    // OpenFDA returns 404 when nothing matched — treat that as "no results".
    if (response.statusCode == 404) return [];
    if (response.statusCode != 200) {
      throw Exception('OpenFDA error ${response.statusCode}');
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
}

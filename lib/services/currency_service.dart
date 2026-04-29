import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const _url = 'https://open.er-api.com/v6/latest/EUR';

  /// Fetches live exchange rates with EUR as the base currency.
  /// Returns a map of currency code → rate (e.g. {'USD': 1.08, 'GBP': 0.86, ...}).
  /// Throws on network failure or non-200 response.
  static Future<Map<String, double>> fetchRates() async {
    final response = await http
        .get(Uri.parse(_url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final raw = data['rates'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    throw Exception('Currency fetch failed: ${response.statusCode}');
  }
}

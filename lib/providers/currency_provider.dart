import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/currency_service.dart';

/// Fetches EUR-based exchange rates once per session from open.er-api.com.
/// Cached automatically by Riverpod; invalidate to force a refresh.
final exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) {
  return CurrencyService.fetchRates();
});

/// Convenience: EUR → USD rate extracted from [exchangeRatesProvider].
/// Falls back to 1.08 while loading or on network error so the UI
/// never blocks on the fetch.
final eurToUsdRateProvider = Provider<double>((ref) {
  return ref.watch(exchangeRatesProvider).valueOrNull?['USD'] ?? 1.08;
});

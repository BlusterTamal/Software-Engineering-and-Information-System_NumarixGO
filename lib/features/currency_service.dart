import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- Currency Service (Simplified) ---
class CurrencyService {
  static const String primaryApiUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String fallbackApiUrl = 'https://api.frankfurter.app/latest';
  static const String cacheKey = 'cachedRates';
  static const String cacheTimestampKey = 'cachedTimestamp';

  Future<Map<String, dynamic>> getLatestRates(String fromCurrency) async {
    try {
      final response = await http.get(Uri.parse('$primaryApiUrl/$fromCurrency')).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cacheDataAsync(response.body);
        return data;
      }
    } catch (e) {
      print('Primary API failed: $e');
    }

    try {
      final response = await http.get(Uri.parse('$fallbackApiUrl?from=$fromCurrency')).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cacheDataAsync(response.body);
        return data;
      }
    } catch (e) {
      print('Fallback API failed: $e');
    }

    return await loadFromCache();
  }

  void _cacheDataAsync(String responseBody) {
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, responseBody);
      await prefs.setInt(cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    });
  }

  // --- REMOVED getHistoricalRates() ---
  // The historical API was the source of the error as it didn't support BDT.
  // Since the chart is removed, this function is no longer needed.

  Future<Map<String, dynamic>> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    throw Exception('Failed to load data and no cache available');
  }

  Future<DateTime?> getCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(cacheTimestampKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}
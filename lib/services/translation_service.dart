import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static Map<String, dynamic>? _cachedTranslations;

  /// Fetches translations from the online JSON file
  static Future<Map<String, dynamic>> fetchTranslations() async {
    if (_cachedTranslations != null) {
      return _cachedTranslations!;
    }

    try {
      final response = await http.get(
        Uri.parse("https://maha-krushi-mittra.vercel.app/language.json"),
      );

      if (response.statusCode == 200) {
        _cachedTranslations = json.decode(response.body);
        return _cachedTranslations!;
      } else {
        throw Exception("Failed to load translations: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load translations: $e");
    }
  }

  /// Gets text for a specific page and key based on the selected language
  static String getText(Map<String, dynamic> data, String page, String key, String selectedLanguage) {
    try {
      // Convert language names to lowercase keys used in JSON
      String languageKey = _getLanguageKey(selectedLanguage);

      return data[page]?[key]?[languageKey] ??
          data[page]?[key]?['english'] ??
          "Text not found";
    } catch (e) {
      return "Error: $key";
    }
  }

  /// Converts display language names to JSON keys
  static String _getLanguageKey(String selectedLanguage) {
    switch (selectedLanguage.toLowerCase()) {
      case 'english':
        return 'english';
      case 'हिन्दी':
        return 'hindi';
      case 'मराठी':
        return 'marathi';
      case 'ਪੰਜਾਬੀ':
        return 'punjabi';
      case 'ಕನ್ನಡ':
        return 'kannada';
      case 'தமிழ்':
        return 'tamil';
      case 'తెలుగు':
        return 'telugu';
      case 'മലയാളം':
        return 'malayalam';
      case 'ગુજરાતી':
        return 'gujarati';
      case 'বাংলা':
        return 'bengali';
      case 'ଓଡ଼ିଆ':
        return 'odia';
      case 'اردو':
        return 'urdu';
      default:
        return 'english';
    }
  }

  /// Clears cached translations (useful when language is changed)
  static void clearCache() {
    _cachedTranslations = null;
  }
}
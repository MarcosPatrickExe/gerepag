import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _geminiKey = 'gemini_api_key';
  static const String _openaiKey = 'openai_api_key';
  static const String _providerKey = 'ai_provider_active';
  static const String _autoBusinessAiKey = 'auto_business_ai';

  Future<List<String>> getGeminiApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_geminiKey)?.trim();
    if (key == null || key.isEmpty || key == 'API_KEY_AQUI') return [];
    return [key];
  }

  Future<String?> getGeminiApiKey() async {
    final keys = await getGeminiApiKeys();
    return keys.isEmpty ? null : keys.first;
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key.trim());
  }

  Future<String?> getOpenAIApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_openaiKey)?.trim();
  }

  Future<void> setOpenAIApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openaiKey, key.trim());
  }

  Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerKey) ?? 'gemini';
  }

  Future<void> setAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider);
  }

  Future<bool> getAutoBusinessAi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBusinessAiKey) ?? true;
  }

  Future<void> setAutoBusinessAi(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBusinessAiKey, enabled);
  }

  Future<bool> hasAiKey() async {
    final provider = await getAiProvider();
    final key = provider == 'gemini'
        ? await getGeminiApiKey()
        : await getOpenAIApiKey();
    return key != null && key.isNotEmpty && key != 'API_KEY_AQUI';
  }
}

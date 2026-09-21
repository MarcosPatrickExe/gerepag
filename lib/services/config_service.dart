import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _geminiKey = 'gemini_api_key';
  static const String _openaiKey = 'openai_api_key';
  static const String _providerKey = 'ai_provider_active'; // 'gemini' ou 'openai'
  static const String _autoBusinessAiKey = 'auto_business_ai';

  Future<List<String>> getGeminiApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_geminiKey);
    List<String> keys = [];
    if (key != null && key.isNotEmpty && key != 'API_KEY_AQUI') {
      keys.add(key.trim());
    }
    // Chaves padrão fornecidas pelo usuário para redundância
    keys.add('AIzaSyAGyJXTanZ-8PFfw9ZGkyIBBilmQfzz5Zs');
    keys.add('AIzaSyCvLWubEKLmgyL5pPhrNfHLhO6FmuNZcc4');
    
    return keys.toSet().toList(); // Remover duplicatas
  }

  Future<String?> getGeminiApiKey() async {
    final keys = await getGeminiApiKeys();
    return keys.first;
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key.trim());
  }

  Future<String?> getOpenAIApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_openaiKey);
    return key?.trim();
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
    if (provider == 'gemini') {
      final key = await getGeminiApiKey();
      return key != null && key.isNotEmpty && key != 'API_KEY_AQUI';
    } else {
      final key = await getOpenAIApiKey();
      return key != null && key.isNotEmpty;
    }
  }
}

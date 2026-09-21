import 'package:shared_preferences/shared_preferences.dart';

class FeatureDiscoveryService {
  static final FeatureDiscoveryService _instance = FeatureDiscoveryService._internal();
  factory FeatureDiscoveryService() => _instance;
  FeatureDiscoveryService._internal();

  static const String _tourCompletedKey = 'feature_tour_v2_completed'; // Versão 2: Faturas, Ajustes e Alertas

  Future<bool> shouldShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_tourCompletedKey) ?? false);
  }

  Future<void> markTourAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, false);
  }
}

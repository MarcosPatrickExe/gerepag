import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class BioAuthService {
  static final BioAuthService _instance = BioAuthService._internal();
  factory BioAuthService() => _instance;
  BioAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _authEnabledKey = 'bio_auth_enabled';

  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false; // Biometria nativa não suportada no Chrome desta forma
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      print('Erro ao verificar biometria: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return true; // Ignorar autenticação biométrica no Web (sempre autenticado)
    try {
      return await _auth.authenticate(
        localizedReason: 'Autentique-se para acessar o GerePag',
      );
    } catch (e) {
      print('Erro na autenticação: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authEnabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authEnabledKey, enabled);
  }
}

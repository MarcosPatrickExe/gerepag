import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false; // Biometria nativa não disponível no Chrome
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print('Erro ao verificar biometria: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return true; // No Web, permitimos o acesso ou usamos outra trava
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar suas finanças',
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Erro na autenticação: $e');
      return false;
    }
  }
}

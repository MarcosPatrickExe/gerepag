import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exclui os dados privados do usuário autenticado e sua conta Firebase.
///
/// A exclusão de contextos compartilhados (por exemplo, família, BPO ou dados
/// sujeitos a retenção fiscal) precisa ser tratada pelo fluxo de backend e pela
/// política de privacidade antes do lançamento público.
class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final FirebaseAuth _auth;
  final FirebaseDatabase _database;
  final Future<SharedPreferences> Function() _preferencesLoader;

  /// Exige a senha atual para que o Firebase considere a sessão recente.
  ///
  /// As atualizações do Realtime Database são agrupadas para não deixar parte
  /// dos dados individuais do usuário persistida entre os nós conhecidos.
  Future<void> deleteCurrentAccount({required String password}) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      throw const AccountDeletionException(
        'Entre novamente com uma conta de e-mail e senha para excluir a conta.',
      );
    }

    if (password.isEmpty) {
      throw const AccountDeletionException('Informe sua senha atual para continuar.');
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (error) {
      throw AccountDeletionException(_messageFor(error));
    }

    try {
      await _database.ref().update({
        'users/${user.uid}': null,
        'omie_sync/${user.uid}': null,
      });
      await user.delete();

      final preferences = await _preferencesLoader();
      await preferences.clear();
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AccountDeletionException(_messageFor(error));
    } on FirebaseException catch (_) {
      throw const AccountDeletionException(
        'Não foi possível excluir os dados agora. Verifique sua conexão e tente novamente.',
      );
    }
  }

  static String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'A senha informada não confere.';
      case 'requires-recent-login':
        return 'Entre novamente e tente excluir a conta mais uma vez.';
      case 'network-request-failed':
        return 'Sem conexão. Verifique a internet e tente novamente.';
      default:
        return 'Não foi possível concluir a exclusão da conta. Tente novamente.';
    }
  }
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/realtime_db_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    if (kIsWeb) return;

    // 1. Solicitar permissões (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuário permitiu notificações push.');
      
      // 2. Obter Token e salvar no Firebase
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      // 3. Ouvir renovação de token
      _fcm.onTokenRefresh.listen(_saveToken);

      // 4. Configurar listeners de mensagens
      _setupMessageHandlers();
    }
  }

  static Future<void> _saveToken(String token) async {
    final realtime = RealtimeDbService();
    // Salva o token sob o perfil do usuário para que o servidor saiba para quem enviar
    await realtime.updateUserProfile({'fcmToken': token});
    debugPrint('Token FCM salvo: $token');
  }

  static void _setupMessageHandlers() {
    // Escuta mensagens quando o app está em primeiro plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Recebi mensagem em Foreground: ${message.notification?.title}');
      // Aqui poderíamos disparar uma notificação local se quisermos
    });

    // Escuta quando o usuário clica na notificação e o app abre
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App aberto via Notificação Push: ${message.data}');
    });
  }

  // Função estática para lidar com mensagens em background (deve ser top-level)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint("Lidando com mensagem em Background: ${message.messageId}");
  }
}

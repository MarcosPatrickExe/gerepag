import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  static const String _billingApiBaseUrl = String.fromEnvironment(
    'GEREPAG_BILLING_API_BASE_URL',
  );

  String get _baseUrl {
    final value = _billingApiBaseUrl.trim();
    if (value.isEmpty) {
      throw StateError(
        'GEREPAG_BILLING_API_BASE_URL não foi configurada no build.',
      );
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<Map<String, String>> _authenticatedHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError(
        'É necessário autenticar antes de iniciar uma cobrança.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Solicita ao backend uma sessão Stripe Checkout.
  ///
  /// O servidor valida usuário, plano, preço e moeda antes de usar a chave
  /// secreta Stripe. Segredos Stripe nunca pertencem ao aplicativo cliente.
  Future<Map<String, String>?> createCheckoutSession({
    required String planName,
    required double amount,
    required String interval,
    int intervalCount = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/checkout/sessions'),
        headers: await _authenticatedHeaders(),
        body: jsonEncode({
          'planName': planName,
          'amount': amount,
          'interval': interval,
          'intervalCount': intervalCount,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url']?.toString();
      final id = data['id']?.toString();
      if (url == null || id == null || url.isEmpty || id.isEmpty) return null;
      return {'url': url, 'id': id};
    } catch (_) {
      return null;
    }
  }

  /// Consulta o backend; a confirmação definitiva deve ocorrer no servidor
  /// por webhook Stripe idempotente.
  Future<bool> verifyPaymentStatus(String sessionId) async {
    try {
      final encodedSessionId = Uri.encodeComponent(sessionId);
      final response = await http.get(
        Uri.parse('$_baseUrl/checkout/sessions/$encodedSessionId'),
        headers: await _authenticatedHeaders(),
      );
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['paid'] == true ||
          data['paymentStatus'] == 'paid' ||
          data['status'] == 'complete';
    } catch (_) {
      return false;
    }
  }

  Future<bool> launchStripeCheckout(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

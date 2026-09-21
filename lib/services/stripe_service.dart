import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  // Chaves de Produção (Enviadas pelo usuário)
  static const String _secretKey = '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';

  /// Cria uma sessão de checkout e retorna um mapa com a URL e o ID da Sessão.
  Future<Map<String, String>?> createCheckoutSession({
    required String planName, 
    required double amount, 
    required String interval, 
    int intervalCount = 1
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_method_types[0]': 'card',
          'line_items[0][price_data][currency]': 'brl',
          'line_items[0][price_data][product_data][name]': 'GerePag - $planName',
          'line_items[0][price_data][unit_amount]': (amount * 100).toInt().toString(),
          'line_items[0][price_data][recurring][interval]': interval, 
          'line_items[0][price_data][recurring][interval_count]': intervalCount.toString(),
          'line_items[0][quantity]': '1',
          'mode': 'subscription',
          'success_url': 'https://gerepag-ai.web.app/#/success',
          'cancel_url': 'https://gerepag-ai.web.app/#/upgrade',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'url': data['url'],
          'id': data['id'],
        };
      } else {
        print('❌ Erro Stripe API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erro de conexão Stripe: $e');
      return null;
    }
  }

  /// Verifica se o pagamento de uma sessão específica foi concluído com sucesso.
  Future<bool> verifyPaymentStatus(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/checkout/sessions/$sessionId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentStatus = data['payment_status']; // 'paid' significa sucesso
        final status = data['status']; // 'complete' significa sessão finalizada
        
        print('🧠 [STRIPE] Status da Sessão: $status, Pagamento: $paymentStatus');
        
        return paymentStatus == 'paid' || status == 'complete';
      }
      return false;
    } catch (e) {
      print('❌ Erro ao verificar pagamento: $e');
      return false;
    }
  }

  Future<bool> launchStripeCheckout(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('❌ Erro ao abrir checkout: $e');
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';

class OcrResult {
  final String? restaurant;
  final double? amount;
  final DateTime? date;
  final String? boletoKey;
  final String? danfeIssuer;
  final bool isBoleto;
  final bool isDanfe;
  final bool isIncome;
  final bool isTaxGuide;
  final String? taxType; // DAS, DARF, FGTS, GPS, ISS, ICMS
  final String? scannedCnpj;
  final String? barCode;
  final String? pixCopyPaste;
  final DateTime? dueDate;

  OcrResult({
    this.restaurant,
    this.amount,
    this.date,
    this.boletoKey,
    this.danfeIssuer,
    this.isBoleto = false,
    this.isDanfe = false,
    this.isIncome = false,
    this.isTaxGuide = false,
    this.taxType,
    this.scannedCnpj,
    this.barCode,
    this.pixCopyPaste,
    this.dueDate,
  });
}

class OcrService {
  final TextRecognizer? _textRecognizer;

  OcrService()
      : _textRecognizer = kIsWeb
            ? null
            : TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(String imagePath) async {
    String fullText = '';

    if (kIsWeb) {
      try {
        final uri = Uri.parse(imagePath);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

          final ocrResponse = await http.post(
            Uri.parse('https://api.ocr.space/parse/image'),
            headers: {'apikey': 'helloworld'},
            body: {
              'base64image': base64Image,
              'language': 'por',
            },
          );

          if (ocrResponse.statusCode == 200) {
            final json = jsonDecode(ocrResponse.body);
            if (json['ParsedResults'] != null && json['ParsedResults'].isNotEmpty) {
              fullText = json['ParsedResults'][0]['ParsedText'] ?? '';
            }
          }
        }
      } catch (e) {
        print('⚠️ Error in Web OCR: $e');
      }
      
      if (fullText.isEmpty) {
        return OcrResult(
          restaurant: null,
          amount: null,
          date: DateTime.now(),
          isBoleto: false,
          isDanfe: false,
        );
      }
    } else {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      fullText = recognizedText.text;
    }

    return _parseExtractedText(fullText);
  }

  OcrResult _parseExtractedText(String fullText) {
    List<String> lines = fullText.split('\n');

    String? restaurant;
    double? totalAmount;
    DateTime? date;

    // 1. Tentar pegar o nome do estabelecimento (geralmente a primeira ou segunda linha)
    if (lines.isNotEmpty) {
      restaurant = lines[0].trim();
      // Se a primeira linha for muito curta ou só números, tenta a segunda
      if (restaurant.length < 3 && lines.length > 1) {
        restaurant = lines[1].trim();
      }
    }

    // 2. Regex para Valor (Procura R$ ou valores com vírgula/ponto)
    // Tenta encontrar o maior valor da nota, que geralmente é o TOTAL
    final RegExp amountRegExp = RegExp(r'(?:R\$|TOTAL|VALOR)\s*[:]?\s*(\d+[.,]\d{2})', caseSensitive: false);
    final RegExp genericAmountRegExp = RegExp(r'(\d+[.,]\d{2})');

    Iterable<RegExpMatch> matches = amountRegExp.allMatches(fullText);
    if (matches.isEmpty) {
      matches = genericAmountRegExp.allMatches(fullText);
    }

    List<double> foundAmounts = [];
    for (var match in matches) {
      String val = match.group(1)!.replaceAll(',', '.');
      foundAmounts.add(double.tryParse(val) ?? 0.0);
    }

    if (foundAmounts.isNotEmpty) {
      // O maior valor geralmente é o total
      totalAmount = foundAmounts.reduce((a, b) => a > b ? a : b);
    }

    // 3. Regex para Data (dd/mm/aaaa ou dd/mm/yy)
    final RegExp dateRegExp = RegExp(r'(\d{2}/\d{2}/\d{2,4})');
    final dateMatch = dateRegExp.firstMatch(fullText);
    if (dateMatch != null) {
      try {
        String rawDate = dateMatch.group(1)!;
        List<String> parts = rawDate.split('/');
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        date = DateTime(year, month, day);
      } catch (_) {}
    }

    // 4. Detectar Boleto (Linha Digitável de 47 ou 48 dígitos)
    String? boletoKey;
    bool isBoleto = false;
    final RegExp boletoBankRegExp = RegExp(r'(\d{5}\.?\d{5}\s?\d{5}\.?\d{6}\s?\d{5}\.?\d{6}\s?\d\s?\d{14})');
    final RegExp boletoConcessionariaRegExp = RegExp(r'(\d{11,12}\s?\d{11,12}\s?\d{11,12}\s?\d{11,12})');

    final cleanText = fullText.replaceAll('\n', ' ');
    final boletoBankMatch = boletoBankRegExp.firstMatch(cleanText);
    final boletoConcessionariaMatch = boletoConcessionariaRegExp.firstMatch(cleanText);

    if (boletoBankMatch != null) {
      boletoKey = boletoBankMatch.group(1)!.replaceAll(RegExp(r'\s|\.'), '');
      isBoleto = true;
    } else if (boletoConcessionariaMatch != null) {
      boletoKey = boletoConcessionariaMatch.group(1)!.replaceAll(RegExp(r'\s|\.'), '');
      isBoleto = true;
    } else {
      // Procurar linhas que, limpas de pontuação, tenham exatamente 47 ou 48 dígitos
      for (String line in lines) {
        final cleanLine = line.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanLine.length == 47 || cleanLine.length == 48) {
          boletoKey = cleanLine;
          isBoleto = true;
          break;
        }
      }
    }

    // 5. Detectar DANFE (Nota Fiscal Eletrônica)
    bool isDanfe = fullText.toLowerCase().contains('danfe') ||
                   fullText.toLowerCase().contains('documento auxiliar') ||
                   fullText.toLowerCase().contains('nota fiscal');
    String? danfeIssuer;

    if (isDanfe) {
      final RegExp issuerRegExp = RegExp(r'(?:EMISSOR|RAZÃO SOCIAL|EMITENTE)[:]?\s*([^\n\r]+)', caseSensitive: false);
      final issuerMatch = issuerRegExp.firstMatch(fullText);
      if (issuerMatch != null) {
        danfeIssuer = issuerMatch.group(1)!.trim();
      } else {
        // Primeira linha relevante que não seja genérica
        for (var line in lines) {
          final l = line.trim().toLowerCase();
          if (l.length > 3 &&
              !l.contains('danfe') &&
              !l.contains('documento auxiliar') &&
              !l.contains('nota fiscal') &&
              !l.contains('nfe') &&
              !l.contains('via') &&
              !l.contains('folha')) {
            danfeIssuer = line.trim();
            break;
          }
        }
      }
    }

    return OcrResult(
      restaurant: isDanfe ? (danfeIssuer ?? 'Nota Fiscal') : restaurant,
      amount: totalAmount,
      date: date ?? DateTime.now(),
      boletoKey: boletoKey,
      danfeIssuer: danfeIssuer,
      isBoleto: isBoleto,
      isDanfe: isDanfe,
    );
  }

  // Método para processar texto de notificações (Nova Funcionalidade)
  OcrResult parseNotification(String text) {
    // Ex: "Compra de R$ 50,00 aprovada no Posto Shell"
    // Ex: "Pix recebido de João Silva no valor de R$ 150,00"

    double? amount;
    String? participant;
    bool isIncome = false;

    final String lowercaseText = text.toLowerCase();

    // 1. Identificar se é saída para evitar falsos positivos
    bool isExpense = false;
    if (lowercaseText.contains('enviado') ||
        lowercaseText.contains('enviou') ||
        lowercaseText.contains('pagamento') ||
        lowercaseText.contains('pago a') ||
        lowercaseText.contains('paga a') ||
        lowercaseText.contains('compra') ||
        lowercaseText.contains('gasto') ||
        lowercaseText.contains('gastei') ||
        lowercaseText.contains('saída') ||
        lowercaseText.contains('débito') ||
        lowercaseText.contains('debito') ||
        lowercaseText.contains('transferência enviada') ||
        lowercaseText.contains('transferencia enviada') ||
        lowercaseText.contains('realizado') ||
        lowercaseText.contains('realizada')) {
      isExpense = true;
    }

    // 2. Identificar se é entrada se não for explicitamente uma despesa
    if (!isExpense && (
        lowercaseText.contains('recebido') || 
        lowercaseText.contains('recebeu') || 
        lowercaseText.contains('transferência') || 
        lowercaseText.contains('transferencia') || 
        lowercaseText.contains('transf') || 
        lowercaseText.contains('entrada') || 
        lowercaseText.contains('crédito') ||
        lowercaseText.contains('credito') ||
        lowercaseText.contains('pix') ||
        lowercaseText.contains('ted') ||
        lowercaseText.contains('doc') ||
        lowercaseText.contains('depósito') ||
        lowercaseText.contains('deposito')
    )) {
      isIncome = true;
    }

    // 3. Regex para valor monetário (R$ XX,XX)
    final RegExp amountRegExp = RegExp(r'(?:R\$|R\s?\$)\s?(\d+[.,]\d{2})', caseSensitive: false);
    final match = amountRegExp.firstMatch(text);
    if (match != null) {
      String val = match.group(1)!.replaceAll(',', '.');
      amount = double.tryParse(val);
    } else {
      // Se não houver R$, tenta encontrar o único decimal do texto (para notificações simplificadas)
      final RegExp fallbackRegExp = RegExp(r'\b(\d+[.,]\d{2})\b');
      final fallbackMatches = fallbackRegExp.allMatches(text);
      if (fallbackMatches.length == 1) {
        String val = fallbackMatches.first.group(1)!.replaceAll(',', '.');
        amount = double.tryParse(val);
      }
    }

    // Função interna para limpar o nome do participante (remetente ou estabelecimento)
    String cleanName(String name) {
      String cleaned = name.trim();

      // Divisores comuns no final
      final List<String> stopPhrases = [
        ' no valor', ' na conta', ' via ', ' pelo ', ' com ', ' de r\$', ' r\$', ' no banco', ' em ', 
        ' realizado', ' aprovado', ' enviado', ' recebido', ' no dia', ' às ', ' as ', ' para '
      ];
      for (var phrase in stopPhrases) {
        final idx = cleaned.toLowerCase().indexOf(phrase);
        if (idx != -1) {
          cleaned = cleaned.substring(0, idx);
        }
      }

      // Remover caracteres estranhos nas pontas
      cleaned = cleaned.replaceAll(RegExp(r'^[^A-Za-zÀ-ÖØ-öø-ÿ\d]+|[^A-Za-zÀ-ÖØ-öø-ÿ\d]+$'), '').trim();

      // Limpar preposições e artigos órfãos que ficaram no início ou no fim
      final List<String> orphanWords = ['de', 'da', 'do', 'dos', 'das', 'para', 'com', 'a', 'o', 'em', 'no', 'na', 'um', 'uma'];
      bool changed = true;
      while (changed) {
        changed = false;
        final words = cleaned.split(RegExp(r'\s+'));
        if (words.isNotEmpty && orphanWords.contains(words.last.toLowerCase())) {
          words.removeLast();
          cleaned = words.join(' ');
          changed = true;
        }
        if (words.isNotEmpty && orphanWords.contains(words.first.toLowerCase())) {
          words.removeAt(0);
          cleaned = words.join(' ');
          changed = true;
        }
      }

      // Limitar a no máximo 4 palavras (evita frases inteiras)
      final words = cleaned.split(RegExp(r'\s+'));
      if (words.length > 4) {
        cleaned = words.take(4).join(' ');
      }

      return cleaned;
    }

    // 4. Extração inteligente de remetente ou estabelecimento
    if (isIncome) {
      final List<RegExp> incomePatterns = [
        RegExp(r'(?:recebido de|recebeu de|recebida de)\s+([A-Za-zÀ-ÖØ-öø-ÿ\s]+)', caseSensitive: false),
        RegExp(r'(?:pix de|ted de|doc de|crédito de|transferência de|transferencia de|transf de)\s+([A-Za-zÀ-ÖØ-öø-ÿ\s]+)', caseSensitive: false),
        RegExp(r'de\s+([A-Za-zÀ-ÖØ-öø-ÿ\s]+)\s+(?:recebido|recebida|no valor)', caseSensitive: false),
      ];

      for (var pattern in incomePatterns) {
        final m = pattern.firstMatch(text);
        if (m != null) {
          participant = cleanName(m.group(1)!);
          break;
        }
      }

      if (participant == null || participant.isEmpty) {
        final RegExp dePattern = RegExp(r'de\s+([A-Za-zÀ-ÖØ-öø-ÿ\s]+)', caseSensitive: false);
        final m = dePattern.firstMatch(text);
        if (m != null) {
          participant = cleanName(m.group(1)!);
        }
      }

      if (participant == null || participant.isEmpty) {
        if (lowercaseText.contains('ted')) {
          participant = 'TED Recebida';
        } else if (lowercaseText.contains('doc')) {
          participant = 'DOC Recebido';
        } else if (lowercaseText.contains('transferencia') || lowercaseText.contains('transferência') || lowercaseText.contains('transf')) {
          participant = 'Transferência Recebida';
        } else {
          participant = 'Pix Recebido';
        }
      }
    } else {
      final List<RegExp> expensePatterns = [
        RegExp(r'(?:compra no|compra na|compra no\(a\))\s+([A-Za-zÀ-ÖØ-öø-ÿ\s\d]+)', caseSensitive: false),
        RegExp(r'(?:pago a|paga a|enviado para|enviada para)\s+([A-Za-zÀ-ÖØ-öø-ÿ\s\d]+)', caseSensitive: false),
        RegExp(r'(?:gasto no|gasto na|gasto no\(a\))\s+([A-Za-zÀ-ÖØ-öø-ÿ\s\d]+)', caseSensitive: false),
      ];

      for (var pattern in expensePatterns) {
        final m = pattern.firstMatch(text);
        if (m != null) {
          participant = cleanName(m.group(1)!);
          break;
        }
      }

      if (participant == null || participant.isEmpty) {
        final List<String> keywords = ['em', 'no', 'na', 'aprovada no', 'no(a)', 'em(a)', 'para'];
        for (String kw in keywords) {
          final RegExp storeRegExp = RegExp('$kw\\s+([A-Za-zÀ-ÖØ-öø-ÿ\\s\\d]+)', caseSensitive: false);
          final m = storeRegExp.firstMatch(text);
          if (m != null) {
            participant = cleanName(m.group(1)!);
            break;
          }
        }
      }
      participant = (participant == null || participant.isEmpty) ? 'Gasto Bancário' : participant;
    }

    return OcrResult(
      restaurant: participant,
      amount: amount,
      date: DateTime.now(),
      isIncome: isIncome,
    );
  }

  void dispose() {
    _textRecognizer?.close();
  }

  Future<OcrResult?> parseNotificationWithAi(String text) async {
    try {
      final keys = await ConfigService().getGeminiApiKeys();
      if (keys.isEmpty) return null;
      final apiKey = keys.first;

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = '''
Analise o texto de notificação bancária de celular abaixo e extraia as informações estruturadas em JSON.
Texto da notificação: "$text"

Formato JSON de saída obrigatório:
{
  "estabelecimento": "Nome limpo do estabelecimento, pessoa ou remetente/destinatário do Pix/TED (ex: Posto Shell, João Silva, Nubank, Omie)",
  "valor": 0.00,
  "isIncome": false, // true se o dinheiro entrou na conta (recebido/Pix recebido/depósito); false se o dinheiro saiu da conta (enviado/compra/pago/débito)
  "data": "aaaa-mm-dd" // Data correspondente ou data atual
}

Retorne APENAS o JSON limpo, sem formatação markdown, sem texto explicativo adicional.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      if (responseText == null) return null;

      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      
      final double amt = double.tryParse(data['valor']?.toString() ?? '') ?? 0.0;
      if (amt <= 0) return null;

      return OcrResult(
        restaurant: data['estabelecimento'] ?? 'Gasto Bancário',
        amount: amt,
        date: DateTime.tryParse(data['data'] ?? '') ?? DateTime.now(),
        isIncome: data['isIncome'] == true,
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao processar notificação com IA: $e');
      return null;
    }
  }
}

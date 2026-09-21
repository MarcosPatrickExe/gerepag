import 'dart:math' as math;
import '../models/transaction_model.dart';

enum AnomalyType { duplicate, cnpjmismatch, magnitude, nocturnal, none }

class AnomalyResult {
  final bool isSuspect;
  final String reason;
  final double score; // 0.0 a 1.0 (nível de suspeita)
  final AnomalyType type;
  final bool isCritical;
  final String? details;

  AnomalyResult({
    required this.isSuspect,
    required this.reason,
    this.score = 0.0,
    this.type = AnomalyType.none,
    this.isCritical = false,
    this.details,
  });
}

class AnomalyService {
  /// Verifica duplicidade de lançamento (mesmo fornecedor/descrição, mesmo valor em janela de 30 dias)
  static AnomalyResult? checkDuplicate(TransactionModel transaction, List<TransactionModel> history) {
    final normalizedTitle = transaction.title.trim().toLowerCase();
    
    for (final existing in history) {
      if (existing.id == transaction.id) continue;
      
      final titleMatch = existing.title.trim().toLowerCase() == normalizedTitle;
      final amountMatch = (existing.amount - transaction.amount).abs() < 0.01;
      final daysDiff = existing.date.difference(transaction.date).inDays.abs();

      if (amountMatch && titleMatch && daysDiff <= 30) {
        return AnomalyResult(
          isSuspect: true,
          type: AnomalyType.duplicate,
          isCritical: true,
          score: 0.95,
          reason: 'Possível pagamento duplicado detectado!',
          details: 'Lançamento com valor R\$ ${transaction.amount.toStringAsFixed(2)} e descrição "${transaction.title}" já existe em ${existing.date.day}/${existing.date.month}/${existing.date.year}.',
        );
      }
    }
    return null;
  }

  /// Verifica se o CNPJ/CPF lido no boleto/Pix bate com o CNPJ cadastrado do fornecedor
  static AnomalyResult checkBeneficiaryMatch({
    required String registeredCnpjCpf,
    required String scannedCnpjCpf,
  }) {
    final cleanRegistered = registeredCnpjCpf.replaceAll(RegExp(r'\D'), '');
    final cleanScanned = scannedCnpjCpf.replaceAll(RegExp(r'\D'), '');

    if (cleanRegistered.isNotEmpty && cleanScanned.isNotEmpty && cleanRegistered != cleanScanned) {
      return AnomalyResult(
        isSuspect: true,
        type: AnomalyType.cnpjmismatch,
        isCritical: true,
        score: 1.0,
        reason: 'ALERTA DE SEGURANÇA: CNPJ/CPF Divergente!',
        details: 'O documento cadastrado ($registeredCnpjCpf) diverge do favorecido do boleto/Pix ($scannedCnpjCpf). Risco de boleto adulterado ou golpe do Pix!',
      );
    }

    return AnomalyResult(isSuspect: false, reason: 'Dados do favorecido validados.');
  }

  static AnomalyResult check(TransactionModel transaction, List<TransactionModel> history) {
    // 1. Prioridade Máxima: Checagem de Duplicidade
    final duplicateCheck = checkDuplicate(transaction, history);
    if (duplicateCheck != null) {
      return duplicateCheck;
    }

    if (history.length < 10) {
      return AnomalyResult(isSuspect: false, reason: 'Modo Aprendizado Ativo.');
    }

    // 2. Verificar Magnitude (Volume do gasto)
    final categoryExpenses = history.where((t) => t.category == transaction.category && t.type == TransactionType.expense).toList();
    
    if (categoryExpenses.isNotEmpty) {
      final double mean = categoryExpenses.fold(0.0, (sum, t) => sum + t.amount) / categoryExpenses.length;
      final double variance = categoryExpenses.fold(0.0, (sum, t) => sum + math.pow(t.amount - mean, 2)) / categoryExpenses.length;
      final double stdDev = math.sqrt(variance);

      // Se o gasto for maior que a média + 3 desvios padrão (Regra dos 99.7%)
      if (transaction.amount > mean + (3 * stdDev) && transaction.amount > 500) {
        return AnomalyResult(
          isSuspect: true, 
          type: AnomalyType.magnitude,
          reason: 'Valor muito acima da sua média habitual para esta categoria.',
          score: 0.8,
          details: 'Média histórica: R\$ ${mean.toStringAsFixed(2)} | Valor atual: R\$ ${transaction.amount.toStringAsFixed(2)}',
        );
      }
    }

    // 3. Verificar Temporalidade (Horário)
    final hour = transaction.date.hour;
    if (hour >= 0 && hour <= 5) { // Madrugada
      final nocturnalHistory = history.where((t) => t.date.hour >= 0 && t.date.hour <= 5).length;
      // Se menos de 5% dos seus gastos são na madrugada
      if (nocturnalHistory / history.length < 0.05) {
        return AnomalyResult(
          isSuspect: true,
          type: AnomalyType.nocturnal,
          reason: 'Gasto realizado em horário atípico (Madrugada) para o seu perfil.',
          score: 0.7,
        );
      }
    }

    return AnomalyResult(isSuspect: false, reason: 'Dentro do padrão esperado.');
  }
}


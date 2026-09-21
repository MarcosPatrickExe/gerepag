import 'package:appfinancerio/models/business_goal_model.dart';
import 'package:appfinancerio/models/dre_node.dart';
import 'package:appfinancerio/models/goal_model.dart';
import 'package:appfinancerio/models/omie_account.dart';
import 'package:appfinancerio/models/omie_purchase_model.dart';
import 'package:appfinancerio/models/omie_sales_analysis_model.dart';
import 'package:appfinancerio/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
    test('round-trips financial fields through a map', () {
      final date = DateTime.utc(2026, 9, 21, 12, 30);
      final transaction = TransactionModel(
        id: 'tx-1',
        amount: 149.90,
        category: 'Software',
        description: 'Assinatura',
        date: date,
        type: TransactionType.expense,
        accountId: 'wallet-1',
        auditedByContador: true,
      );

      final restored = TransactionModel.fromMap('tx-1', transaction.toMap());

      expect(restored.amount, 149.90);
      expect(restored.date, date);
      expect(restored.type, TransactionType.expense);
      expect(restored.accountId, 'wallet-1');
      expect(restored.auditedByContador, isTrue);
      expect(restored.title, 'Assinatura');
    });

    test('uses safe defaults for optional text and unknown type', () {
      final restored = TransactionModel.fromMap('tx-2', {
        'amount': 10,
        'date': '2026-09-21T00:00:00.000Z',
        'type': 'unknown',
      });

      expect(restored.category, 'Geral');
      expect(restored.type, TransactionType.expense);
      expect(restored.title, 'Geral');
    });
  });

  group('GoalModel', () {
    test('clamps progress to the supported range', () {
      final goal = GoalModel(
        id: 'goal-1',
        title: 'Reserva',
        targetAmount: 1000,
        currentAmount: 1250,
        deadline: DateTime.utc(2027),
      );

      expect(goal.progress, 1.0);
      expect(goal.isReached, isTrue);
    });

    test('returns zero progress for an invalid zero target', () {
      final goal = GoalModel(
        id: 'goal-2',
        title: 'Sem meta definida',
        targetAmount: 0,
        currentAmount: 0,
        deadline: DateTime.utc(2027),
      );

      expect(goal.progress, 0.0);
    });
  });

  test('BusinessGoalModel round-trips typed targets', () {
    final goal = BusinessGoalModel(
      id: 'business-1',
      title: 'Meta anual',
      type: BusinessGoalType.annual,
      year: 2027,
      targets: {
        BusinessMetricType.grossRevenue: 500000,
        BusinessMetricType.netIncome: 100000,
      },
    );

    final restored = BusinessGoalModel.fromMap('business-1', goal.toMap());

    expect(restored.type, BusinessGoalType.annual);
    expect(restored.targets[BusinessMetricType.grossRevenue], 500000);
    expect(restored.targets[BusinessMetricType.netIncome], 100000);
  });

  group('Omie financial models', () {
    test('calculates product margin and markup', () {
      final item = OmieProductSaleItem.fromMap({
        'id': 'p-1',
        'productName': 'Serviço',
        'quantity': 2,
        'unitPrice': 100,
        'costPrice': 40,
        'totalRevenue': 200,
      });

      expect(item.marginAmount, 120);
      expect(item.marginPercentage, 60);
      expect(item.markupPercentage, 150);
    });

    test('calculates purchase price variance', () {
      final order = OmiePurchaseOrder.fromMap({
        'id': 'order-1',
        'requestedAmount': 1000,
        'billedAmount': 1075,
        'dOrdem': '2026-09-20',
      });

      expect(order.priceVariance, 75);
      expect(order.orderDate, DateTime(2026, 9, 20));
    });

    test('serializes an Omie account to JSON and back', () {
      final account = OmieAccount(
        id: 'omie-1',
        name: 'Empresa A',
        appKey: 'key',
        appSecret: 'secret',
        cnpj: '00000000000100',
      );

      final restored = OmieAccount.fromJson(account.toJson());

      expect(restored.id, account.id);
      expect(restored.name, account.name);
      expect(restored.cnpj, account.cnpj);
    });
  });

  test('DreNode sorts children by accounting code', () {
    final root = DreNode(code: '1', name: 'Receitas', level: 1);
    root.children['late'] = DreNode(code: '1.20', name: 'Outras', level: 2);
    root.children['early'] = DreNode(code: '1.10', name: 'Vendas', level: 2);

    expect(root.sortedChildren.map((node) => node.code), ['1.10', '1.20']);
  });
}

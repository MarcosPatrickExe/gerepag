import 'package:flutter/material.dart';

enum OpportunityTemperature { hot, warm, cold }

class OmieCrmOpportunity {
  final String id;
  final String title;
  final String clientName;
  final String sellerName;
  final double amount;
  final String stage; // lead, proposal, negotiation, closed_won, closed_lost
  final OpportunityTemperature temperature;
  final double probability; // 0.0 to 1.0
  final DateTime expectedCloseDate;
  final DateTime createdAt;

  OmieCrmOpportunity({
    required this.id,
    required this.title,
    required this.clientName,
    required this.sellerName,
    required this.amount,
    required this.stage,
    required this.temperature,
    required this.probability,
    required this.expectedCloseDate,
    required this.createdAt,
  });

  factory OmieCrmOpportunity.fromMap(Map<String, dynamic> map) {
    OpportunityTemperature parseTemp(String? temp) {
      if (temp == null) return OpportunityTemperature.warm;
      switch (temp.toLowerCase()) {
        case 'hot':
        case 'quente':
          return OpportunityTemperature.hot;
        case 'cold':
        case 'frio':
          return OpportunityTemperature.cold;
        default:
          return OpportunityTemperature.warm;
      }
    }

    return OmieCrmOpportunity(
      id: map['nCodOpp']?.toString() ?? map['id']?.toString() ?? '',
      title: map['cNome'] ?? map['title'] ?? 'Oportunidade sem nome',
      clientName: map['cNomeCliente'] ?? map['clientName'] ?? 'Cliente N/A',
      sellerName: map['cNomeVendedor'] ?? map['sellerName'] ?? 'Vendedor N/A',
      amount: (map['nValor'] ?? map['amount'] ?? 0.0).toDouble(),
      stage: map['cEtapa'] ?? map['stage'] ?? 'lead',
      temperature: parseTemp(map['cTemperatura'] ?? map['temperature']),
      probability: ((map['nProbabilidade'] ?? map['probability'] ?? 50.0) as num).toDouble() / 100.0,
      expectedCloseDate: map['dPrevisao'] != null
          ? DateTime.tryParse(map['dPrevisao']) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['dCriacao'] != null
          ? DateTime.tryParse(map['dCriacao']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'clientName': clientName,
      'sellerName': sellerName,
      'amount': amount,
      'stage': stage,
      'temperature': temperature.name,
      'probability': probability * 100,
      'expectedCloseDate': expectedCloseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class OmieCrmTask {
  final String id;
  final String title;
  final String assignedTo;
  final bool isCompleted;
  final DateTime dueDate;

  OmieCrmTask({
    required this.id,
    required this.title,
    required this.assignedTo,
    required this.isCompleted,
    required this.dueDate,
  });

  factory OmieCrmTask.fromMap(Map<String, dynamic> map) {
    return OmieCrmTask(
      id: map['nCodTarefa']?.toString() ?? map['id']?.toString() ?? '',
      title: map['cTitulo'] ?? map['title'] ?? 'Tarefa',
      assignedTo: map['cResponsavel'] ?? map['assignedTo'] ?? 'N/A',
      isCompleted: map['cConcluida'] == 'S' || map['isCompleted'] == true,
      dueDate: map['dVencimento'] != null
          ? DateTime.tryParse(map['dVencimento']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class OmieRecurrenceMetric {
  final double mrr;
  final double previousMrr;
  final double churnRate;
  final double retentionRate;
  final int totalContractClients;

  OmieRecurrenceMetric({
    required this.mrr,
    required this.previousMrr,
    required this.churnRate,
    required this.retentionRate,
    required this.totalContractClients,
  });
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

enum SubscriptionTier { free, pro, family }

class SubscriptionProvider with ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseDatabase get _db => FirebaseDatabase.instance;
  
  SubscriptionTier _tier = SubscriptionTier.free;
  int _ocrUsageCount = 0;
  int _negotiationUsageCount = 0;
  bool _isLoading = true;
  DateTime? _expiresAt;
  String? _stripeSessionId;

  bool _hasPromoEmail(String? email) {
    if (email == null) return false;
    return email == 'empresapequena@gmail.com.br' || email == 'freelanceroficial@gmail.com';
  }

  SubscriptionTier get tier {
    if (_hasPromoEmail(_auth.currentUser?.email)) {
      return SubscriptionTier.family;
    }
    return _tier;
  }
  bool get isLoading => _isLoading;
  bool get isPro {
    if (_hasPromoEmail(_auth.currentUser?.email)) return true;
    return _tier == SubscriptionTier.pro || _tier == SubscriptionTier.family;
  }
  bool get isFamily {
    if (_hasPromoEmail(_auth.currentUser?.email)) return true;
    return _tier == SubscriptionTier.family;
  }
  DateTime? get expiresAt {
    if (_hasPromoEmail(_auth.currentUser?.email)) {
      return DateTime.now().add(const Duration(days: 365));
    }
    return _expiresAt;
  }
  String? get stripeSessionId => _stripeSessionId;
  int get ocrUsageCount => _ocrUsageCount;
  int get negotiationUsageCount => _negotiationUsageCount;
 
  int get daysRemaining {
    if (_hasPromoEmail(_auth.currentUser?.email)) return 365;
    if (_expiresAt == null) return 0;
    final diff = _expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
 
  SubscriptionProvider() {
    _init();
  }
 
  Future<void> _init() async {
    if (Firebase.apps.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }
 
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadSubscriptionData(user.uid);
      } else {
        _tier = SubscriptionTier.free;
        _expiresAt = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }
 
  Future<void> _loadSubscriptionData(String uid) async {
    _isLoading = true;
    notifyListeners();
 
    // Se o email for de promoção, dar upgrade automático no banco de dados!
    if (_hasPromoEmail(_auth.currentUser?.email)) {
      try {
        final now = DateTime.now();
        final expirationDate = now.add(const Duration(days: 365));
        await _db.ref('users/$uid/subscription').update({
          'tier': 'family',
          'status': 'active',
          'expiresAt': expirationDate.toIso8601String(),
        });
      } catch (_) {}
    }

    try {
      final snapshot = await _db.ref('users/$uid/subscription').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final tierStr = data['tier'] ?? 'free';
        _tier = SubscriptionTier.values.firstWhere(
          (e) => e.name == tierStr,
          orElse: () => SubscriptionTier.free,
        );
        _ocrUsageCount = data['ocrCount'] ?? 0;
        _negotiationUsageCount = data['negotiationCount'] ?? 0;
        
        // Carregar metadados Premium
        if (data['expiresAt'] != null) {
          _expiresAt = DateTime.parse(data['expiresAt']);
        }
        _stripeSessionId = data['stripeSessionId'];
      }
    } catch (e) {
      print('Erro ao carregar assinatura: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Upgrade com Inteligência de Dados
  Future<void> upgradeTo(SubscriptionTier newTier, {required String sessionId, int durationDays = 30}) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final expirationDate = now.add(Duration(days: durationDays));

    await _db.ref('users/$uid/subscription').update({
      'tier': newTier.name,
      'status': 'active',
      'stripeSessionId': sessionId,
      'updatedAt': now.toIso8601String(),
      'expiresAt': expirationDate.toIso8601String(),
    });

    _tier = newTier;
    notifyListeners();
  }

  // Verificação de Limites
  bool get canUseOCR {
    if (isPro) return true;
    return _ocrUsageCount < 3; // Limite de 3 notas para o plano Grátis
  }

  Future<void> incrementOCRUsage() async {
    if (isPro) return;
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _ocrUsageCount++;
    await _db.ref('users/$uid/subscription/ocrCount').set(_ocrUsageCount);
    notifyListeners();
  }

  bool get canUseNegotiation {
    if (isPro) return true;
    return _negotiationUsageCount < 2; // Limite de 2 negociações para o plano Grátis
  }

  Future<void> incrementNegotiationUsage() async {
    if (isPro) return;
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _negotiationUsageCount++;
    await _db.ref('users/$uid/subscription/negotiationCount').set(_negotiationUsageCount);
    notifyListeners();
  }
}

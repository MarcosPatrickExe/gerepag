import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GlobalSettingsProvider with ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  StreamSubscription? _settingsSubscription;
  Map<String, dynamic> _settings = {
    'maintenanceMode': false,
    'premiumPrice': 199.90,
    'familyPrice': 49.90,
    'announcement': '',
  };
  bool _isLoading = true;

  GlobalSettingsProvider() {
    _init();
  }

  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  void _init() {
    _settingsSubscription = _db.ref('global_settings').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _settings = Map<String, dynamic>.from(event.snapshot.value as Map);
        _isLoading = false;
        notifyListeners();
      } else {
        // Inicializar com padrões se não existir
        _db.ref('global_settings').set(_settings);
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> updateSetting(String key, dynamic value) async {
    await _db.ref('global_settings').update({key: value});
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}

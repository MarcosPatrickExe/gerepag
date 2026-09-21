import 'package:flutter/material.dart';

class PremiumService extends ChangeNotifier {
  bool _isPremium = false;

  bool get isPremium => _isPremium;

  void upgradeToPremium() {
    _isPremium = true;
    notifyListeners();
  }

  void resetPremium() {
    _isPremium = false;
    notifyListeners();
  }
}

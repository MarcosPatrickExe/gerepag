import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String _groupId = 'group.com.real.finance.control';
  static const String _androidWidgetName = 'HomeWidgetProvider';

  static double _lastBalance = 0.0;
  static int _lastLevel = 1;
  static int _lastXp = 0;
  static double _lastRadarLimit = 0.0;
  static double _lastRadarRemaining = 0.0;

  static Future<void> updateBalance(double balance) async {
    _lastBalance = balance;
    await _updateWidget();
  }

  static Future<void> updateStats(int level, int xp) async {
    _lastLevel = level;
    _lastXp = xp;
    await _updateWidget();
  }

  static Future<void> updateRadar(double limit, double remaining) async {
    _lastRadarLimit = limit;
    _lastRadarRemaining = remaining;
    await _updateWidget();
  }

  static Future<void> _updateWidget() async {
    if (kIsWeb) return; 
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    
    try {
      await HomeWidget.saveWidgetData<String>('widget_balance', currency.format(_lastBalance));
      await HomeWidget.saveWidgetData<String>('widget_xp', 'Nível $_lastLevel • $_lastXp XP');
      await HomeWidget.saveWidgetData<String>('widget_radar_limit', currency.format(_lastRadarLimit));
      await HomeWidget.saveWidgetData<String>('widget_radar_remaining', currency.format(_lastRadarRemaining));

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      print('Erro ao atualizar Widget: $e');
    }
  }

  static Future<void> initLaunchListener(Function(String?) onLaunch) async {
    if (kIsWeb) return; 
    HomeWidget.setAppGroupId(_groupId);
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null) onLaunch(uri.toString());
    });
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) onLaunch(uri.toString());
    });
  }
}

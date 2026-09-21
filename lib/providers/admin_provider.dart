import 'package:flutter/material.dart';
import '../services/realtime_db_service.dart';

class AdminProvider with ChangeNotifier {
  final RealtimeDbService _db = RealtimeDbService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'empresarial', 'familia', 'pessoal'
  String _sortType = 'date'; // 'date', 'name', 'balance'
  bool _showInactiveOnly = false;
  
  List<Map<String, dynamic>> get users {
    List<Map<String, dynamic>> filtered = _users;

    // 1. Busca por texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    // 2. Filtro por tipo
    if (_filterType != 'all') {
      filtered = filtered.where((u) => u['accountType'] == _filterType).toList();
    }

    // 3. Filtro por inatividade (ex: 7 dias sem logar)
    if (_showInactiveOnly) {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      filtered = filtered.where((u) {
        final lastLogin = u['lastLoginAt'] ?? u['joinedAt'] ?? 0;
        return lastLogin < sevenDaysAgo;
      }).toList();
    }

    // 4. Ordenação
    filtered.sort((a, b) {
      if (_sortType == 'name') {
        return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
      } else if (_sortType == 'balance') {
        final balA = double.tryParse(a['balance']?.toString() ?? '0') ?? 0;
        final balB = double.tryParse(b['balance']?.toString() ?? '0') ?? 0;
        return balB.compareTo(balA); // Decrescente
      } else {
        final dateA = a['joinedAt'] ?? 0;
        final dateB = b['joinedAt'] ?? 0;
        return dateB.compareTo(dateA); // Mais novos primeiro
      }
    });

    return filtered;
  }
  
  bool get isLoading => _isLoading;
  String get filterType => _filterType;
  String get sortType => _sortType;
  bool get showInactiveOnly => _showInactiveOnly;

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setSort(String type) {
    _sortType = type;
    notifyListeners();
  }

  void toggleInactiveFilter() {
    _showInactiveOnly = !_showInactiveOnly;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _db.getAllUsers();
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Estatísticas para os Gráficos
  List<double> get userGrowthData {
    // Mock de dados para os últimos 7 dias (em produção, agruparíamos por joinedAt)
    if (_users.isEmpty) return [0, 0, 0, 0, 0, 0, 0];
    
    final now = DateTime.now();
    List<double> dailyCounts = List.filled(7, 0);
    
    for (var user in _users) {
      final joined = DateTime.fromMillisecondsSinceEpoch(user['joinedAt'] ?? 0);
      final diff = now.difference(joined).inDays;
      if (diff >= 0 && diff < 7) {
        dailyCounts[6 - diff]++;
      }
    }
    
    // Acumular
    for (int i = 1; i < 7; i++) {
      dailyCounts[i] += dailyCounts[i - 1];
    }
    return dailyCounts;
  }

  Future<void> changeUserRole(String uid, String newRole) async {
    await _db.updateUserRole(uid, newRole);
    final index = _users.indexWhere((u) => u['uid'] == uid);
    if (index != -1) {
      _users[index]['role'] = newRole;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _db.deleteUser(uid);
    _users.removeWhere((u) => u['uid'] == uid);
    notifyListeners();
  }

  double get totalMRR {
    double total = 0;
    for (var user in _users) {
      final type = user['accountType'] ?? 'pessoal';
      if (type == 'empresarial') total += 199.90;
      else if (type == 'familia') total += 49.90;
    }
    return total;
  }
}

import 'package:flutter/material.dart';
import 'package:zippa_app/data/api/api_client.dart';

class WalletProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // API CALL: Get Balance
  // ============================================
  Future<void> fetchBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/wallet/balance');
      if (response['success'] != false) {
        _balance = double.tryParse(response['balance']?.toString() ?? '0') ?? 0.0;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to fetch balance';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // API CALL: Get Transactions
  // ============================================
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/wallet/transactions');
      if (response['success'] != false && response['transactions'] != null) {
        _transactions = response['transactions'] as List;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = 'Failed to fetch transactions';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // API CALL: Fund Wallet
  // ============================================
  Future<bool> fundWallet(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/wallet/fund', {'amount': amount});
      if (response['success'] != false) {
        _balance = double.tryParse(response['balance']?.toString() ?? _balance.toString()) ?? _balance;
        await fetchTransactions(); // Refresh history
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Funding failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe) {
        final userJson = prefs.getString('current_user');
        if (userJson != null) {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromJson(userMap);
        }
      } else {
        // Clear session from storage if rememberMe is false
        await prefs.remove('current_user');
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String cedula, String password, bool rememberMe) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check default admin
      if (cedula.trim() == '30141644' && password == '123') {
        _currentUser = User(
          id: 'admin_1',
          cedula: '30141644',
          password: '123',
        );

        await prefs.setBool('remember_me', rememberMe);
        if (rememberMe) {
          await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        } else {
          await prefs.remove('current_user');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Check registered system users in SharedPreferences
      final usersJson = prefs.getString('system_users') ?? '[]';
      final List<dynamic> usersList = jsonDecode(usersJson);
      Map<String, dynamic>? matchedUser;
      for (final item in usersList) {
        if (item is Map<String, dynamic> &&
            item['cedula'].toString().trim() == cedula.trim() &&
            item['password'].toString() == password) {
          matchedUser = item;
          break;
        }
      }

      if (matchedUser != null) {
        _currentUser = User(
          id: matchedUser['id'] as String? ?? '',
          cedula: matchedUser['cedula'] as String? ?? '',
          password: matchedUser['password'] as String? ?? '',
        );

        await prefs.setBool('remember_me', rememberMe);
        if (rememberMe) {
          await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
        } else {
          await prefs.remove('current_user');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      await prefs.setBool('remember_me', false);
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
}

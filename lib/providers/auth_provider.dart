// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final _svc = AuthService();

  String  _uid      = '';
  String? _type;
  Map<String, dynamic>? _profile;
  bool    _loading  = false;
  String? _error;
  bool    _ready    = false;   // session restore дууссан уу

  String  get uid          => _uid;
  String? get userType     => _type;
  Map<String, dynamic>? get profile => _profile;
  bool    get loading      => _loading;
  String? get error        => _error;
  bool    get isStudent    => _type == 'student';
  bool    get isCompany    => _type == 'company';
  bool    get isLoggedIn   => _uid.isNotEmpty;
  bool    get ready        => _ready;

  String get displayName {
    if (_profile == null) return '';
    return isStudent
        ? (_profile!['first_name'] ?? _profile!['firstName'] ?? '')
        : (_profile!['name'] ?? '');
  }

  AuthProvider() {
    _restoreSession();
  }

  // ── Session сэргээлт ────────────────────────────────────────
  Future<void> _restoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      final me = await _svc.restoreSession();
      if (me != null) {
        _uid  = me['uid'] as String;
        _type = me['type'] as String;
        await _loadProfile();
      }
    } catch (_) {
      // token хүчинтэй биш → нэвтрэх дэлгэц рүү
    } finally {
      _loading = false;
      _ready   = true;
      notifyListeners();
    }
  }

  // ── Профайл татах ───────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      if (isStudent) {
        _profile = await ApiClient.get('/students/$_uid') as Map<String, dynamic>;
      } else {
        _profile = await ApiClient.get('/companies/$_uid') as Map<String, dynamic>;
      }
    } catch (_) {}
    notifyListeners();
  }

  // ── Бүртгэл ─────────────────────────────────────────────────
  Future<bool> registerStudent(Map<String, dynamic> data, String pw) async {
    _setLoading(true);
    try {
      final res = await _svc.registerStudent(email: data['email'], password: pw, data: data);
      _uid  = res['uid'] as String;
      _type = 'student';
      await _loadProfile();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  Future<bool> registerCompany(Map<String, dynamic> data, String pw) async {
    _setLoading(true);
    try {
      final res = await _svc.registerCompany(email: data['email'], password: pw, data: data);
      _uid  = res['uid'] as String;
      _type = 'company';
      await _loadProfile();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  // ── Нэвтрэх ─────────────────────────────────────────────────
  Future<bool> login(String email, String pw) async {
    _setLoading(true);
    try {
      final res = await _svc.login(email, pw);
      _uid  = res['uid'] as String;
      _type = res['type'] as String;
      await _loadProfile();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  // ── Нууц үг сэргээх (backend-д email илгээх endpoint байхгүй бол хэрэгжүүлнэ) ──
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      // TODO: backend-д POST /auth/forgot-password endpoint нэмэх
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  // ── Гарах ───────────────────────────────────────────────────
  Future<void> logout() async {
    await _svc.logout();
    _uid     = '';
    _type    = null;
    _profile = null;
    notifyListeners();
  }

  // ── Нууц үг солих ───────────────────────────────────────────
  Future<bool> changePassword(String newPw) async {
    _setLoading(true);
    try {
      await _svc.changePassword(newPw);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  // ── Профайл шинэчлэх ────────────────────────────────────────
  Future<void> refreshProfile() => _loadProfile();

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool v) { _loading = v; notifyListeners(); }
}

// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  User? _user;
  String? _userType;   // 'student' | 'company'
  Map<String, dynamic>? _profile;
  bool _loading = false;
  String? _error;

  User?                   get user      => _user;
  String?                 get userType  => _userType;
  Map<String, dynamic>?   get profile   => _profile;
  bool                    get loading   => _loading;
  String?                 get error     => _error;
  bool                    get isStudent => _userType == 'student';
  bool                    get isCompany => _userType == 'company';
  bool                    get isLoggedIn => _user != null;
  String get displayName {
    if (_profile == null) return '';
    if (isStudent) return _profile!['firstName'] ?? '';
    return _profile!['name'] ?? '';
  }

  AuthProvider() {
    _authService.authStream.listen(_onAuthChange);
  }

  Future<void> _onAuthChange(User? user) async {
    _user = user;
    if (user != null) {
      _userType = await _authService.getUserType(user.uid);
      await _loadProfile(user.uid);
    } else {
      _userType = null;
      _profile = null;
    }
    notifyListeners();
  }

  Future<void> _loadProfile(String uid) async {
    final col = _userType == 'student' ? DB.students : DB.companies;
    final doc = await col.doc(uid).get();
    _profile = doc.data();
    notifyListeners();
  }

  Future<bool> registerStudent(Map<String, dynamic> data, String password) async {
    _setLoading(true);
    try {
      await _authService.registerStudent(
        email: data['email'], password: password, studentData: data);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Бүртгэл амжилтгүй: ${_firestoreError(e)}';
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  Future<bool> registerCompany(Map<String, dynamic> data, String password) async {
    _setLoading(true);
    try {
      await _authService.registerCompany(
        email: data['email'], password: password, companyData: data);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Бүртгэл амжилтгүй: ${_firestoreError(e)}';
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    } finally { _setLoading(false); }
  }

  Future<void> logout() => _authService.logout();

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      if (_userType == 'student') {
        await ProfileService().updateStudent(_user!.uid, data);
      } else {
        await ProfileService().updateCompany(_user!.uid, data);
      }
      await _loadProfile(_user!.uid);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() { _error = null; notifyListeners(); }
  void _setLoading(bool v) { _loading = v; notifyListeners(); }

  String _firestoreError(Object e) {
    final msg = e.toString();
    if (msg.contains('permission-denied')) return 'Firestore эрх байхгүй. Firebase Console → Firestore → Rules-г шалгана уу';
    if (msg.contains('unavailable'))       return 'Сервер байхгүй байна. Дараа дахин оролдоно уу';
    if (msg.contains('network'))           return 'Интернет холболт шалгана уу';
    return msg;
  }

  String _authError(String code) => switch (code) {
    'email-already-in-use' => 'Имэйл аль хэдийн бүртгэлтэй',
    'wrong-password'       => 'Нууц үг буруу',
    'user-not-found'       => 'Хэрэглэгч олдсонгүй',
    'invalid-credential'   => 'Имэйл эсвэл нууц үг буруу байна',
    'invalid-email'        => 'Имэйл буруу форматтай',
    'weak-password'        => 'Нууц үг хэт богино (6+ тэмдэгт)',
    'operation-not-allowed'=> 'Email/Password нэвтрэлт идэвхгүй байна',
    'too-many-requests'    => 'Хэт олон оролдлого хийлээ. Түр хүлээнэ үү',
    'network-request-failed' => 'Интернет холболт шалгана уу',
    _                      => 'Алдаа гарлаа: $code',
  };
}

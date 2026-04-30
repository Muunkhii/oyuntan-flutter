// lib/services/api_service.dart
// Firebase-г орлосон REST API service layer
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Эндпойнт тохиргоо ─────────────────────────────────────────
// --dart-define=API_BASE=https://myserver.com гэж override хийж болно
// Android эмулятор: 10.0.2.2 | Web/Desktop: localhost
const _kBaseEnv = String.fromEnvironment('API_BASE', defaultValue: '');
String get _kBase {
  if (_kBaseEnv.isNotEmpty) return _kBaseEnv;
  if (kIsWeb) return 'http://localhost:3000';
  return 'http://10.0.2.2:3000'; // Android emulator
}

// ─────────────────────────────────────────────────────────────
//  ApiException
// ─────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override String toString() => message;
}

// ─────────────────────────────────────────────────────────────
//  ApiClient  –  token удирдлага + HTTP хүсэлт
// ─────────────────────────────────────────────────────────────
class ApiClient {
  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static bool get hasToken => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$_kBase$path'), headers: _headers);
    return _parse(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_kBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_kBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$_kBase$path'), headers: _headers);
    return _parse(res);
  }

  static Future<dynamic> putList(String path, List<dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_kBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  static dynamic _parse(http.Response res) {
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) {
      final msg = (body is Map) ? (body['message'] ?? 'Алдаа гарлаа') : 'Алдаа гарлаа';
      throw ApiException(msg.toString(), res.statusCode);
    }
    return body;
  }
}

// ─────────────────────────────────────────────────────────────
//  AuthService
// ─────────────────────────────────────────────────────────────
class AuthService {
  /// Token хадгалагдсан байвал /auth/me дуудан хэрэглэгчийн мэдээлэл авна
  Future<Map<String, dynamic>?> restoreSession() async {
    await ApiClient.init();
    if (!ApiClient.hasToken) return null;
    try {
      final me = await ApiClient.get('/auth/me') as Map<String, dynamic>;
      return me;
    } catch (_) {
      await ApiClient.clearToken();
      return null;
    }
  }

  Future<Map<String, dynamic>> registerStudent(
      {required String email, required String password, required Map<String, dynamic> data}) async {
    final res = await ApiClient.post('/auth/register/student', {
      ...data,
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await ApiClient.saveToken(res['token'] as String);
    return res;
  }

  Future<Map<String, dynamic>> registerCompany(
      {required String email, required String password, required Map<String, dynamic> data}) async {
    final res = await ApiClient.post('/auth/register/company', {
      ...data,
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await ApiClient.saveToken(res['token'] as String);
    return res;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await ApiClient.saveToken(res['token'] as String);
    return res;
  }

  Future<void> logout() => ApiClient.clearToken();

  Future<void> changePassword(String newPassword) =>
      ApiClient.put('/auth/change-password', {'newPassword': newPassword});
}

// ─────────────────────────────────────────────────────────────
//  InternshipService
// ─────────────────────────────────────────────────────────────
class InternshipService {
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    return await ApiClient.post('/posts', data) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getFeed() async {
    final list = await ApiClient.get('/posts') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCompanyPosts(String companyId) async {
    final list = await ApiClient.get('/posts?companyId=$companyId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> apply({
    required String postId,
    required String companyId,
    String? message,
    String? githubLink,
    List<Map<String, dynamic>>? portfolio,
  }) async {
    final res = await ApiClient.post('/applications', {
      'postId':    postId,
      'companyId': companyId,
      if (message    != null && message.isNotEmpty)    'message':    message,
      if (githubLink != null && githubLink.isNotEmpty) 'githubLink': githubLink,
      if (portfolio  != null && portfolio.isNotEmpty)  'portfolio':  portfolio,
    });
    return res as Map<String, dynamic>;
  }

  Future<void> acceptApplication({
    required String applicationId,
    required String studentId,
    required String postId,
    required int durationDays,
  }) async {
    await ApiClient.put('/applications/$applicationId/accept', {
      'studentId': studentId,
      'postId': postId,
      'durationDays': durationDays,
    });
  }

  Future<void> rejectApplication(String applicationId, {String? reason}) async {
    await ApiClient.put('/applications/$applicationId/reject', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<List<Map<String, dynamic>>> getCandidates(String postId) async {
    final list = await ApiClient.get('/applications?postId=$postId&status=pending') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getStudentInternships(String studentId) async {
    final list = await ApiClient.get('/internships?studentId=$studentId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getInternship(String id) async {
    return await ApiClient.get('/internships/$id') as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCompanyApplications(String companyId, {String? status}) async {
    final q = status != null
        ? '/applications?companyId=$companyId&status=$status'
        : '/applications?companyId=$companyId';
    final list = await ApiClient.get(q) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> terminateInternship(String internshipId, String reason) async {
    await ApiClient.put('/internships/$internshipId/terminate', {'reason': reason});
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await ApiClient.put('/posts/$postId', data);
  }

  Future<void> deletePost(String postId) async {
    await ApiClient.delete('/posts/$postId');
  }

  Future<List<Map<String, dynamic>>> getStudentApplications(String studentId) async {
    final list = await ApiClient.get('/applications?studentId=$studentId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> trackView(String postId) async {
    try { await ApiClient.post('/posts/$postId/view', {}); } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────
//  DiaryService
// ─────────────────────────────────────────────────────────────
class DiaryService {
  Future<void> addEntry({
    required String internshipId,
    required int dayNumber,
    required String workDone,
    required String mood,
    String? interactions,
    required List<String> categories,
  }) async {
    await ApiClient.post('/diary', {
      'internshipId': internshipId,
      'dayNumber': dayNumber,
      'workDone': workDone,
      'mood': mood,
      if (interactions != null) 'interactions': interactions,
      'categories': categories,
    });
  }

  Future<List<Map<String, dynamic>>> getEntries(String internshipId) async {
    final list = await ApiClient.get('/diary?internshipId=$internshipId') as List;
    return list.cast<Map<String, dynamic>>();
  }
}

// ─────────────────────────────────────────────────────────────
//  ReviewService
// ─────────────────────────────────────────────────────────────
class ReviewService {
  Future<void> submit({
    required String internshipId,
    required String companyId,
    required int env,
    required int mentor,
    required int learn,
    required int relation,
    required bool wouldReturn,
    String? comment,
  }) async {
    await ApiClient.post('/reviews', {
      'internshipId': internshipId,
      'companyId': companyId,
      'envScore': env,
      'mentorScore': mentor,
      'learnScore': learn,
      'relationScore': relation,
      'wouldReturn': wouldReturn,
      if (comment != null) 'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getCompanyReviews(String companyId) async {
    final list = await ApiClient.get('/reviews?companyId=$companyId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getReviewForInternship(String internshipId) async {
    final list = await ApiClient.get('/reviews?internshipId=$internshipId') as List;
    return list.cast<Map<String, dynamic>>();
  }
}

// ─────────────────────────────────────────────────────────────
//  CVService
// ─────────────────────────────────────────────────────────────
class CVService {
  Future<void> save(String studentId, Map<String, dynamic> data) async {
    await ApiClient.put('/cvs/$studentId', data);
  }

  Future<Map<String, dynamic>?> get(String studentId) async {
    final res = await ApiClient.get('/cvs/$studentId');
    if (res == null) return null;
    final map = res as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>?;
  }
}

// ─────────────────────────────────────────────────────────────
//  NotificationService
// ─────────────────────────────────────────────────────────────
class NotificationService {
  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    final list = await ApiClient.get('/notifications?uid=$uid') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<int> getUnreadCount() async {
    final res = await ApiClient.get('/notifications/unread-count') as Map<String, dynamic>;
    return res['count'] as int? ?? 0;
  }

  Future<void> markRead(String id) => ApiClient.put('/notifications/$id/read', {});

  Future<void> markAllRead() => ApiClient.put('/notifications/read-all', {});
}

// ─────────────────────────────────────────────────────────────
//  ScheduleService
// ─────────────────────────────────────────────────────────────
class ScheduleService {
  Future<List<Map<String, dynamic>>> getSchedule(String studentId) async {
    final list = await ApiClient.get('/schedules?studentId=$studentId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveSchedule(List<Map<String, dynamic>> items) async {
    await ApiClient.putList('/schedules', items);
  }
}

// ─────────────────────────────────────────────────────────────
//  InternTrackingService
// ─────────────────────────────────────────────────────────────
class InternTrackingService {
  Future<List<Map<String, dynamic>>> getCompanyInternships(String companyId) async {
    final list = await ApiClient.get('/internships?companyId=$companyId') as List;
    return list.cast<Map<String, dynamic>>();
  }
}

// ─────────────────────────────────────────────────────────────
//  AssessmentService  (компани шалгалт үүсгэх / оюутан хариулах)
// ─────────────────────────────────────────────────────────────
class AssessmentService {
  Future<void> saveCompanyQuestions(String companyId, List<Map<String, dynamic>> questions) =>
      ApiClient.put('/companies/$companyId/assessment', {'questions': questions});

  Future<List<Map<String, dynamic>>> getCompanyQuestions(String companyId) async {
    try {
      final res = await ApiClient.get('/companies/$companyId/assessment');
      if (res == null) return [];
      final qs = (res as Map<String, dynamic>)['questions'] as List? ?? [];
      return qs.cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  Future<void> submitAnswers({
    required String applicationId,
    required String companyId,
    required List<Map<String, dynamic>> answers,
  }) => ApiClient.post('/assessment-responses', {
    'applicationId': applicationId,
    'companyId':     companyId,
    'answers':       answers,
  });

  Future<Map<String, dynamic>?> getAnswers(String applicationId) async {
    try {
      return await ApiClient.get('/assessment-responses/$applicationId') as Map<String, dynamic>?;
    } catch (_) { return null; }
  }
}

// ─────────────────────────────────────────────────────────────
//  StudentReviewService  (компани → оюутан үнэлнэ)
// ─────────────────────────────────────────────────────────────
class StudentReviewService {
  Future<void> submit({
    required String internshipId,
    required String studentId,
    required int work,
    required int attitude,
    required int punctuality,
    required int learning,
    required bool wouldRehire,
    String? comment,
  }) async {
    await ApiClient.post('/student-reviews', {
      'internshipId':      internshipId,
      'studentId':         studentId,
      'workScore':         work,
      'attitudeScore':     attitude,
      'punctualityScore':  punctuality,
      'learningScore':     learning,
      'wouldRehire':       wouldRehire,
      if (comment != null) 'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getForInternship(String internshipId) async {
    final list = await ApiClient.get('/student-reviews?internshipId=$internshipId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getForStudent(String studentId) async {
    final list = await ApiClient.get('/student-reviews?studentId=$studentId') as List;
    return list.cast<Map<String, dynamic>>();
  }
}

// ─────────────────────────────────────────────────────────────
//  MessageService
// ─────────────────────────────────────────────────────────────
class MessageService {
  Future<List<Map<String, dynamic>>> getConversations() async {
    final list = await ApiClient.get('/messages/conversations') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMessages(String withUid) async {
    final list = await ApiClient.get('/messages?with=$withUid') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> send(String toUid, String content) async {
    await ApiClient.post('/messages', {'toUid': toUid, 'content': content});
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await ApiClient.get('/messages/unread-count') as Map<String, dynamic>;
      return res['count'] as int? ?? 0;
    } catch (_) { return 0; }
  }
}

// ─────────────────────────────────────────────────────────────
//  InterviewService
// ─────────────────────────────────────────────────────────────
class InterviewService {
  Future<void> propose({
    required String applicationId,
    required String studentId,
    required String scheduledAt,
    String? location,
    String? notes,
  }) async {
    await ApiClient.post('/interview-slots', {
      'applicationId': applicationId,
      'studentId':     studentId,
      'scheduledAt':   scheduledAt,
      if (location != null) 'location': location,
      if (notes    != null) 'notes':    notes,
    });
  }

  Future<List<Map<String, dynamic>>> getSlots(String applicationId) async {
    final list = await ApiClient.get('/interview-slots?applicationId=$applicationId') as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> respond(String slotId, String status) async {
    await ApiClient.put('/interview-slots/$slotId', {'status': status});
  }
}

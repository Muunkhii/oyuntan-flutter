// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Collection ссылкууд ──────────────────────────────
class DB {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String,dynamic>> get users       => _db.collection('users');
  static CollectionReference<Map<String,dynamic>> get students    => _db.collection('students');
  static CollectionReference<Map<String,dynamic>> get companies   => _db.collection('companies');
  static CollectionReference<Map<String,dynamic>> get posts       => _db.collection('internship_posts');
  static CollectionReference<Map<String,dynamic>> get freelance   => _db.collection('freelance_posts');
  static CollectionReference<Map<String,dynamic>> get applications=> _db.collection('applications');
  static CollectionReference<Map<String,dynamic>> get internships => _db.collection('internships');
  static CollectionReference<Map<String,dynamic>> get diary       => _db.collection('diary_entries');
  static CollectionReference<Map<String,dynamic>> get reviews     => _db.collection('reviews');
  static CollectionReference<Map<String,dynamic>> get cvs         => _db.collection('cvs');
  static CollectionReference<Map<String,dynamic>> get notifications => _db.collection('notifications');
}

// ── Auth Service ─────────────────────────────────────
class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStream => _auth.authStateChanges();

  // Оюутан бүртгэл
  Future<UserCredential> registerStudent({
    required String email,
    required String password,
    required Map<String, dynamic> studentData,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    try {
      await DB.users.doc(uid).set({
        'uid': uid, 'email': email, 'type': 'student',
        'language': 'mn', 'createdAt': FieldValue.serverTimestamp(),
      });
      await DB.students.doc(uid).set({
        ...studentData, 'uid': uid, 'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Firestore амжилтгүй болвол auth user-ийг устгана
      await cred.user!.delete();
      rethrow;
    }
    return cred;
  }

  // Компани бүртгэл
  Future<UserCredential> registerCompany({
    required String email,
    required String password,
    required Map<String, dynamic> companyData,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    try {
      await DB.users.doc(uid).set({
        'uid': uid, 'email': email, 'type': 'company',
        'language': 'mn', 'createdAt': FieldValue.serverTimestamp(),
      });
      await DB.companies.doc(uid).set({
        ...companyData, 'uid': uid, 'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await cred.user!.delete();
      rethrow;
    }
    return cred;
  }

  // Нэвтрэх
  Future<UserCredential> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // Гарах
  Future<void> logout() => _auth.signOut();

  // Нууц үг солих
  Future<void> changePassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);

  // Нууц үг сэргээх имэйл илгээх
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // Хэрэглэгчийн төрөл (student/company)
  Future<String> getUserType(String uid) async {
    final doc = await DB.users.doc(uid).get();
    return doc.data()?['type'] ?? 'student';
  }
}

// ── Internship Post Service ───────────────────────────
class InternshipService {
  // Зар нийтлэх (компани)
  Future<String> createPost(Map<String, dynamic> data) async {
    final ref = await DB.posts.add({
      ...data,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'applicantCount': 0,
    });
    return ref.id;
  }

  // Бүх зарыг авах (оюутан жагсаалт)
  Stream<QuerySnapshot> getAllPosts() =>
      DB.posts
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots();

  // Feed (оюутан swipe-д)
  Stream<QuerySnapshot> getFeed({required String major}) =>
      DB.posts
          .where('isActive', isEqualTo: true)
          .where('majors', arrayContains: major)
          .orderBy('createdAt', descending: true)
          .snapshots();

  // Компанийн зарнууд
  Stream<QuerySnapshot> getCompanyPosts(String companyId) =>
      DB.posts
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .snapshots();

  // Хүсэлт илгээх (swipe right)
  Future<void> apply({
    required String postId,
    required String studentId,
    required String companyId,
    String? message,
  }) async {
    final existing = await DB.applications
        .where('postId', isEqualTo: postId)
        .where('studentId', isEqualTo: studentId)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('Аль хэдийн хүсэлт илгээсэн');

    await DB.applications.add({
      'postId': postId, 'studentId': studentId, 'companyId': companyId,
      'status': 'pending', 'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Applicant count нэмэх
    await DB.posts.doc(postId).update({'applicantCount': FieldValue.increment(1)});

    // Компанид мэдэгдэл
    await DB.notifications.add({
      'toUid': companyId, 'type': 'new_application',
      'postId': postId, 'studentId': studentId,
      'read': false, 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Хүсэлт хүлээн авах → Internship үүсгэх
  Future<void> acceptApplication({
    required String applicationId,
    required String studentId,
    required String postId,
    required int durationDays,
    required String companyId,
  }) async {
    await DB.applications.doc(applicationId).update({'status': 'accepted'});

    final endDate = DateTime.now().add(Duration(days: durationDays));
    await DB.internships.add({
      'studentId': studentId, 'postId': postId,
      'companyId': companyId,
      'status': 'active', 'durationDays': durationDays,
      'startDate': FieldValue.serverTimestamp(),
      'endDate': Timestamp.fromDate(endDate),
      'completedDays': 0,
    });

    // Оюутанд мэдэгдэл
    await DB.notifications.add({
      'toUid': studentId, 'type': 'application_accepted',
      'postId': postId, 'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // CV жагсаалт (компани swipe)
  Stream<QuerySnapshot> getCandidates(String postId) =>
      DB.applications
          .where('postId', isEqualTo: postId)
          .where('status', isEqualTo: 'pending')
          .snapshots();
}

// ── Diary Service ─────────────────────────────────────
class DiaryService {
  // Өдрийн тэмдэглэл нэмэх
  Future<void> addEntry({
    required String internshipId,
    required String studentId,
    required int dayNumber,
    required String workDone,
    required String mood,
    String? interactions,
    required List<String> categories,
  }) async {
    // Давхардал шалгах
    final exists = await DB.diary
        .where('internshipId', isEqualTo: internshipId)
        .where('dayNumber', isEqualTo: dayNumber)
        .get();
    if (exists.docs.isNotEmpty) throw Exception('Энэ өдрийн тэмдэглэл аль хэдийн байна');

    await DB.diary.add({
      'internshipId': internshipId, 'studentId': studentId,
      'dayNumber': dayNumber, 'workDone': workDone,
      'mood': mood, 'interactions': interactions,
      'categories': categories,
      'date': FieldValue.serverTimestamp(),
    });

    // Internship дахь completedDays шинэчлэх
    await DB.internships.doc(internshipId).update({
      'completedDays': FieldValue.increment(1),
    });
  }

  // Тэмдэглэл жагсаалт
  Stream<QuerySnapshot> getEntries(String internshipId) =>
      DB.diary
          .where('internshipId', isEqualTo: internshipId)
          .orderBy('dayNumber')
          .snapshots();
}

// ── Review Service ────────────────────────────────────
class ReviewService {
  Future<void> submitReview({
    required String internshipId,
    required String studentId,
    required String companyId,
    required int envScore,
    required int mentorScore,
    required int learnScore,
    required int relationScore,
    required bool wouldReturn,
    String? comment,
  }) async {
    final existing = await DB.reviews
        .where('internshipId', isEqualTo: internshipId)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('Үнэлгээ аль хэдийн илгээсэн');

    final avg = (envScore + mentorScore + learnScore + relationScore) / 4;

    await DB.reviews.add({
      'internshipId': internshipId, 'studentId': studentId,
      'companyId': companyId,
      'envScore': envScore, 'mentorScore': mentorScore,
      'learnScore': learnScore, 'relationScore': relationScore,
      'avgScore': avg, 'wouldReturn': wouldReturn, 'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Internship дуусгах
    await DB.internships.doc(internshipId).update({'status': 'completed'});

    // Компанийн average score шинэчлэх
    final reviews = await DB.reviews.where('companyId', isEqualTo: companyId).get();
    final allAvg = reviews.docs.map((d) => (d['avgScore'] as num).toDouble()).reduce((a, b) => a + b) / reviews.docs.length;
    await DB.companies.doc(companyId).update({'avgScore': allAvg, 'reviewCount': reviews.docs.length});
  }

  Stream<QuerySnapshot> getCompanyReviews(String companyId) =>
      DB.reviews.where('companyId', isEqualTo: companyId).orderBy('createdAt', descending: true).snapshots();
}

// ── CV Service ────────────────────────────────────────
class CVService {
  Future<void> saveCV(String studentId, Map<String, dynamic> data) =>
      DB.cvs.doc(studentId).set({...data, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  Stream<DocumentSnapshot> getCV(String studentId) => DB.cvs.doc(studentId).snapshots();
}

// ── Profile Update Service ────────────────────────────
class ProfileService {
  Future<void> updateStudent(String uid, Map<String, dynamic> data) =>
      DB.students.doc(uid).update(data);

  Future<void> updateCompany(String uid, Map<String, dynamic> data) =>
      DB.companies.doc(uid).update(data);
}

// ── Notification Service ──────────────────────────────
class NotificationService {
  // Мэдэгдлүүд (uid-аар шүүсэн, клиент талд эрэмбэлнэ)
  Stream<List<QueryDocumentSnapshot>> getNotifications(String uid) =>
      DB.notifications
          .where('toUid', isEqualTo: uid)
          .snapshots()
          .map((s) {
            final docs = List<QueryDocumentSnapshot>.from(s.docs);
            docs.sort((a, b) {
              final at = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bt = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });
            return docs;
          });

  // Уншаагүй мэдэгдлийн тоо
  Stream<int> unreadCount(String uid) =>
      DB.notifications
          .where('toUid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.length);

  // Уншсан гэж тэмдэглэх
  Future<void> markRead(String notifId) =>
      DB.notifications.doc(notifId).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final snap = await DB.notifications
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

// ── Intern tracking ───────────────────────────────────
class InternTrackingService {
  // Компанийн бүх дадлагажигчид
  Stream<QuerySnapshot> getCompanyInternships(String companyId) =>
      DB.internships
          .where('companyId', isEqualTo: companyId)
          .snapshots();

  // Оюутаны идэвхтэй дадлага
  Stream<QuerySnapshot> getStudentActiveInternship(String studentId) =>
      DB.internships
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .snapshots();

  // Оюутаны бүх дадлагууд
  Stream<QuerySnapshot> getStudentInternships(String studentId) =>
      DB.internships
          .where('studentId', isEqualTo: studentId)
          .snapshots();
}

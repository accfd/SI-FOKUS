import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/repositories/student_progress_repository.dart';
import '../../data/models/student_progress_model.dart';
import '../../data/models/quick_check_session_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  if (!kIsWeb) return false;
  return true;
}

class StudentProgressRepositoryImpl implements StudentProgressRepository {
  final FirebaseFirestore? _firestore;

  StudentProgressRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  String _progressKey(String studentId, String materialId) =>
      '${studentId}_$materialId';

  @override
  Future<StudentProgressModel?> getProgress(String studentId, String materialId) async {
    if (isMockMode) {
      await MockDb.init();
      final allProgress = await MockDb.getAll('student_progress');
      final match = allProgress.firstWhere(
        (p) => p['studentId'] == studentId && p['materialId'] == materialId,
        orElse: () => const {},
      );
      if (match.isEmpty) return null;
      return StudentProgressModel.fromJson(match);
    }

    final snapshot = await _firestore!
        .collection('student_progress')
        .where('studentId', isEqualTo: studentId)
        .where('materialId', isEqualTo: materialId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return StudentProgressModel.fromJson(snapshot.docs.first.data());
  }

  @override
  Future<void> updateProgress(StudentProgressModel progress) async {
    if (isMockMode) {
      await MockDb.init();
      await MockDb.save(
        'student_progress',
        _progressKey(progress.studentId, progress.materialId),
        progress.toJson(),
      );
      return;
    }

    // Firestore: upsert by studentId + materialId
    final snapshot = await _firestore!
        .collection('student_progress')
        .where('studentId', isEqualTo: progress.studentId)
        .where('materialId', isEqualTo: progress.materialId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.set(progress.toJson(), SetOptions(merge: true));
    } else {
      await _firestore!.collection('student_progress').add(progress.toJson());
    }
  }

  @override
  Future<void> saveQuickCheckSession(QuickCheckSessionModel session) async {
    if (isMockMode) {
      await MockDb.init();
      await MockDb.save('quick_check_sessions', session.sessionId, session.toJson());
      return;
    }

    await _firestore!
        .collection('quick_check_sessions')
        .doc(session.sessionId)
        .set(session.toJson());
  }

  @override
  Future<void> updateQuickCheckSession(QuickCheckSessionModel session) async {
    if (isMockMode) {
      await MockDb.init();
      await MockDb.save('quick_check_sessions', session.sessionId, session.toJson());
      return;
    }

    await _firestore!
        .collection('quick_check_sessions')
        .doc(session.sessionId)
        .update(session.toJson());
  }
}

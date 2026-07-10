import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'parent_monitoring_event.dart';
import 'parent_monitoring_state.dart';

class ParentMonitoringBloc
    extends Bloc<ParentMonitoringEvent, ParentMonitoringState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _childSubscription;

  ParentMonitoringBloc() : super(const ParentMonitoringInitial()) {
    on<LoadChildData>(_onLoadChildData);
    on<ChildDataUpdated>(_onChildDataUpdated);
  }

  Future<void> _onLoadChildData(
    LoadChildData event,
    Emitter<ParentMonitoringState> emit,
  ) async {
    emit(const ParentMonitoringLoading());

    try {
      // ── DUMMY MODE: langsung berikan data mock ──
      // Karena Firebase belum terhubung ke project sungguhan,
      // kita langsung return data dummy untuk demo UI.
      final dummyActivities = [
        {
          'materialTitle': 'Biologi: Sistem Pencernaan',
          'focusScore': 85.0,
          'readDurationSec': 720,
          'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'materialTitle': 'Sejarah: Perang Dunia II',
          'focusScore': 72.0,
          'readDurationSec': 540,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'materialTitle': 'Matematika: Aljabar Linear',
          'focusScore': 91.0,
          'readDurationSec': 900,
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        },
      ];

      final dummyQuizResults = [
        {
          'materialTitle': 'Biologi: Sistem Pencernaan',
          'type': 'quick_check',
          'score': 3,
          'totalQuestions': 3,
          'passed': true,
          'date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'materialTitle': 'Biologi: Sistem Pencernaan',
          'type': 'quiz_utama',
          'score': 4,
          'totalQuestions': 5,
          'passed': true,
          'date': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'materialTitle': 'Sejarah: Perang Dunia II',
          'type': 'quick_check',
          'score': 1,
          'totalQuestions': 3,
          'passed': false,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];

      emit(ParentMonitoringLoaded(
        childName: 'Ahmad Fauzi',
        childEmail: 'ahmad.fauzi@siswa.id',
        className: 'Kelas 8A - Biologi',
        childXp: 1250,
        childLevel: 5,
        childBadges: ['Pembaca Setia', 'Quick Learner', 'Focus Master'],
        averageFocusScore: 82.7,
        totalActivities: 12,
        quizzesPassed: 8,
        quizzesFailed: 2,
        recentActivities: dummyActivities,
        quizResults: dummyQuizResults,
      ));

      return; // skip Firestore

      // ── PRODUCTION CODE (aktifkan jika Firebase sudah live) ──
      // ignore: dead_code
      final parentDoc =
          await _firestore.collection('users').doc(event.parentUid).get();

      if (!parentDoc.exists) {
        emit(const ParentMonitoringError('Data akun tidak ditemukan.'));
        return;
      }

      final linkedStudentUid =
          parentDoc.data()?['linkedStudentUid'] as String?;

      if (linkedStudentUid == null || linkedStudentUid.isEmpty) {
        emit(const ParentMonitoringNoChild());
        return;
      }

      // Stream real-time data anak
      _childSubscription?.cancel();
      _childSubscription = _firestore
          .collection('users')
          .doc(linkedStudentUid)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists) {
          add(const ChildDataUpdated(
            childData: {},
            recentActivities: [],
            quizResults: [],
          ));
          return;
        }

        final childData = snapshot.data()!;

        // Fetch aktivitas terbaru anak
        final activitiesSnapshot = await _firestore
            .collection('activities')
            .where('studentId', isEqualTo: linkedStudentUid)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        final activities = activitiesSnapshot.docs
            .map((doc) => doc.data())
            .toList();

        // Fetch hasil kuis anak
        final progressSnapshot = await _firestore
            .collection('student_progress')
            .where('studentId', isEqualTo: linkedStudentUid)
            .get();

        final quizResults = progressSnapshot.docs
            .map((doc) => doc.data())
            .toList();

        add(ChildDataUpdated(
          childData: childData,
          recentActivities: activities,
          quizResults: quizResults,
        ));
      }, onError: (error) {
        debugPrint('ParentMonitoring stream error: $error');
      });
    } catch (e) {
      emit(ParentMonitoringError('Gagal memuat data anak: $e'));
    }
  }

  void _onChildDataUpdated(
    ChildDataUpdated event,
    Emitter<ParentMonitoringState> emit,
  ) {
    final data = event.childData;

    if (data.isEmpty) {
      emit(const ParentMonitoringError('Data anak tidak ditemukan.'));
      return;
    }

    // Hitung rata-rata fokus
    double avgFocus = 0;
    if (event.recentActivities.isNotEmpty) {
      final totalFocus = event.recentActivities.fold<double>(
        0,
        (total, a) => total + (a['focusScore'] as num? ?? 0).toDouble(),
      );
      avgFocus = totalFocus / event.recentActivities.length;
    }

    // Hitung kuis lulus/gagal
    int passed = 0;
    int failed = 0;
    for (var q in event.quizResults) {
      if (q['isQuickCheckPassed'] == true) {
        passed++;
      } else {
        failed++;
      }
    }

    emit(ParentMonitoringLoaded(
      childName: data['name'] as String? ?? 'Siswa',
      childEmail: data['email'] as String? ?? '-',
      className: '-',
      childXp: data['xp'] as int? ?? 0,
      childLevel: data['level'] as int? ?? 1,
      childBadges: (data['unlockedBadges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageFocusScore: avgFocus,
      totalActivities: event.recentActivities.length,
      quizzesPassed: passed,
      quizzesFailed: failed,
      recentActivities: event.recentActivities,
      quizResults: event.quizResults,
    ));
  }

  @override
  Future<void> close() {
    _childSubscription?.cancel();
    return super.close();
  }
}

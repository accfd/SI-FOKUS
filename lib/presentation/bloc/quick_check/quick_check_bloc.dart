import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/assessment_model.dart';
import '../../../../data/models/question_model.dart';
import '../../../../data/repositories/mock_db.dart';
import 'quick_check_event.dart';
import 'quick_check_state.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class QuickCheckBloc extends Bloc<QuickCheckEvent, QuickCheckState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track state internally for submission
  AssessmentModel? _currentAssessment;
  String _currentStudentId = '';
  String _currentMaterialId = '';

  QuickCheckBloc() : super(QuickCheckInitial()) {
    on<LoadQuickCheck>(_onLoadQuickCheck);
    on<SubmitQuickCheck>(_onSubmitQuickCheck);
  }

  Future<void> _onLoadQuickCheck(
    LoadQuickCheck event,
    Emitter<QuickCheckState> emit,
  ) async {
    emit(QuickCheckLoading());
    try {
      _currentStudentId = event.studentId;
      _currentMaterialId = event.materialId;

      AssessmentModel? assessment;

      if (isMockMode) {
        // 1. Cek progress siswa untuk materi ini
        final allProgress = await MockDb.getAll('student_progress');
        final progressMatch = allProgress.firstWhere(
          (p) => p['studentId'] == event.studentId && p['materialId'] == event.materialId,
          orElse: () => const {},
        );

        if (progressMatch.isNotEmpty) {
          if (progressMatch['isQuickCheckPassed'] == true && event.assessmentType == 'quick_check') {
            emit(const QuickCheckPassed(score: 3));
            return;
          }
          if (progressMatch['cooldownUntil'] != null) {
            final cooldownTime = DateTime.parse(progressMatch['cooldownUntil'] as String);
            if (DateTime.now().isBefore(cooldownTime)) {
              emit(QuickCheckCooldown(cooldownUntil: cooldownTime));
              return;
            }
          }
        }

        // 2. Muat soal dari MockDb
        final allAssessments = await MockDb.getAll('assessments');
        final match = allAssessments.firstWhere(
          (a) => a['materialId'] == event.materialId && a['type'] == event.assessmentType,
          orElse: () => const {},
        );

        if (match.isNotEmpty) {
          assessment = AssessmentModel.fromJson(match);
        }
      } else {
        // Online Firestore
        // 1. Cek progress
        final progressSnapshot = await _firestore
            .collection('student_progress')
            .where('studentId', isEqualTo: event.studentId)
            .where('materialId', isEqualTo: event.materialId)
            .limit(1)
            .get();

        if (progressSnapshot.docs.isNotEmpty) {
          final progressData = progressSnapshot.docs.first.data();
          if (progressData['isQuickCheckPassed'] == true && event.assessmentType == 'quick_check') {
            emit(const QuickCheckPassed(score: 3));
            return;
          }
          if (progressData['cooldownUntil'] != null) {
            DateTime cooldownTime = (progressData['cooldownUntil'] as Timestamp).toDate();
            if (DateTime.now().isBefore(cooldownTime)) {
              emit(QuickCheckCooldown(cooldownUntil: cooldownTime));
              return;
            }
          }
        }

        // 2. Muat soal dari Firestore
        final assessmentSnapshot = await _firestore
            .collection('assessments')
            .where('materialId', isEqualTo: event.materialId)
            .where('type', isEqualTo: event.assessmentType)
            .limit(1)
            .get();

        if (assessmentSnapshot.docs.isNotEmpty) {
          assessment = AssessmentModel.fromJson(
            assessmentSnapshot.docs.first.data()..['assessmentId'] = assessmentSnapshot.docs.first.id
          );
        }
      }

      // Fallback jika tidak ditemukan di database
      if (assessment == null) {
        final isMainQuiz = event.assessmentType == 'quiz_utama';
        assessment = AssessmentModel(
          assessmentId: isMainQuiz ? 'dummy_qu_${event.materialId}' : 'dummy_qc_${event.materialId}',
          materialId: event.materialId,
          classId: 'dummy_class',
          type: event.assessmentType,
          durationMinutes: isMainQuiz ? 15 : 5,
          questions: isMainQuiz 
              ? List.generate(10, (idx) => QuestionModel(
                  questionId: 'q_$idx',
                  questionText: 'Pertanyaan Kuis Utama $idx mengenai materi ini?',
                  options: ['Opsi A', 'Opsi B', 'Opsi C', 'Opsi D'],
                  correctAnswerIndex: idx % 4,
                ))
              : List.generate(5, (idx) => QuestionModel(
                  questionId: 'q_$idx',
                  questionText: 'Pertanyaan Quick Check $idx mengenai materi ini?',
                  options: ['Opsi A', 'Opsi B', 'Opsi C', 'Opsi D'],
                  correctAnswerIndex: idx % 4,
                )),
        );
      }

      _currentAssessment = assessment;

      // Randomisasi Soal untuk Quick Check (Ambil 3 Soal dari total pool)
      List<QuestionModel> finalQuestions = List<QuestionModel>.from(assessment.questions);
      if (event.assessmentType == 'quick_check') {
        finalQuestions.shuffle(Random());
        finalQuestions = finalQuestions.take(3).toList();
      }

      emit(QuickCheckReady(
        assessment: assessment,
        questions: finalQuestions,
      ));
    } catch (e) {
      emit(QuickCheckError('Gagal memuat kuis: $e'));
    }
  }

  Future<void> _onSubmitQuickCheck(
    SubmitQuickCheck event,
    Emitter<QuickCheckState> emit,
  ) async {
    if (_currentAssessment == null) return;
    
    emit(QuickCheckLoading());
    try {
      int correctAnswers = 0;

      for (var question in _currentAssessment!.questions) {
        final studentAnswer = event.answers[question.questionId];
        if (studentAnswer == null) continue;

        if (question.type == 'majemuk_kompleks') {
          final correctAnswersList = question.correctAnswers ?? [1, 0, 1];
          if (studentAnswer is List) {
            bool allCorrect = true;
            for (int i = 0; i < correctAnswersList.length; i++) {
              if (i < studentAnswer.length && studentAnswer[i] != correctAnswersList[i]) {
                allCorrect = false;
                break;
              }
            }
            if (allCorrect) {
              correctAnswers++;
            }
          }
        } else if (question.type == 'isian_singkat') {
          final correctText = question.correctAnswerText ?? '';
          if (studentAnswer is String &&
              studentAnswer.trim().toLowerCase() == correctText.trim().toLowerCase()) {
            correctAnswers++;
          }
        } else {
          if (studentAnswer is int && studentAnswer == question.correctAnswerIndex) {
            correctAnswers++;
          }
        }
      }

      final isQC = _currentAssessment!.type == 'quick_check';
      final totalQs = event.answers.length; // Number of questions presented
      final passingThreshold = isQC ? 2 : (totalQs * 0.6).ceil();

      if (isMockMode) {
        // Simpan progress di MockDb
        final allProgress = await MockDb.getAll('student_progress');
        final matchIndex = allProgress.indexWhere(
          (p) => p['studentId'] == _currentStudentId && p['materialId'] == _currentMaterialId,
        );

        final Map<String, dynamic> newProgress = {
          'studentId': _currentStudentId,
          'materialId': _currentMaterialId,
        };

        if (matchIndex >= 0) {
          newProgress.addAll(Map<String, dynamic>.from(allProgress[matchIndex]));
        }

        if (correctAnswers >= passingThreshold || !isQC) {
          if (isQC) {
            newProgress['isQuickCheckPassed'] = true;
          } else {
            newProgress['isQuizUtamaCompleted'] = true;
          }
          newProgress['completedAt'] = DateTime.now().toIso8601String();
          
          if (matchIndex >= 0) {
            allProgress[matchIndex] = newProgress;
          } else {
            allProgress.add(newProgress);
          }
          await MockDb.save('student_progress', '${_currentStudentId}_${_currentMaterialId}', newProgress);
          emit(QuickCheckPassed(score: correctAnswers));
        } else {
          final cooldownEnd = DateTime.now().add(const Duration(minutes: 10));
          newProgress['isQuickCheckPassed'] = false;
          newProgress['cooldownUntil'] = cooldownEnd.toIso8601String();

          if (matchIndex >= 0) {
            allProgress[matchIndex] = newProgress;
          } else {
            allProgress.add(newProgress);
          }
          await MockDb.save('student_progress', '${_currentStudentId}_${_currentMaterialId}', newProgress);
          emit(QuickCheckFailed(score: correctAnswers, cooldownUntil: cooldownEnd));
        }
        return;
      }

      // Online Firestore
      // Cari atau buat doc reference untuk progress
      final progressQuery = await _firestore
          .collection('student_progress')
          .where('studentId', isEqualTo: _currentStudentId)
          .where('materialId', isEqualTo: _currentMaterialId)
          .limit(1)
          .get();

      DocumentReference progressRef;
      if (progressQuery.docs.isNotEmpty) {
        progressRef = progressQuery.docs.first.reference;
      } else {
        progressRef = _firestore.collection('student_progress').doc();
      }

      if (correctAnswers >= passingThreshold || !isQC) {
        // LULUS
        await progressRef.set({
          'studentId': _currentStudentId,
          'materialId': _currentMaterialId,
          isQC ? 'isQuickCheckPassed' : 'isQuizUtamaCompleted': true,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        emit(QuickCheckPassed(score: correctAnswers));
      } else {
        // GAGAL -> Cooldown 10 menit
        final cooldownEnd = DateTime.now().add(const Duration(minutes: 10));
        
        await progressRef.set({
          'studentId': _currentStudentId,
          'materialId': _currentMaterialId,
          'isQuickCheckPassed': false,
          'cooldownUntil': Timestamp.fromDate(cooldownEnd),
        }, SetOptions(merge: true));

        emit(QuickCheckFailed(score: correctAnswers, cooldownUntil: cooldownEnd));
      }
    } catch (e) {
      emit(QuickCheckError('Gagal mengirim kuis: $e'));
    }
  }
}

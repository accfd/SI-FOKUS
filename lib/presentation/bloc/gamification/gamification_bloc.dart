import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/user_model.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GamificationBloc() : super(GamificationInitial()) {
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<ProcessQuizResult>(_onProcessQuizResult);
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .orderBy('xp', descending: true)
          .limit(10)
          .get();

      final List<UserModel> topStudents = snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()..['uid'] = doc.id))
          .toList();

      if (topStudents.isEmpty) {
        topStudents.addAll(_getMockLeaderboard());
      }
      
      emit(LeaderboardLoaded(topStudents));
    } catch (e) {
      emit(LeaderboardLoaded(_getMockLeaderboard()));
    }
  }

  List<UserModel> _getMockLeaderboard() {
    return [
      UserModel(uid: 'mock1', name: 'Budi Santoso', email: 'budi@test.com', role: 'siswa', xp: 2450, level: 3, unlockedBadges: ['Focus Master', 'Veteran Scholar'], createdAt: DateTime.now()),
      UserModel(uid: 'mock2', name: 'Siti Aminah', email: 'siti@test.com', role: 'siswa', xp: 1980, level: 2, unlockedBadges: ['Perfect Score'], createdAt: DateTime.now()),
      UserModel(uid: 'mock3', name: 'Andi Wijaya', email: 'andi@test.com', role: 'siswa', xp: 1200, level: 2, unlockedBadges: [], createdAt: DateTime.now()),
      UserModel(uid: 'mock4', name: 'Rina Melati', email: 'rina@test.com', role: 'siswa', xp: 950, level: 1, unlockedBadges: [], createdAt: DateTime.now()),
      UserModel(uid: 'mock5', name: 'Dimas Pratama', email: 'dimas@test.com', role: 'siswa', xp: 820, level: 1, unlockedBadges: [], createdAt: DateTime.now()),
    ];
  }

  Future<void> _onProcessQuizResult(
    ProcessQuizResult event,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(event.studentId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      int currentXp = userData['xp'] ?? 0;
      int currentLevel = userData['level'] ?? 1;
      List<String> currentBadges = List<String>.from(userData['unlockedBadges'] ?? []);

      // 1. Kalkulasi XP
      int xpGained = (event.quizScore * 2).toInt();
      int newXp = currentXp + xpGained;

      // 2. Kalkulasi Level (misal naik level setiap 1000 XP)
      int newLevel = (newXp / 1000).floor() + 1;
      bool isLevelUp = newLevel > currentLevel;

      // 3. Cek Kriteria Badge
      List<String> newBadgesAchieved = [];
      if (event.focusScore > 90 && !currentBadges.contains('Focus Master')) {
        newBadgesAchieved.add('Focus Master');
        currentBadges.add('Focus Master');
      }
      if (event.quizScore == 100 && !currentBadges.contains('Perfect Score')) {
        newBadgesAchieved.add('Perfect Score');
        currentBadges.add('Perfect Score');
      }
      if (newLevel >= 5 && !currentBadges.contains('Veteran Scholar')) {
        newBadgesAchieved.add('Veteran Scholar');
        currentBadges.add('Veteran Scholar');
      }

      // Update Firestore
      await _firestore.collection('users').doc(event.studentId).update({
        'xp': newXp,
        'level': newLevel,
        'unlockedBadges': currentBadges,
      });

      // Emit Achieved state untuk memicu animasi Lottie popup
      emit(GamificationAchieved(
        xpGained: xpGained,
        newLevel: isLevelUp ? newLevel : null,
        newBadges: newBadgesAchieved,
      ));
    } catch (e) {
      emit(GamificationError('Gagal memproses gamifikasi: $e'));
    }
  }
}

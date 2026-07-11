import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/models/digital_learning_profile_model.dart';
import 'learning_profile_event.dart';
import 'learning_profile_state.dart';

class LearningProfileBloc extends Bloc<LearningProfileEvent, LearningProfileState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _isMockMode {
    try {
      return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
    } catch (_) {
      return true;
    }
  }

  LearningProfileBloc() : super(ProfileInitial()) {
    on<LoadDigitalLearningProfile>(_onLoadDigitalLearningProfile);
  }

  Future<void> _onLoadDigitalLearningProfile(
    LoadDigitalLearningProfile event,
    Emitter<LearningProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    if (_isMockMode) {
      // Instantly load mock profile in local/offline test mode to avoid infinite Firestore wait times
      final mockProfile = _getMockProfile(event.studentId);
      emit(ProfileLoaded(mockProfile));
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('student_profiles')
          .doc(event.studentId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        final profile = DigitalLearningProfileModel.fromJson(snapshot.data()!);
        emit(ProfileLoaded(profile));
      } else {
        // Mock data untuk keperluan visualisasi UI sementara
        // hingga Backend AI mengisi koleksi student_profiles
        final mockProfile = _getMockProfile(event.studentId);
        
        try {
          // Opsional: Simpan mock data ini ke Firestore agar persisten
          await _firestore.collection('student_profiles').doc(event.studentId).set(mockProfile.toJson());
        } catch (_) {}
        
        emit(ProfileLoaded(mockProfile));
      }
    } catch (e) {
      final mockProfile = _getMockProfile(event.studentId);
      emit(ProfileLoaded(mockProfile));
    }
  }

  DigitalLearningProfileModel _getMockProfile(String studentId) {
    return DigitalLearningProfileModel(
      studentId: studentId,
      focusTrend: [
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 6)), focusScore: 65),
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 5)), focusScore: 72),
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 4)), focusScore: 68),
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 3)), focusScore: 85),
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 2)), focusScore: 81),
        FocusDataPoint(date: DateTime.now().subtract(const Duration(days: 1)), focusScore: 92),
        FocusDataPoint(date: DateTime.now(), focusScore: 88),
      ],
      consistencyTrend: [
        ConsistencyDataPoint(weekLabel: 'Mg 1', hoursStudied: 4.5),
        ConsistencyDataPoint(weekLabel: 'Mg 2', hoursStudied: 3.2),
        ConsistencyDataPoint(weekLabel: 'Mg 3', hoursStudied: 6.0),
        ConsistencyDataPoint(weekLabel: 'Mg 4', hoursStudied: 5.5),
      ],
      strongestMaterial: 'Sistem Pencernaan Manusia',
      weakestMaterial: 'Fotosintesis Tingkat Lanjut',
      mostEffectiveMedia: 'Video Interaktif & Animasi',
    );
  }
}

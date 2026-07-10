import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import '../../domain/repositories/question_bank_repository.dart';
import '../../data/models/question_bank_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  if (!kIsWeb) return false;
  return true;
}

/// URL base backend Python FastAPI
const String _backendBaseUrl = 'http://localhost:8000';

class QuestionBankRepositoryImpl implements QuestionBankRepository {
  final FirebaseFirestore? _firestore;

  QuestionBankRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<QuestionBankModel?> fetchQuestionBank(String materialId) async {
    if (isMockMode) {
      await MockDb.init();
      final allBanks = await MockDb.getAll('question_banks');
      final match = allBanks.firstWhere(
        (b) => b['materialId'] == materialId,
        orElse: () => const {},
      );
      if (match.isEmpty) return null;
      return QuestionBankModel.fromJson(match);
    }

    // Firestore: query question_banks by materialId
    final snapshot = await _firestore!
        .collection('question_banks')
        .where('materialId', isEqualTo: materialId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['bankId'] = snapshot.docs.first.id;
    return QuestionBankModel.fromJson(data);
  }

  @override
  Future<bool> triggerBankGeneration({
    required String materialId,
    required String classId,
    required String fileUrl,
    required String fileType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/api/generate-question-bank'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'material_id': materialId,
          'class_id': classId,
          'file_url': fileUrl,
          'file_type': fileType,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Jika dalam mock mode, simpan hasilnya ke MockDb
        if (isMockMode) {
          await MockDb.init();
          final bankData = responseData['question_bank'] as Map<String, dynamic>?;
          if (bankData != null) {
            await MockDb.save('question_banks', bankData['bankId'] as String, bankData);
          }

          // Update material data juga
          final summary = responseData['summary'] as String?;
          final topics = responseData['topics'] as List<dynamic>?;
          if (summary != null || topics != null) {
            final allMaterials = await MockDb.getAll('materials');
            final matIndex = allMaterials.indexWhere((m) => m['materialId'] == materialId);
            if (matIndex >= 0) {
              if (summary != null) allMaterials[matIndex]['summary'] = summary;
              if (topics != null) allMaterials[matIndex]['topics'] = topics;
              allMaterials[matIndex]['aiProcessingStatus'] = 'done';
              await MockDb.save('materials', materialId, allMaterials[matIndex]);
            }
          }
        }

        return true;
      } else {
        final errorBody = response.body;
        debugPrint('Backend error: $errorBody');
        throw Exception('Backend gagal memproses: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error triggering bank generation: $e');
      rethrow;
    }
  }
}

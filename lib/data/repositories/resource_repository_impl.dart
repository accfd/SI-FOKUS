import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/repositories/resource_repository.dart';
import '../../data/models/learning_resource_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  if (!kIsWeb) return false;
  return true; // Selalu mock di web selama development
}

class ResourceRepositoryImpl implements ResourceRepository {
  final FirebaseFirestore? _firestore;

  ResourceRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  // ─── MOCK DB KEY ─────────────────────────────────────────
  String _mockKey(String materialId) => 'learning_resources_$materialId';

  @override
  Future<List<LearningResourceModel>> fetchResources(String materialId) async {
    if (isMockMode) {
      await MockDb.init();
      final raw = await MockDb.getString(_mockKey(materialId));
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => LearningResourceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Firestore: learningResources disimpan sebagai array di dalam dokumen material
    final doc = await _firestore!.collection('materials').doc(materialId).get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    final rawList = data['learningResources'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => LearningResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addResource(String materialId, LearningResourceModel resource) async {
    if (isMockMode) {
      await MockDb.init();
      final existing = await fetchResources(materialId);
      existing.add(resource);
      final encoded = json.encode(existing.map((e) => e.toJson()).toList());
      await MockDb.setString(_mockKey(materialId), encoded);
      return;
    }

    // Firestore: arrayUnion
    await _firestore!.collection('materials').doc(materialId).update({
      'learningResources': FieldValue.arrayUnion([resource.toJson()]),
    });
  }

  @override
  Future<void> removeResource(String materialId, String resourceId) async {
    if (isMockMode) {
      await MockDb.init();
      final existing = await fetchResources(materialId);
      existing.removeWhere((r) => r.resourceId == resourceId);
      final encoded = json.encode(existing.map((e) => e.toJson()).toList());
      await MockDb.setString(_mockKey(materialId), encoded);
      return;
    }

    // Firestore: perlu baca dulu, hapus item, lalu tulis ulang array
    final doc = await _firestore!.collection('materials').doc(materialId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final rawList = (data['learningResources'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    rawList.removeWhere((e) => e['resourceId'] == resourceId);
    await _firestore.collection('materials').doc(materialId).update({
      'learningResources': rawList,
    });
  }
}

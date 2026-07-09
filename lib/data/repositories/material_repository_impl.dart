import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/repositories/material_repository.dart';
import '../models/material_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class MaterialRepositoryImpl implements MaterialRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  MaterialRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance),
        _storage = isMockMode ? null : (storage ?? FirebaseStorage.instance);

  @override
  Future<List<MaterialModel>> fetchClassMaterials(String classId) async {
    if (isMockMode) {
      final allMaterials = await MockDb.getAll('materials');
      return allMaterials
          .where((m) => m['classId'] == classId)
          .map((m) => MaterialModel.fromJson(m))
          .toList();
    }

    final query = await _firestore!
        .collection('materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => MaterialModel.fromJson(doc.data())).toList();
  }

  @override
  Future<void> updateMaterialPublishStatus(String materialId, bool isPublished) async {
    if (isMockMode) {
      final data = await MockDb.get('materials', materialId);
      if (data != null) {
        data['isPublished'] = isPublished;
        await MockDb.save('materials', materialId, data);
      }
      return;
    }
    await _firestore!.collection('materials').doc(materialId).update({
      'isPublished': isPublished,
    });
  }

  @override
  Stream<MaterialModel> streamMaterialDetail(String materialId) {
    if (isMockMode) {
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        final data = await MockDb.get('materials', materialId);
        if (data == null) {
          throw Exception('Materi tidak ditemukan.');
        }
        return MaterialModel.fromJson(data);
      });
    }

    return _firestore!
        .collection('materials')
        .doc(materialId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            throw Exception('Materi tidak ditemukan.');
          }
          return MaterialModel.fromJson(doc.data()!);
        });
  }

  @override
  Stream<double> uploadMaterialFile({
    required String materialId,
    required String classId,
    required String fileName,
    required List<int> fileBytes,
  }) {
    if (isMockMode) {
      // Simulasikan progress bar unggahan file
      final controller = StreamController<double>();
      int counter = 0;
      Timer.periodic(const Duration(milliseconds: 200), (timer) {
        counter++;
        final progress = counter * 0.2;
        if (progress >= 1.0) {
          if (!controller.isClosed) {
            controller.add(1.0);
            controller.close();
          }
          timer.cancel();
        } else {
          if (!controller.isClosed) {
            controller.add(progress);
          }
        }
      });
      return controller.stream;
    }

    final ref = _storage!.ref().child('materials/$classId/$materialId/$fileName');
    final uploadTask = ref.putData(Uint8List.fromList(fileBytes));

    return uploadTask.snapshotEvents.map((snapshot) {
      if (snapshot.totalBytes == 0) return 0.0;
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  @override
  Future<void> saveMaterialMetadata(MaterialModel material) async {
    if (isMockMode) {
      await MockDb.save('materials', material.materialId, material.toJson());
      return;
    }
    await _firestore!
        .collection('materials')
        .doc(material.materialId)
        .set(material.toFirestore());
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    if (isMockMode) {
      // URL contoh PDF agar penampil PDF (syncfusion_flutter_pdfviewer) tidak crash saat uji coba lokal
      return "https://pdfobject.com/pdf/sample.pdf";
    }
    return await _storage!.ref().child(path).getDownloadURL();
  }
}

import '../../data/models/material_model.dart';

abstract class MaterialRepository {
  Future<List<MaterialModel>> fetchClassMaterials(String classId);
  
  Future<void> updateMaterialPublishStatus(String materialId, bool isPublished);
  
  Stream<MaterialModel> streamMaterialDetail(String materialId);
  
  Stream<double> uploadMaterialFile({
    required String materialId,
    required String classId,
    required String fileName,
    required List<int> fileBytes,
  });

  Future<void> saveMaterialMetadata(MaterialModel material, {List<int>? fileBytes});
  
  Future<String> getDownloadUrl(String path);
}

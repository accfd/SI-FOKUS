import '../../data/models/learning_resource_model.dart';

abstract class ResourceRepository {
  /// Mengambil semua sumber belajar tambahan dari sebuah materi.
  Future<List<LearningResourceModel>> fetchResources(String materialId);

  /// Menambahkan sumber belajar baru ke sebuah materi.
  Future<void> addResource(String materialId, LearningResourceModel resource);

  /// Menghapus sumber belajar dari sebuah materi berdasarkan resourceId.
  Future<void> removeResource(String materialId, String resourceId);
}

import '../../../data/models/learning_resource_model.dart';

abstract class ResourceEvent {
  const ResourceEvent();
}

/// Memuat semua sumber belajar untuk sebuah materi.
class FetchResourcesByMaterial extends ResourceEvent {
  final String materialId;
  const FetchResourcesByMaterial(this.materialId);
}

/// Menambahkan sumber belajar baru ke materi.
class AddResourceToMaterial extends ResourceEvent {
  final String materialId;
  final LearningResourceModel resource;
  const AddResourceToMaterial({required this.materialId, required this.resource});
}

/// Menghapus sumber belajar dari materi.
class RemoveResource extends ResourceEvent {
  final String materialId;
  final String resourceId;
  const RemoveResource({required this.materialId, required this.resourceId});
}

import '../../../data/models/material_model.dart';

abstract class MaterialEvent {
  const MaterialEvent();
}

class UploadMaterial extends MaterialEvent {
  final String classId;
  final String title;
  final String fileName;
  final List<int> fileBytes;
  final String fileType; // 'pdf' | 'docx' | 'pptx'

  const UploadMaterial({
    required this.classId,
    required this.title,
    required this.fileName,
    required this.fileBytes,
    required this.fileType,
  });
}

class FetchClassMaterials extends MaterialEvent {
  final String classId;

  const FetchClassMaterials(this.classId);
}

class UpdateMaterialPublishStatus extends MaterialEvent {
  final String materialId;
  final bool isPublished;
  final String classId; // To refetch after update

  const UpdateMaterialPublishStatus({
    required this.materialId,
    required this.isPublished,
    required this.classId,
  });
}

class UploadProgressUpdated extends MaterialEvent {
  final double progress;

  const UploadProgressUpdated(this.progress);
}

class UploadFinished extends MaterialEvent {
  final MaterialModel material;

  const UploadFinished(this.material);
}

class UploadFailed extends MaterialEvent {
  final String message;

  const UploadFailed(this.message);
}

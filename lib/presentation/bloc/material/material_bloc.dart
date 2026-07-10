import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/repositories/material_repository.dart';
import '../../../data/models/material_model.dart';
import 'material_event.dart';
import 'material_state.dart';

class MaterialBloc extends Bloc<MaterialEvent, MaterialBlocState> {
  final MaterialRepository materialRepository;
  StreamSubscription<double>? _uploadSubscription;

  MaterialBloc({required this.materialRepository}) : super(const MaterialInitial()) {
    on<UploadMaterial>(_onUploadMaterial);
    on<FetchClassMaterials>(_onFetchClassMaterials);
    on<UpdateMaterialPublishStatus>(_onUpdateMaterialPublishStatus);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
    on<UploadFinished>(_onUploadFinished);
    on<UploadFailed>(_onUploadFailed);
  }

  Future<void> _onUploadMaterial(
    UploadMaterial event,
    Emitter<MaterialBlocState> emit,
  ) async {
    emit(const MaterialUploadProgress(0.0));
    await _uploadSubscription?.cancel();

    final materialId = const Uuid().v4();

    _uploadSubscription = materialRepository.uploadMaterialFile(
      materialId: materialId,
      classId: event.classId,
      fileName: event.fileName,
      fileBytes: event.fileBytes,
    ).listen(
      (progress) {
        add(UploadProgressUpdated(progress));
      },
      onError: (error) {
        add(UploadFailed(error.toString()));
      },
      onDone: () async {
        try {
          final storagePath = 'materials/${event.classId}/$materialId/${event.fileName}';
          final fileUrl = await materialRepository.getDownloadUrl(storagePath);
          
          final material = MaterialModel(
            materialId: materialId,
            classId: event.classId,
            title: event.title,
            fileUrl: fileUrl,
            fileType: event.fileType,
            createdAt: DateTime.now(),
            isPublished: false,
          );

          await materialRepository.saveMaterialMetadata(material, fileBytes: event.fileBytes);
          add(UploadFinished(material));
        } catch (e) {
          add(UploadFailed(e.toString()));
        }
      },
    );
  }

  void _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<MaterialBlocState> emit,
  ) {
    emit(MaterialUploadProgress(event.progress));
  }

  void _onUploadFinished(
    UploadFinished event,
    Emitter<MaterialBlocState> emit,
  ) {
    emit(MaterialUploadSuccess(event.material));
    add(FetchClassMaterials(event.material.classId));
  }

  void _onUploadFailed(
    UploadFailed event,
    Emitter<MaterialBlocState> emit,
  ) {
    emit(MaterialError(event.message));
  }

  Future<void> _onFetchClassMaterials(
    FetchClassMaterials event,
    Emitter<MaterialBlocState> emit,
  ) async {
    emit(const MaterialLoading());
    try {
      final materials = await materialRepository.fetchClassMaterials(event.classId);
      emit(MaterialsLoaded(materials));
    } catch (e) {
      emit(MaterialError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateMaterialPublishStatus(
    UpdateMaterialPublishStatus event,
    Emitter<MaterialBlocState> emit,
  ) async {
    try {
      await materialRepository.updateMaterialPublishStatus(event.materialId, event.isPublished);
      add(FetchClassMaterials(event.classId));
    } catch (e) {
      emit(MaterialError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  @override
  Future<void> close() {
    _uploadSubscription?.cancel();
    return super.close();
  }
}

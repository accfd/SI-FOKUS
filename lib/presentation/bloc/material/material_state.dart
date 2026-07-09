import '../../../data/models/material_model.dart';

abstract class MaterialBlocState {
  const MaterialBlocState();
}

class MaterialInitial extends MaterialBlocState {
  const MaterialInitial();
}

class MaterialLoading extends MaterialBlocState {
  const MaterialLoading();
}

class MaterialUploadProgress extends MaterialBlocState {
  final double progress;

  const MaterialUploadProgress(this.progress);
}

class MaterialUploadSuccess extends MaterialBlocState {
  final MaterialModel material;

  const MaterialUploadSuccess(this.material);
}

class MaterialsLoaded extends MaterialBlocState {
  final List<MaterialModel> materials;

  const MaterialsLoaded(this.materials);
}

class MaterialError extends MaterialBlocState {
  final String message;

  const MaterialError(this.message);
}

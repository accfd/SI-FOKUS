import '../../../data/models/learning_resource_model.dart';

abstract class ResourceState {
  const ResourceState();
}

class ResourceInitial extends ResourceState {
  const ResourceInitial();
}

class ResourceLoading extends ResourceState {
  const ResourceLoading();
}

class ResourceLoaded extends ResourceState {
  final List<LearningResourceModel> resources;
  const ResourceLoaded(this.resources);
}

/// State sementara setelah operasi add/remove berhasil.
/// UI mendengarkan ini untuk menampilkan snackbar, lalu memuat ulang data.
class ResourceActionSuccess extends ResourceState {
  final String message;
  const ResourceActionSuccess(this.message);
}

class ResourceError extends ResourceState {
  final String message;
  const ResourceError(this.message);
}

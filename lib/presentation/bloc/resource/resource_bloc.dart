import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/resource_repository.dart';
import 'resource_event.dart';
import 'resource_state.dart';

class ResourceBloc extends Bloc<ResourceEvent, ResourceState> {
  final ResourceRepository resourceRepository;

  ResourceBloc({required this.resourceRepository}) : super(const ResourceInitial()) {
    on<FetchResourcesByMaterial>(_onFetchResources);
    on<AddResourceToMaterial>(_onAddResource);
    on<RemoveResource>(_onRemoveResource);
  }

  Future<void> _onFetchResources(
    FetchResourcesByMaterial event,
    Emitter<ResourceState> emit,
  ) async {
    emit(const ResourceLoading());
    try {
      final resources = await resourceRepository.fetchResources(event.materialId);
      emit(ResourceLoaded(resources));
    } catch (e) {
      emit(ResourceError('Gagal memuat sumber belajar: $e'));
    }
  }

  Future<void> _onAddResource(
    AddResourceToMaterial event,
    Emitter<ResourceState> emit,
  ) async {
    emit(const ResourceLoading());
    try {
      await resourceRepository.addResource(event.materialId, event.resource);
      emit(const ResourceActionSuccess('Sumber belajar berhasil ditambahkan!'));
      // Muat ulang data setelah berhasil menambahkan
      final resources = await resourceRepository.fetchResources(event.materialId);
      emit(ResourceLoaded(resources));
    } catch (e) {
      emit(ResourceError('Gagal menambahkan sumber belajar: $e'));
    }
  }

  Future<void> _onRemoveResource(
    RemoveResource event,
    Emitter<ResourceState> emit,
  ) async {
    emit(const ResourceLoading());
    try {
      await resourceRepository.removeResource(event.materialId, event.resourceId);
      emit(const ResourceActionSuccess('Sumber belajar berhasil dihapus.'));
      // Muat ulang data setelah berhasil menghapus
      final resources = await resourceRepository.fetchResources(event.materialId);
      emit(ResourceLoaded(resources));
    } catch (e) {
      emit(ResourceError('Gagal menghapus sumber belajar: $e'));
    }
  }
}

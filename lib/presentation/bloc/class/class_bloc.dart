import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/class_repository.dart';
import 'class_event.dart';
import 'class_state.dart';

class ClassBloc extends Bloc<ClassEvent, ClassState> {
  final ClassRepository classRepository;

  ClassBloc({required this.classRepository}) : super(const ClassInitial()) {
    on<FetchTeacherClasses>(_onFetchTeacherClasses);
    on<CreateClass>(_onCreateClass);
    on<DeleteClass>(_onDeleteClass);
  }

  Future<void> _onFetchTeacherClasses(
    FetchTeacherClasses event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final classes = await classRepository.fetchTeacherClasses(event.teacherId);
      emit(TeacherClassesLoaded(classes));
    } catch (e) {
      emit(ClassError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateClass(
    CreateClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      final newClass = await classRepository.createClass(
        className: event.className,
        subjectName: event.subjectName,
        teacherId: event.teacherId,
      );
      emit(ClassSuccess('Kelas ${newClass.className} berhasil dibuat.', createdClass: newClass));
      add(FetchTeacherClasses(event.teacherId));
    } catch (e) {
      emit(ClassError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteClass(
    DeleteClass event,
    Emitter<ClassState> emit,
  ) async {
    emit(const ClassLoading());
    try {
      await classRepository.deleteClass(event.classId);
      emit(const ClassSuccess('Kelas berhasil dihapus.'));
      add(FetchTeacherClasses(event.teacherId));
    } catch (e) {
      emit(ClassError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

import '../../../data/models/class_model.dart';

abstract class ClassState {
  const ClassState();
}

class ClassInitial extends ClassState {
  const ClassInitial();
}

class ClassLoading extends ClassState {
  const ClassLoading();
}

class ClassSuccess extends ClassState {
  final String message;
  final ClassModel? createdClass;

  const ClassSuccess(this.message, {this.createdClass});
}

class ClassError extends ClassState {
  final String message;

  const ClassError(this.message);
}

class TeacherClassesLoaded extends ClassState {
  final List<ClassModel> classes;

  const TeacherClassesLoaded(this.classes);
}

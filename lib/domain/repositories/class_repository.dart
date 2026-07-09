import '../../data/models/class_model.dart';
import '../../data/models/user_model.dart';

abstract class ClassRepository {
  Future<List<ClassModel>> fetchTeacherClasses(String teacherId);
  
  Future<ClassModel> createClass({
    required String className,
    required String subjectName,
    required String teacherId,
  });

  Future<void> deleteClass(String classId);

  Stream<List<UserModel>> streamClassStudents(List<String> studentUids);
  
  Stream<ClassModel> streamClassDetail(String classId);
}

abstract class ClassEvent {
  const ClassEvent();
}

class FetchTeacherClasses extends ClassEvent {
  final String teacherId;

  const FetchTeacherClasses(this.teacherId);
}

class CreateClass extends ClassEvent {
  final String className;
  final String subjectName;
  final String teacherId;

  const CreateClass({
    required this.className,
    required this.subjectName,
    required this.teacherId,
  });
}

class DeleteClass extends ClassEvent {
  final String classId;
  final String teacherId; // To refetch lists after deletion

  const DeleteClass({
    required this.classId,
    required this.teacherId,
  });
}

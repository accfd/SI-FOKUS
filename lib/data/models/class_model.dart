class ClassModel {
  final String classId;
  final String className;
  final String classCode; // 8-character unique alphanumeric code
  final String subjectName;
  final String teacherId;
  final List<String> studentUids;

  ClassModel({
    required this.classId,
    required this.className,
    required this.classCode,
    required this.subjectName,
    required this.teacherId,
    this.studentUids = const [],
  });

  ClassModel copyWith({
    String? classId,
    String? className,
    String? classCode,
    String? subjectName,
    String? teacherId,
    List<String>? studentUids,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      classCode: classCode ?? this.classCode,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      studentUids: studentUids ?? this.studentUids,
    );
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      classCode: json['classCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
      studentUids: (json['studentUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'classCode': classCode,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'studentUids': studentUids,
    };
  }
}

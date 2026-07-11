import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/class_repository.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true;
  }
}

class ClassRepositoryImpl implements ClassRepository {
  final FirebaseFirestore? _firestore;
  final _uuid = const Uuid();

  ClassRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Future<List<ClassModel>> fetchTeacherClasses(String teacherId) async {
    if (isMockMode) {
      final allClasses = await MockDb.getAll('classes');
      return allClasses
          .where((c) => c['teacherId'] == teacherId)
          .map((c) => ClassModel.fromJson(c))
          .toList();
    }

    final query = await _firestore!
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    return query.docs.map((doc) => ClassModel.fromJson(doc.data())).toList();
  }

  @override
  Future<ClassModel> createClass({
    required String className,
    required String subjectName,
    required String teacherId,
  }) async {
    final classId = _uuid.v4();
    final classCode = await _generateUniqueClassCode(subjectName);

    final classModel = ClassModel(
      classId: classId,
      className: className.trim(),
      classCode: classCode,
      subjectName: subjectName.trim(),
      teacherId: teacherId,
      studentUids: const [],
    );

    if (isMockMode) {
      await MockDb.save('classes', classId, classModel.toJson());
      return classModel;
    }

    await _firestore!.collection('classes').doc(classId).set(classModel.toJson());
    return classModel;
  }

  @override
  Future<void> deleteClass(String classId) async {
    if (isMockMode) {
      await MockDb.delete('classes', classId);
      return;
    }
    await _firestore!.collection('classes').doc(classId).delete();
  }

  @override
  Stream<List<UserModel>> streamClassStudents(List<String> studentUids) {
    if (isMockMode) {
      if (studentUids.isEmpty) {
        return Stream.value([]);
      }
      
      final controller = StreamController<List<UserModel>>();
      
      // Fetch and emit immediately to prevent UI spinner hang
      Future.microtask(() async {
        try {
          final allUsers = await MockDb.getAll('users');
          final enrolled = allUsers
              .where((u) => studentUids.contains(u['uid']))
              .map((u) => UserModel.fromJson(u))
              .toList();
          if (!controller.isClosed) {
            controller.add(enrolled);
          }
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      });
      
      // Periodic updates every 2 seconds
      final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final allUsers = await MockDb.getAll('users');
          final enrolled = allUsers
              .where((u) => studentUids.contains(u['uid']))
              .map((u) => UserModel.fromJson(u))
              .toList();
          if (!controller.isClosed) {
            controller.add(enrolled);
          }
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      });
      
      controller.onCancel = () {
        timer.cancel();
        controller.close();
      };
      
      return controller.stream;
    }

    if (studentUids.isEmpty) {
      return Stream.value([]);
    }

    final queryList = studentUids.length > 30 
        ? studentUids.sublist(0, 30) 
        : studentUids;

    return _firestore!
        .collection('users')
        .where('uid', whereIn: queryList)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
        });
  }

  @override
  Stream<ClassModel> streamClassDetail(String classId) {
    if (isMockMode) {
      return (() async* {
        while (true) {
          final classData = await MockDb.get('classes', classId);
          if (classData == null) {
            throw Exception('Kelas tidak ditemukan.');
          }
          yield ClassModel.fromJson(classData);
          await Future.delayed(const Duration(seconds: 2));
        }
      })();
    }

    return _firestore!
        .collection('classes')
        .doc(classId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            throw Exception('Kelas tidak ditemukan.');
          }
          return ClassModel.fromJson(doc.data()!);
        });
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  Future<String> _generateUniqueClassCode(String subjectName) async {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    
    String prefix = subjectName.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    if (prefix.length > 4) {
      prefix = prefix.substring(0, 4);
    } else if (prefix.isEmpty) {
      prefix = 'SIFK';
    }

    bool isUnique = false;
    String code = '';

    while (!isUnique) {
      final neededLength = 8 - prefix.length;
      final suffix = List.generate(neededLength, (index) => chars[random.nextInt(chars.length)]).join();
      code = '$prefix$suffix';

      if (isMockMode) {
        final allClasses = await MockDb.getAll('classes');
        final duplicate = allClasses.any((c) => c['classCode'] == code);
        if (!duplicate) {
          isUnique = true;
        }
      } else {
        final checkQuery = await _firestore!
            .collection('classes')
            .where('classCode', isEqualTo: code)
            .limit(1)
            .get();

        if (checkQuery.docs.isEmpty) {
          isUnique = true;
        }
      }
    }

    return code;
  }
}

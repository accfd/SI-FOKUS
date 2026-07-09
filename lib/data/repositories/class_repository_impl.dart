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
      
      // Tambahkan siswa tiruan/mock ke kelas secara default jika berjalan lokal agar guru langsung melihat siswa terdaftar!
      // Ini penting agar F-05, F-06, F-07 dapat langsung berjalan dan diuji.
      final mockStudents = [
        UserModel(
          uid: 'std_rem_1',
          name: 'Aditya Pratama',
          email: 'aditya@siswa.com',
          role: 'siswa',
          parentAccessCode: 'ADTYA1',
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'std_rem_2',
          name: 'Budi Santoso',
          email: 'budi@siswa.com',
          role: 'siswa',
          parentAccessCode: 'BUDI02',
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'std_rem_3',
          name: 'Citra Lestari',
          email: 'citra@siswa.com',
          role: 'siswa',
          parentAccessCode: 'CITRA3',
          createdAt: DateTime.now(),
        ),
        UserModel(
          uid: 'std_rem_4',
          name: 'Dewi Handayani',
          email: 'dewi@siswa.com',
          role: 'siswa',
          parentAccessCode: 'DEWI04',
          createdAt: DateTime.now(),
        ),
      ];

      for (final student in mockStudents) {
        await MockDb.save('users', student.uid, student.toJson());
      }

      // Tambahkan UID siswa mock ke kelas
      final updatedClassModel = ClassModel(
        classId: classId,
        className: className.trim(),
        classCode: classCode,
        subjectName: subjectName.trim(),
        teacherId: teacherId,
        studentUids: mockStudents.map((e) => e.uid).toList(),
      );

      await MockDb.save('classes', classId, updatedClassModel.toJson());
      return updatedClassModel;
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
      // Pemantauan berkala local mock database untuk kelancaran UI
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        final allUsers = await MockDb.getAll('users');
        return allUsers
            .where((u) => studentUids.contains(u['uid']))
            .map((u) => UserModel.fromJson(u))
            .toList();
      });
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
      return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        final classData = await MockDb.get('classes', classId);
        if (classData == null) {
          throw Exception('Kelas tidak ditemukan.');
        }
        return ClassModel.fromJson(classData);
      });
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

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'mock_db.dart';

bool get isMockMode {
  try {
    return Firebase.app().options.apiKey == "AIzaSyDummyKeyForLocalWebTestingOnly";
  } catch (_) {
    return true; // Default ke mock mode jika Firebase belum terinisialisasi
  }
}

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  final _mockAuthStreamController = StreamController<UserModel?>.broadcast();

  AuthRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = isMockMode ? null : (firebaseAuth ?? firebase_auth.FirebaseAuth.instance),
        _firestore = isMockMode ? null : (firestore ?? FirebaseFirestore.instance);

  @override
  Stream<UserModel?> get onAuthStateChanged {
    if (isMockMode) {
      final controller = StreamController<UserModel?>.broadcast();
      
      // Ambil status login awal dari SharedPreferences
      _getInitialMockUser().then((user) {
        if (!controller.isClosed) {
          controller.add(user);
        }
      });

      // Hubungkan ke stream perubahan login lokal
      final subscription = _mockAuthStreamController.stream.listen((user) {
        if (!controller.isClosed) {
          controller.add(user);
        }
      });

      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };

      return controller.stream;
    }

    return _firebaseAuth!.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _getUserFromFirestore(firebaseUser.uid);
    });
  }

  Future<UserModel?> _getInitialMockUser() async {
    try {
      final currentUid = await MockDb.getString('current_user_uid');
      if (currentUid == null) return null;
      final userData = await MockDb.get('users', currentUid);
      if (userData == null) return null;
      return UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Error loading initial mock user: $e');
      return null;
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? parentAccessCode,
  }) async {
    String? finalParentAccessCode;
    String? linkedStudentUid;

    // 1. Logika Khusus Siswa
    if (role == 'siswa') {
      finalParentAccessCode = await _generateUniqueAccessCode();
    }

    // 2. Logika Khusus Orang Tua
    if (role == 'orang_tua') {
      if (parentAccessCode == null || parentAccessCode.trim().isEmpty) {
        throw Exception('Kode akses orang tua (Parent Access Code) wajib diisi.');
      }

      if (isMockMode) {
        var allUsers = await MockDb.getAll('users');
        final codeUpper = parentAccessCode.trim().toUpperCase();
        
        // Data siswa bawaan (default mock students)
        final codeToMockStudent = {
          'ADTYA1': UserModel(
            uid: 'std_rem_1',
            name: 'Aditya Pratama',
            email: 'aditya@siswa.com',
            role: 'siswa',
            parentAccessCode: 'ADTYA1',
            createdAt: DateTime.now(),
          ),
          'BUDI02': UserModel(
            uid: 'std_rem_2',
            name: 'Budi Santoso',
            email: 'budi@siswa.com',
            role: 'siswa',
            parentAccessCode: 'BUDI02',
            createdAt: DateTime.now(),
          ),
          'CITRA3': UserModel(
            uid: 'std_rem_3',
            name: 'Citra Lestari',
            email: 'citra@siswa.com',
            role: 'siswa',
            parentAccessCode: 'CITRA3',
            createdAt: DateTime.now(),
          ),
          'DEWI04': UserModel(
            uid: 'std_rem_4',
            name: 'Dewi Handayani',
            email: 'dewi@siswa.com',
            role: 'siswa',
            parentAccessCode: 'DEWI04',
            createdAt: DateTime.now(),
          ),
        };

        // Jika siswa belum ada di database lokal namun menggunakan salah satu kode bawaan,
        // daftarkan secara otomatis agar orang tua dapat mendaftar tanpa hambatan
        final hasMatch = allUsers.any((u) => u['role'] == 'siswa' && u['parentAccessCode'] == codeUpper);
        if (!hasMatch && codeToMockStudent.containsKey(codeUpper)) {
          final student = codeToMockStudent[codeUpper]!;
          await MockDb.save('users', student.uid, student.toJson());
          allUsers = await MockDb.getAll('users'); // refresh daftar user
        }

        final student = allUsers.firstWhere(
          (u) => u['role'] == 'siswa' && u['parentAccessCode'] == codeUpper,
          orElse: () => throw Exception('Kode akses tidak valid. Siswa tidak ditemukan.'),
        );
        linkedStudentUid = student['uid'] as String;
      } else {
        final studentQuery = await _firestore!
            .collection('users')
            .where('role', isEqualTo: 'siswa')
            .where('parentAccessCode', isEqualTo: parentAccessCode.trim().toUpperCase())
            .limit(1)
            .get();

        if (studentQuery.docs.isEmpty) {
          throw Exception('Kode akses tidak valid. Siswa tidak ditemukan.');
        }

        linkedStudentUid = studentQuery.docs.first.id;
      }
    }

    if (isMockMode) {
      // Simulasikan pendaftaran lokal
      final uid = 'mock_uid_${email.trim().toLowerCase().hashCode}';
      
      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        parentAccessCode: finalParentAccessCode,
        linkedStudentUid: linkedStudentUid,
        createdAt: DateTime.now(),
      );

      await MockDb.save('users', uid, userModel.toJson());
      await MockDb.setString('current_user_uid', uid);
      _mockAuthStreamController.add(userModel);

      return userModel;
    }

    // Pendaftaran Firebase asli
    final userCredential = await _firebaseAuth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = userCredential.user!.uid;

    final userModel = UserModel(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      parentAccessCode: finalParentAccessCode,
      linkedStudentUid: linkedStudentUid,
      createdAt: DateTime.now(),
    );

    await _firestore!.collection('users').doc(uid).set(userModel.toFirestore());
    return userModel;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (isMockMode) {
      final allUsers = await MockDb.getAll('users');
      final matched = allUsers.firstWhere(
        (u) => u['email'] == email.trim().toLowerCase(),
        orElse: () => throw Exception('Email atau password salah (Local Mock).'),
      );

      final userModel = UserModel.fromJson(matched);
      await MockDb.setString('current_user_uid', userModel.uid);
      _mockAuthStreamController.add(userModel);

      return userModel;
    }

    final userCredential = await _firebaseAuth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = userCredential.user!.uid;
    final userModel = await _getUserFromFirestore(uid);
    
    if (userModel == null) {
      throw Exception('Data profil pengguna tidak ditemukan di server.');
    }

    return userModel;
  }

  @override
  Future<void> logout() async {
    if (isMockMode) {
      await MockDb.remove('current_user_uid');
      _mockAuthStreamController.add(null);
      return;
    }
    await _firebaseAuth!.signOut();
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    if (isMockMode) {
      return await _getInitialMockUser();
    }
    final firebaseUser = _firebaseAuth!.currentUser;
    if (firebaseUser == null) return null;
    return await _getUserFromFirestore(firebaseUser.uid);
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting user from firestore: $e');
    }
    return null;
  }

  Future<String> _generateUniqueAccessCode() async {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    bool isUnique = false;
    String code = '';

    while (!isUnique) {
      code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
      
      if (isMockMode) {
        final allUsers = await MockDb.getAll('users');
        final duplicate = allUsers.any((u) => u['parentAccessCode'] == code);
        if (!duplicate) {
          isUnique = true;
        }
      } else {
        final checkQuery = await _firestore!
            .collection('users')
            .where('parentAccessCode', isEqualTo: code)
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

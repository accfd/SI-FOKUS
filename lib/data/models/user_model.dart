import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'guru' | 'siswa' | 'orang_tua'
  final String? parentAccessCode; // optional for siswa
  final String? linkedStudentUid; // optional for orang_tua
  final int xp;
  final int level;
  final List<String> unlockedBadges;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.parentAccessCode,
    this.linkedStudentUid,
    this.xp = 0,
    this.level = 1,
    this.unlockedBadges = const [],
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? parentAccessCode,
    String? linkedStudentUid,
    int? xp,
    int? level,
    List<String>? unlockedBadges,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      parentAccessCode: parentAccessCode ?? this.parentAccessCode,
      linkedStudentUid: linkedStudentUid ?? this.linkedStudentUid,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.parse(json['createdAt'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'siswa',
      parentAccessCode: json['parentAccessCode'] as String?,
      linkedStudentUid: json['linkedStudentUid'] as String?,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      unlockedBadges: (json['unlockedBadges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'parentAccessCode': parentAccessCode,
      'linkedStudentUid': linkedStudentUid,
      'xp': xp,
      'level': level,
      'unlockedBadges': unlockedBadges,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'parentAccessCode': parentAccessCode,
      'linkedStudentUid': linkedStudentUid,
      'xp': xp,
      'level': level,
      'unlockedBadges': unlockedBadges,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

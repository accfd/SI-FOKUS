import 'package:cloud_firestore/cloud_firestore.dart';
import 'learning_resource_model.dart';

class MaterialModel {
  final String materialId;
  final String classId;
  final String title;
  final String fileUrl;
  final String fileType; // 'pdf' | 'docx' | 'pptx'
  final String? summary; // diisi null awalnya oleh guru, diupdate oleh AI backend
  final DateTime createdAt;
  final bool isPublished;
  final List<LearningResourceModel> learningResources;
  final String? aiProcessingStatus; // 'pending' | 'processing' | 'done' | 'error'
  final List<String> topics; // Daftar topik utama yang dideteksi AI

  MaterialModel({
    required this.materialId,
    required this.classId,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    this.summary,
    required this.createdAt,
    this.isPublished = false,
    this.learningResources = const [],
    this.aiProcessingStatus,
    this.topics = const [],
  });

  MaterialModel copyWith({
    String? materialId,
    String? classId,
    String? title,
    String? fileUrl,
    String? fileType,
    String? summary,
    DateTime? createdAt,
    bool? isPublished,
    List<LearningResourceModel>? learningResources,
    String? aiProcessingStatus,
    List<String>? topics,
  }) {
    return MaterialModel(
      materialId: materialId ?? this.materialId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      learningResources: learningResources ?? this.learningResources,
      aiProcessingStatus: aiProcessingStatus ?? this.aiProcessingStatus,
      topics: topics ?? this.topics,
    );
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.parse(json['createdAt'] as String);
    } else {
      parsedDate = DateTime.now();
    }

    // Parse learningResources array
    final rawResources = json['learningResources'] as List<dynamic>? ?? [];
    final resources = rawResources
        .map((e) => LearningResourceModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse topics array
    final rawTopics = json['topics'] as List<dynamic>? ?? [];
    final topics = rawTopics.map((e) => e.toString()).toList();

    return MaterialModel(
      materialId: json['materialId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'pdf',
      summary: json['summary'] as String?,
      createdAt: parsedDate,
      isPublished: json['isPublished'] as bool? ?? false,
      learningResources: resources,
      aiProcessingStatus: json['aiProcessingStatus'] as String?,
      topics: topics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materialId': materialId,
      'classId': classId,
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
      'isPublished': isPublished,
      'learningResources': learningResources.map((e) => e.toJson()).toList(),
      'aiProcessingStatus': aiProcessingStatus,
      'topics': topics,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'materialId': materialId,
      'classId': classId,
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'summary': summary,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'learningResources': learningResources.map((e) => e.toJson()).toList(),
      'aiProcessingStatus': aiProcessingStatus,
      'topics': topics,
    };
  }
}

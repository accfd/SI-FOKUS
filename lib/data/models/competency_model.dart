class MistakeTopicModel {
  final String topic;
  final double errorRate;

  MistakeTopicModel({
    required this.topic,
    required this.errorRate,
  });

  factory MistakeTopicModel.fromJson(Map<String, dynamic> json) {
    return MistakeTopicModel(
      topic: json['topic'] as String? ?? '',
      errorRate: (json['errorRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'errorRate': errorRate,
    };
  }
}

class CompetencyModel {
  final String classId;
  final double averageScore;
  final List<MistakeTopicModel> highestMistakeTopics;
  final Map<String, double> competencyMastery;

  CompetencyModel({
    required this.classId,
    required this.averageScore,
    required this.highestMistakeTopics,
    required this.competencyMastery,
  });

  factory CompetencyModel.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['highestMistakeTopics'] as List<dynamic>? ?? const [];
    final topics = rawTopics.map((e) => MistakeTopicModel.fromJson(e as Map<String, dynamic>)).toList();
    
    final rawMastery = json['competencyMastery'] as Map<String, dynamic>? ?? const {};
    final competencyMastery = rawMastery.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return CompetencyModel(
      classId: json['classId'] as String? ?? '',
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      highestMistakeTopics: topics,
      competencyMastery: competencyMastery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'averageScore': averageScore,
      'highestMistakeTopics': highestMistakeTopics.map((e) => e.toJson()).toList(),
      'competencyMastery': competencyMastery,
    };
  }
}

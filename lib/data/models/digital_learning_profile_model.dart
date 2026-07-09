class FocusDataPoint {
  final DateTime date;
  final double focusScore;

  FocusDataPoint({required this.date, required this.focusScore});

  factory FocusDataPoint.fromJson(Map<String, dynamic> json) {
    return FocusDataPoint(
      date: DateTime.parse(json['date'] as String),
      focusScore: (json['focusScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'focusScore': focusScore,
    };
  }
}

class ConsistencyDataPoint {
  final String weekLabel;
  final double hoursStudied;

  ConsistencyDataPoint({required this.weekLabel, required this.hoursStudied});

  factory ConsistencyDataPoint.fromJson(Map<String, dynamic> json) {
    return ConsistencyDataPoint(
      weekLabel: json['weekLabel'] as String,
      hoursStudied: (json['hoursStudied'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekLabel': weekLabel,
      'hoursStudied': hoursStudied,
    };
  }
}

class DigitalLearningProfileModel {
  final String studentId;
  final List<FocusDataPoint> focusTrend;
  final List<ConsistencyDataPoint> consistencyTrend;
  final String strongestMaterial;
  final String weakestMaterial;
  final String mostEffectiveMedia;

  DigitalLearningProfileModel({
    required this.studentId,
    this.focusTrend = const [],
    this.consistencyTrend = const [],
    required this.strongestMaterial,
    required this.weakestMaterial,
    required this.mostEffectiveMedia,
  });

  factory DigitalLearningProfileModel.fromJson(Map<String, dynamic> json) {
    return DigitalLearningProfileModel(
      studentId: json['studentId'] as String? ?? '',
      focusTrend: (json['focusTrend'] as List<dynamic>?)
              ?.map((e) => FocusDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      consistencyTrend: (json['consistencyTrend'] as List<dynamic>?)
              ?.map((e) =>
                  ConsistencyDataPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      strongestMaterial: json['strongestMaterial'] as String? ?? '-',
      weakestMaterial: json['weakestMaterial'] as String? ?? '-',
      mostEffectiveMedia: json['mostEffectiveMedia'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'focusTrend': focusTrend.map((e) => e.toJson()).toList(),
      'consistencyTrend': consistencyTrend.map((e) => e.toJson()).toList(),
      'strongestMaterial': strongestMaterial,
      'weakestMaterial': weakestMaterial,
      'mostEffectiveMedia': mostEffectiveMedia,
    };
  }
}

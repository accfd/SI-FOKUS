class LearningResourceModel {
  final String resourceId;
  final String title;
  final String type; // 'youtube' | 'video_file' | 'link'
  final String url;

  LearningResourceModel({
    required this.resourceId,
    required this.title,
    required this.type,
    required this.url,
  });

  LearningResourceModel copyWith({
    String? resourceId,
    String? title,
    String? type,
    String? url,
  }) {
    return LearningResourceModel(
      resourceId: resourceId ?? this.resourceId,
      title: title ?? this.title,
      type: type ?? this.type,
      url: url ?? this.url,
    );
  }

  factory LearningResourceModel.fromJson(Map<String, dynamic> json) {
    return LearningResourceModel(
      resourceId: json['resourceId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'link',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resourceId': resourceId,
      'title': title,
      'type': type,
      'url': url,
    };
  }
}

/// Model representing a recently processed file
class RecentFile {
  final String path;
  final DateTime processedAt;

  RecentFile({
    required this.path,
    required this.processedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'processedAt': processedAt.toIso8601String(),
    };
  }

  factory RecentFile.fromJson(Map<String, dynamic> json) {
    return RecentFile(
      path: json['path'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
    );
  }
}

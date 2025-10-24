/// Settings for MKV file optimization
class OptimizationSettings {
  /// Whether to reorder streams by type (video, audio, subtitle)
  final bool reorderStreams;
  
  /// Whether to remove unnecessary metadata
  final bool removeMetadata;
  
  /// Whether to optimize header compression
  final bool optimizeHeader;
  
  /// Policy for stream reordering
  final StreamReorderPolicy reorderPolicy;

  const OptimizationSettings({
    this.reorderStreams = true,
    this.removeMetadata = false,
    this.optimizeHeader = true,
    this.reorderPolicy = StreamReorderPolicy.typeBasedDefault,
  });

  OptimizationSettings copyWith({
    bool? reorderStreams,
    bool? removeMetadata,
    bool? optimizeHeader,
    StreamReorderPolicy? reorderPolicy,
  }) {
    return OptimizationSettings(
      reorderStreams: reorderStreams ?? this.reorderStreams,
      removeMetadata: removeMetadata ?? this.removeMetadata,
      optimizeHeader: optimizeHeader ?? this.optimizeHeader,
      reorderPolicy: reorderPolicy ?? this.reorderPolicy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reorderStreams': reorderStreams,
      'removeMetadata': removeMetadata,
      'optimizeHeader': optimizeHeader,
      'reorderPolicy': reorderPolicy.name,
    };
  }

  factory OptimizationSettings.fromJson(Map<String, dynamic> json) {
    return OptimizationSettings(
      reorderStreams: json['reorderStreams'] as bool? ?? true,
      removeMetadata: json['removeMetadata'] as bool? ?? false,
      optimizeHeader: json['optimizeHeader'] as bool? ?? true,
      reorderPolicy: StreamReorderPolicy.values.firstWhere(
        (p) => p.name == json['reorderPolicy'],
        orElse: () => StreamReorderPolicy.typeBasedDefault,
      ),
    );
  }
}

/// Policy for reordering streams in MKV files
enum StreamReorderPolicy {
  /// Keep original order
  keepOriginal,
  
  /// Video → Audio → Subtitle (with default tracks first)
  typeBasedDefault,
  
  /// Video → Audio → Subtitle (all in original order within type)
  typeBasedOriginal,
}

extension StreamReorderPolicyExtension on StreamReorderPolicy {
  String get displayName {
    switch (this) {
      case StreamReorderPolicy.keepOriginal:
        return 'Keep Original Order';
      case StreamReorderPolicy.typeBasedDefault:
        return 'Type-Based (Default First)';
      case StreamReorderPolicy.typeBasedOriginal:
        return 'Type-Based (Original Order)';
    }
  }

  String get description {
    switch (this) {
      case StreamReorderPolicy.keepOriginal:
        return 'Maintains the original stream order';
      case StreamReorderPolicy.typeBasedDefault:
        return 'Groups by type with default tracks first: Video → Audio → Subtitle';
      case StreamReorderPolicy.typeBasedOriginal:
        return 'Groups by type maintaining original order within each type';
    }
  }
}

/// Result of an optimization operation
class OptimizationResult {
  /// Original file size in bytes
  final int originalSize;
  
  /// Optimized file size in bytes
  final int optimizedSize;
  
  /// Error message if optimization failed
  final String? error;
  
  /// Duration of optimization in milliseconds
  final int durationMs;

  const OptimizationResult({
    required this.originalSize,
    required this.optimizedSize,
    this.error,
    required this.durationMs,
  });

  /// Calculates size savings in bytes
  int get sizeSavings => originalSize - optimizedSize;

  /// Calculates size savings percentage
  double get savingsPercentage {
    if (originalSize == 0) return 0.0;
    return (sizeSavings / originalSize) * 100.0;
  }

  /// Whether optimization was successful
  bool get isSuccess => error == null;

  /// Formats size in human-readable format
  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  String get formattedOriginalSize => formatSize(originalSize);
  String get formattedOptimizedSize => formatSize(optimizedSize);
  String get formattedSizeSavings => formatSize(sizeSavings);
}

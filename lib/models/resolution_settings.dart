/// Represents resolution and framerate conversion settings.
class ResolutionSettings {
  /// Target width (null means keep original)
  final int? width;
  
  /// Target height (null means keep original)
  final int? height;
  
  /// Target framerate (null means keep original)
  final double? framerate;
  
  /// Preset name if using a preset
  final String? presetName;
  
  /// Whether resolution/framerate conversion is enabled
  final bool enabled;

  const ResolutionSettings({
    this.width,
    this.height,
    this.framerate,
    this.presetName,
    this.enabled = false,
  });

  /// Common resolution presets
  static const Map<String, ResolutionSettings> presets = {
    '4K (3840x2160)': ResolutionSettings(width: 3840, height: 2160, presetName: '4K', enabled: true),
    '1080p (1920x1080)': ResolutionSettings(width: 1920, height: 1080, presetName: '1080p', enabled: true),
    '720p (1280x720)': ResolutionSettings(width: 1280, height: 720, presetName: '720p', enabled: true),
    '480p (854x480)': ResolutionSettings(width: 854, height: 480, presetName: '480p', enabled: true),
    '360p (640x360)': ResolutionSettings(width: 640, height: 360, presetName: '360p', enabled: true),
  };

  /// Common framerate options
  static const List<double> framerateOptions = [
    23.976,
    24.0,
    25.0,
    29.97,
    30.0,
    50.0,
    59.94,
    60.0,
  ];

  /// Get FFmpeg scale filter string
  String? get scaleFilter {
    if (!enabled || (width == null && height == null)) return null;
    
    if (width != null && height != null) {
      return 'scale=$width:$height';
    } else if (width != null) {
      return 'scale=$width:-2'; // -2 maintains aspect ratio with even height
    } else if (height != null) {
      return 'scale=-2:$height'; // -2 maintains aspect ratio with even width
    }
    return null;
  }

  /// Estimate output file size based on resolution change
  /// Returns a multiplier for the original file size
  double estimateSizeMultiplier(int originalWidth, int originalHeight) {
    if (!enabled || (width == null && height == null)) return 1.0;
    
    final targetWidth = width ?? originalWidth;
    final targetHeight = height ?? originalHeight;
    final originalPixels = originalWidth * originalHeight;
    final targetPixels = targetWidth * targetHeight;
    
    // Rough estimate: size is proportional to pixel count
    // Apply a small overhead for encoding
    return (targetPixels / originalPixels) * 1.1;
  }

  ResolutionSettings copyWith({
    int? width,
    int? height,
    double? framerate,
    String? presetName,
    bool? enabled,
  }) {
    return ResolutionSettings(
      width: width ?? this.width,
      height: height ?? this.height,
      framerate: framerate ?? this.framerate,
      presetName: presetName ?? this.presetName,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'framerate': framerate,
      'presetName': presetName,
      'enabled': enabled,
    };
  }

  factory ResolutionSettings.fromJson(Map<String, dynamic> json) {
    return ResolutionSettings(
      width: json['width'] as int?,
      height: json['height'] as int?,
      framerate: json['framerate'] as double?,
      presetName: json['presetName'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    if (!enabled) return 'Resolution: Original';
    final parts = <String>[];
    if (width != null || height != null) {
      parts.add('${width ?? 'auto'}x${height ?? 'auto'}');
    }
    if (framerate != null) {
      parts.add('${framerate}fps');
    }
    if (presetName != null) {
      parts.add('($presetName)');
    }
    return parts.isEmpty ? 'Resolution: Custom' : 'Resolution: ${parts.join(' ')}';
  }
}

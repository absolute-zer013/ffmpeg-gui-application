import 'dart:io';

class EncoderInfo {
  final String mediaType; // 'V' (video), 'A' (audio), 'S' (subtitle)
  final String name; // ffmpeg encoder name
  final String description; // human-readable description

  EncoderInfo(this.mediaType, this.name, this.description);
}

/// Hardware acceleration capabilities detected on the system
class HardwareCapabilities {
  final bool hasNVENC; // NVIDIA NVENC
  final bool hasAMF; // AMD AMF
  final bool hasQSV; // Intel Quick Sync Video
  final List<String> availableHardwareEncoders;
  final DateTime detectedAt;

  HardwareCapabilities({
    required this.hasNVENC,
    required this.hasAMF,
    required this.hasQSV,
    required this.availableHardwareEncoders,
    required this.detectedAt,
  });

  bool get hasAnyHardwareAcceleration =>
      hasNVENC || hasAMF || hasQSV || availableHardwareEncoders.isNotEmpty;

  @override
  String toString() {
    final caps = <String>[];
    if (hasNVENC) caps.add('NVENC');
    if (hasAMF) caps.add('AMF');
    if (hasQSV) caps.add('QSV');
    return caps.isEmpty
        ? 'No hardware acceleration detected'
        : 'Hardware: ${caps.join(", ")}';
  }
}

class FFmpegCapabilitiesService {
  static final RegExp _line = RegExp(r'^\s*([VAS])\S*\s+(\S+)\s+(.*)$');

  static Future<List<EncoderInfo>> getEncoders() async {
    try {
      final proc = await Process.run('ffmpeg', ['-hide_banner', '-encoders']);
      if (proc.exitCode != 0) return [];
      final out = (proc.stdout as String).split('\n');
      final result = <EncoderInfo>[];
      bool inTable = false;
      for (final raw in out) {
        final line = raw.trimRight();
        if (line.startsWith('-------')) {
          inTable = true;
          continue;
        }
        if (!inTable) continue;
        final m = _line.firstMatch(line);
        if (m != null) {
          result.add(EncoderInfo(m.group(1)!, m.group(2)!, m.group(3)!.trim()));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  static Future<List<EncoderInfo>> getVideoEncoders() async {
    final all = await getEncoders();
    return all.where((e) => e.mediaType == 'V').toList();
  }

  static Future<List<EncoderInfo>> getAudioEncoders() async {
    final all = await getEncoders();
    return all.where((e) => e.mediaType == 'A').toList();
  }

  /// Detect available hardware encoders on the system
  static Future<HardwareCapabilities> detectHardwareCapabilities() async {
    final encoders = await getVideoEncoders();
    final encoderNames = encoders.map((e) => e.name.toLowerCase()).toSet();

    // Detect NVENC (NVIDIA)
    final hasNVENC = encoderNames.any((name) =>
        name.contains('nvenc') ||
        name.contains('h264_nvenc') ||
        name.contains('hevc_nvenc') ||
        name.contains('av1_nvenc'));

    // Detect AMF (AMD)
    final hasAMF = encoderNames.any((name) =>
        name.contains('amf') ||
        name.contains('h264_amf') ||
        name.contains('hevc_amf'));

    // Detect QSV (Intel Quick Sync)
    final hasQSV = encoderNames.any((name) =>
        name.contains('qsv') ||
        name.contains('h264_qsv') ||
        name.contains('hevc_qsv') ||
        name.contains('av1_qsv'));

    // Collect all hardware encoder names
    final hardwareEncoders = encoderNames
        .where((name) =>
            name.contains('nvenc') ||
            name.contains('amf') ||
            name.contains('qsv') ||
            name.contains('vaapi') ||
            name.contains('videotoolbox') ||
            name.contains('v4l2m2m'))
        .toList();

    return HardwareCapabilities(
      hasNVENC: hasNVENC,
      hasAMF: hasAMF,
      hasQSV: hasQSV,
      availableHardwareEncoders: hardwareEncoders,
      detectedAt: DateTime.now(),
    );
  }

  /// Select best hardware encoder for a given codec, or null if none available
  /// Priority order: NVENC > AMF > QSV
  static String? selectHardwareEncoder(
    String softwareCodec,
    HardwareCapabilities capabilities,
  ) {
    final codecLower = softwareCodec.toLowerCase();

    // Map software codec to hardware encoders in priority order
    final Map<String, List<String>> codecToHardwareEncoders = {
      'libx264': [
        'h264_nvenc', // NVIDIA
        'h264_amf', // AMD
        'h264_qsv', // Intel
      ],
      'libx265': [
        'hevc_nvenc', // NVIDIA
        'hevc_amf', // AMD
        'hevc_qsv', // Intel
      ],
      'libaom-av1': [
        'av1_nvenc', // NVIDIA (RTX 40 series+)
        'av1_qsv', // Intel (Arc+)
      ],
    };

    final candidates = codecToHardwareEncoders[codecLower];
    if (candidates == null) return null;

    // Return first available candidate
    for (final candidate in candidates) {
      if (capabilities.availableHardwareEncoders.contains(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  /// Check if a specific encoder is compatible with a container format
  static bool isEncoderCompatibleWithContainer(
      String encoder, String containerExt) {
    final ext = containerExt.toLowerCase().replaceAll('.', '');
    final enc = encoder.toLowerCase();

    // MP4/M4V/MOV compatibility
    if (['mp4', 'm4v', 'mov'].contains(ext)) {
      // MP4 supports H.264, H.265, AV1 hardware encoders
      return enc.contains('h264') || enc.contains('hevc') || enc.contains('av1');
    }

    // MKV compatibility - supports almost everything
    if (ext == 'mkv') {
      return true;
    }

    // WebM compatibility
    if (ext == 'webm') {
      // WebM primarily supports VP8, VP9, AV1
      return enc.contains('vp8') || enc.contains('vp9') || enc.contains('av1');
    }

    // Default: assume compatible
    return true;
  }
}

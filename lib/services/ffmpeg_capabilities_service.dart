import 'dart:io';

class EncoderInfo {
  final String mediaType; // 'V' (video), 'A' (audio), 'S' (subtitle)
  final String name; // ffmpeg encoder name
  final String description; // human-readable description

  EncoderInfo(this.mediaType, this.name, this.description);
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
}

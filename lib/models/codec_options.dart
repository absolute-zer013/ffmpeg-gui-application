/// Enum for video codecs
enum VideoCodec {
  copy('Copy', 'copy', 'No re-encoding (fast)'),
  h264('H.264', 'libx264', 'High compatibility, good quality'),
  h265('H.265/HEVC', 'libx265', 'Better compression, slower encoding'),
  vp9('VP9', 'libvpx-vp9', 'Open format, good for web'),
  av1('AV1', 'libaom-av1', 'Best compression, very slow');

  final String displayName;
  final String ffmpegName;
  final String description;

  const VideoCodec(this.displayName, this.ffmpegName, this.description);
}

/// Enum for audio codecs
enum AudioCodec {
  copy('Copy', 'copy', 'No re-encoding (fast)'),
  aac('AAC', 'aac', 'High compatibility, good quality'),
  mp3('MP3', 'libmp3lame', 'Universal compatibility'),
  opus('Opus', 'libopus', 'Best quality per bitrate'),
  ac3('AC3', 'ac3', 'Common for multi-channel audio'),
  flac('FLAC', 'flac', 'Lossless compression'),
  vorbis('Vorbis', 'libvorbis', 'Open format, good quality');

  final String displayName;
  final String ffmpegName;
  final String description;

  const AudioCodec(this.displayName, this.ffmpegName, this.description);
}

/// Codec conversion settings for a specific track
class CodecConversionSettings {
  final VideoCodec? videoCodec;
  final AudioCodec? audioCodec;
  final int? audioBitrate; // in kbps
  final int? audioChannels; // e.g., 2 for stereo, 6 for 5.1
  final int? audioSampleRate; // in Hz, e.g., 48000

  CodecConversionSettings({
    this.videoCodec,
    this.audioCodec,
    this.audioBitrate,
    this.audioChannels,
    this.audioSampleRate,
  });

  CodecConversionSettings copyWith({
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    int? audioBitrate,
    int? audioChannels,
    int? audioSampleRate,
  }) {
    return CodecConversionSettings(
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioChannels: audioChannels ?? this.audioChannels,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec?.name,
      'audioCodec': audioCodec?.name,
      'audioBitrate': audioBitrate,
      'audioChannels': audioChannels,
      'audioSampleRate': audioSampleRate,
    };
  }

  factory CodecConversionSettings.fromJson(Map<String, dynamic> json) {
    return CodecConversionSettings(
      videoCodec: json['videoCodec'] != null
          ? VideoCodec.values.firstWhere((e) => e.name == json['videoCodec'])
          : null,
      audioCodec: json['audioCodec'] != null
          ? AudioCodec.values.firstWhere((e) => e.name == json['audioCodec'])
          : null,
      audioBitrate: json['audioBitrate'] as int?,
      audioChannels: json['audioChannels'] as int?,
      audioSampleRate: json['audioSampleRate'] as int?,
    );
  }
}

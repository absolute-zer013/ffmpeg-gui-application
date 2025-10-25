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

/// Enum for subtitle formats
enum SubtitleFormat {
  copy('Copy', 'copy', 'No conversion (fast)'),
  srt('SRT', 'srt', 'SubRip text format (universal)'),
  ass('ASS', 'ass', 'Advanced SubStation Alpha (styling)'),
  ssa('SSA', 'ssa', 'SubStation Alpha'),
  webvtt('WebVTT', 'webvtt', 'Web Video Text Tracks'),
  movText('MOV Text', 'mov_text', 'MP4 subtitle format'),
  subrip('SubRip', 'subrip', 'SubRip format (alternative)');

  final String displayName;
  final String ffmpegName;
  final String description;

  const SubtitleFormat(this.displayName, this.ffmpegName, this.description);
}

/// Codec conversion settings for a specific track
class CodecConversionSettings {
  final VideoCodec? videoCodec;
  final AudioCodec? audioCodec;
  final SubtitleFormat? subtitleFormat;
  // Video params
  final int? videoCrf; // for constant quality
  final String? videoPreset; // encoder preset string
  final int? videoBitrateKbps; // set to 0 for CQ in AV1 (-b:v 0)
  final int? audioBitrate; // in kbps
  final int? audioChannels; // e.g., 2 for stereo, 6 for 5.1
  final int? audioSampleRate; // in Hz, e.g., 48000
  // Advanced: allow using any ffmpeg codec name directly
  final String? customVideoCodec; // e.g., 'libsvtav1', 'mpeg4'
  final String? customAudioCodec; // e.g., 'libfdk_aac', 'pcm_s16le'

  CodecConversionSettings({
    this.videoCodec,
    this.audioCodec,
    this.subtitleFormat,
    this.videoCrf,
    this.videoPreset,
    this.videoBitrateKbps,
    this.audioBitrate,
    this.audioChannels,
    this.audioSampleRate,
    this.customVideoCodec,
    this.customAudioCodec,
  });

  CodecConversionSettings copyWith({
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    SubtitleFormat? subtitleFormat,
    int? videoCrf,
    String? videoPreset,
    int? videoBitrateKbps,
    int? audioBitrate,
    int? audioChannels,
    int? audioSampleRate,
    String? customVideoCodec,
    String? customAudioCodec,
  }) {
    return CodecConversionSettings(
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      subtitleFormat: subtitleFormat ?? this.subtitleFormat,
      videoCrf: videoCrf ?? this.videoCrf,
      videoPreset: videoPreset ?? this.videoPreset,
      videoBitrateKbps: videoBitrateKbps ?? this.videoBitrateKbps,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioChannels: audioChannels ?? this.audioChannels,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      customVideoCodec: customVideoCodec ?? this.customVideoCodec,
      customAudioCodec: customAudioCodec ?? this.customAudioCodec,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec?.name,
      'audioCodec': audioCodec?.name,
      'subtitleFormat': subtitleFormat?.name,
      'videoCrf': videoCrf,
      'videoPreset': videoPreset,
      'videoBitrateKbps': videoBitrateKbps,
      'audioBitrate': audioBitrate,
      'audioChannels': audioChannels,
      'audioSampleRate': audioSampleRate,
      'customVideoCodec': customVideoCodec,
      'customAudioCodec': customAudioCodec,
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
      subtitleFormat: json['subtitleFormat'] != null
          ? SubtitleFormat.values
              .firstWhere((e) => e.name == json['subtitleFormat'])
          : null,
      videoCrf: json['videoCrf'] as int?,
      videoPreset: json['videoPreset'] as String?,
      videoBitrateKbps: json['videoBitrateKbps'] as int?,
      audioBitrate: json['audioBitrate'] as int?,
      audioChannels: json['audioChannels'] as int?,
      audioSampleRate: json['audioSampleRate'] as int?,
      customVideoCodec: json['customVideoCodec'] as String?,
      customAudioCodec: json['customAudioCodec'] as String?,
    );
  }
}

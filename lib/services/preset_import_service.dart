import 'dart:convert';
import 'dart:io';
import '../models/external_preset.dart';
import 'package:path/path.dart' as path;

/// Service for importing presets from external tools like HandBrake.
class PresetImportService {
  /// Imports a preset file and returns a list of external presets.
  Future<List<ExternalPreset>> importPresetFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Preset file not found: $filePath');
    }

    final extension = path.extension(filePath).toLowerCase();

    if (extension == '.json') {
      return await _importHandBrakeJson(file);
    } else if (extension == '.xml') {
      return await _importHandBrakeXml(file);
    } else {
      throw Exception('Unsupported preset file format: $extension');
    }
  }

  /// Imports HandBrake JSON preset format.
  Future<List<ExternalPreset>> _importHandBrakeJson(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);

      final presets = <ExternalPreset>[];

      // HandBrake JSON format can have multiple structures
      if (json is List) {
        for (var presetData in json) {
          final preset =
              _parseHandBrakePreset(presetData as Map<String, dynamic>);
          if (preset != null) presets.add(preset);
        }
      } else if (json is Map) {
        // Single preset or container with "PresetList"
        if (json.containsKey('PresetList')) {
          final presetList = json['PresetList'] as List;
          for (var presetData in presetList) {
            final preset =
                _parseHandBrakePreset(presetData as Map<String, dynamic>);
            if (preset != null) presets.add(preset);
          }
        } else {
          final preset = _parseHandBrakePreset(json as Map<String, dynamic>);
          if (preset != null) presets.add(preset);
        }
      }

      return presets;
    } catch (e) {
      throw Exception('Failed to parse HandBrake JSON: $e');
    }
  }

  /// Imports HandBrake XML preset format.
  Future<List<ExternalPreset>> _importHandBrakeXml(File file) async {
    // For simplicity, we'll return an empty list for XML
    // In a real implementation, you would parse XML using an XML parser package
    throw UnimplementedError('XML preset import is not yet implemented');
  }

  /// Parses a single HandBrake preset and maps it to FFmpeg parameters.
  ExternalPreset? _parseHandBrakePreset(Map<String, dynamic> data) {
    try {
      final name =
          data['PresetName'] as String? ?? data['name'] as String? ?? 'Unnamed';
      final description = data['PresetDescription'] as String? ??
          data['description'] as String?;
      final category = data['Type'] as String? ?? data['category'] as String?;

      // Map HandBrake parameters to FFmpeg
      final mapping = _mapHandBrakeToFFmpeg(data);

      return ExternalPreset(
        name: name,
        description: description,
        source: 'HandBrake',
        category: category,
        rawData: data,
        mapping: mapping,
      );
    } catch (e) {
      // Skip invalid presets
      return null;
    }
  }

  /// Maps HandBrake preset parameters to FFmpeg parameters.
  PresetMapping _mapHandBrakeToFFmpeg(Map<String, dynamic> data) {
    final warnings = <String>[];
    bool isCompatible = true;

    // Video codec mapping
    String? videoCodec;
    final videoEncoder = data['VideoEncoder'] as String?;
    if (videoEncoder != null) {
      videoCodec = _mapVideoEncoder(videoEncoder);
      if (videoCodec == null) {
        warnings.add('Unsupported video encoder: $videoEncoder');
        isCompatible = false;
      }
    }

    // Audio codec mapping
    String? audioCodec;
    final audioEncoders = data['AudioList'] as List?;
    if (audioEncoders != null && audioEncoders.isNotEmpty) {
      final firstEncoder = audioEncoders[0] as Map<String, dynamic>?;
      final encoder = firstEncoder?['AudioEncoder'] as String?;
      if (encoder != null) {
        audioCodec = _mapAudioEncoder(encoder);
        if (audioCodec == null) {
          warnings.add('Unsupported audio encoder: $encoder');
        }
      }
    }

    // Video quality
    String? videoQuality;
    if (data.containsKey('VideoQualitySlider')) {
      final quality = data['VideoQualitySlider'];
      videoQuality = 'CRF ${quality.toString()}';
    } else if (data.containsKey('VideoAvgBitrate')) {
      final bitrate = data['VideoAvgBitrate'];
      videoQuality = '${bitrate}k';
    }

    // Audio bitrate
    String? audioBitrate;
    if (audioEncoders != null && audioEncoders.isNotEmpty) {
      final firstEncoder = audioEncoders[0] as Map<String, dynamic>?;
      final bitrate = firstEncoder?['AudioBitrate'] as num?;
      if (bitrate != null) {
        audioBitrate = '${bitrate}k';
      }
    }

    // Audio sample rate
    int? audioSampleRate;
    if (audioEncoders != null && audioEncoders.isNotEmpty) {
      final firstEncoder = audioEncoders[0] as Map<String, dynamic>?;
      final samplerate = firstEncoder?['AudioSamplerate'] as String?;
      if (samplerate != null && samplerate != 'auto') {
        audioSampleRate = int.tryParse(samplerate);
      }
    }

    // Resolution
    String? resolution;
    if (data.containsKey('PictureWidth') && data.containsKey('PictureHeight')) {
      final width = data['PictureWidth'];
      final height = data['PictureHeight'];
      if (width != null && height != null) {
        resolution = '${width}x$height';
      }
    }

    // Frame rate
    String? frameRate;
    final videoFramerate = data['VideoFramerate'] as String?;
    if (videoFramerate != null && videoFramerate != 'auto') {
      frameRate = videoFramerate;
    }

    // Format
    String? format;
    final fileFormat = data['FileFormat'] as String?;
    if (fileFormat != null) {
      format = _mapFileFormat(fileFormat);
      if (format == null) {
        warnings.add('Unsupported file format: $fileFormat');
      }
    }

    // Additional args
    final additionalArgs = <String>[];

    // Check for filters
    if (data.containsKey('PictureDecombDeinterlace') &&
        data['PictureDecombDeinterlace'] == true) {
      warnings.add('Deinterlacing may require manual configuration in FFmpeg');
    }

    if (data.containsKey('PictureDetelecine') &&
        data['PictureDetelecine'] != 'off') {
      warnings.add('Detelecine filter not directly supported');
    }

    return PresetMapping(
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      videoQuality: videoQuality,
      audioBitrate: audioBitrate,
      audioSampleRate: audioSampleRate,
      resolution: resolution,
      frameRate: frameRate,
      format: format,
      additionalArgs: additionalArgs,
      warnings: warnings,
      isCompatible: isCompatible,
    );
  }

  /// Maps HandBrake video encoder to FFmpeg codec.
  String? _mapVideoEncoder(String encoder) {
    final encoderLower = encoder.toLowerCase();

    if (encoderLower.contains('x264')) {
      return 'h264';
    }
    if (encoderLower.contains('x265') || encoderLower.contains('hevc')) {
      return 'hevc';
    }
    if (encoderLower.contains('vp9')) {
      return 'vp9';
    }
    if (encoderLower.contains('vp8')) {
      return 'vp8';
    }
    if (encoderLower.contains('av1')) {
      return 'av1';
    }
    if (encoderLower.contains('mpeg4')) {
      return 'mpeg4';
    }
    if (encoderLower.contains('mpeg2')) {
      return 'mpeg2';
    }

    return null;
  }

  /// Maps HandBrake audio encoder to FFmpeg codec.
  String? _mapAudioEncoder(String encoder) {
    final encoderLower = encoder.toLowerCase();

    if (encoderLower.contains('aac')) {
      return 'aac';
    }
    if (encoderLower.contains('mp3') || encoderLower.contains('lame')) {
      return 'mp3';
    }
    if (encoderLower.contains('opus')) {
      return 'opus';
    }
    if (encoderLower.contains('vorbis')) {
      return 'vorbis';
    }
    if (encoderLower.contains('flac')) {
      return 'flac';
    }
    if (encoderLower.contains('ac3')) {
      return 'ac3';
    }
    if (encoderLower.contains('eac3')) {
      return 'eac3';
    }
    if (encoderLower.contains('dts')) {
      return 'dts';
    }

    return null;
  }

  /// Maps HandBrake file format to FFmpeg format.
  String? _mapFileFormat(String format) {
    final formatLower = format.toLowerCase();

    if (formatLower.contains('mp4') || formatLower == 'av_mp4') return 'mp4';
    if (formatLower.contains('mkv') || formatLower == 'av_mkv') return 'mkv';
    if (formatLower.contains('webm')) return 'webm';
    if (formatLower.contains('avi')) return 'avi';

    return null;
  }

  /// Validates a preset mapping for compatibility.
  bool validateMapping(PresetMapping mapping) {
    return mapping.isCompatible && mapping.warnings.isEmpty;
  }

  /// Gets a list of all warnings for a preset.
  List<String> getPresetWarnings(ExternalPreset preset) {
    return preset.mapping?.warnings ?? [];
  }
}

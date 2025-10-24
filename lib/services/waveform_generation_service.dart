import 'dart:io';
import 'dart:typed_data';
import '../models/waveform_data.dart';

/// Service for generating waveform data from audio files.
class WaveformGenerationService {
  /// Generates waveform data from an audio file.
  /// 
  /// Uses FFmpeg to extract raw audio data and downsample it for visualization.
  /// [filePath] - Path to the audio/video file
  /// [trackIndex] - Index of the audio track to extract
  /// [targetSampleRate] - Sample rate for the waveform (lower = less detailed but faster)
  /// [maxSamples] - Maximum number of samples to generate (for performance)
  Future<WaveformData?> generateWaveform(
    String filePath,
    int trackIndex, {
    int targetSampleRate = 1000,
    int maxSamples = 10000,
  }) async {
    try {
      // First, get audio information using ffprobe
      final probeResult = await Process.run(
        'ffprobe',
        [
          '-v', 'error',
          '-select_streams', 'a:$trackIndex',
          '-show_entries', 'stream=codec_name,sample_rate,channels,duration',
          '-of', 'default=noprint_wrappers=1',
          filePath,
        ],
      );

      if (probeResult.exitCode != 0) {
        return null;
      }

      // Parse ffprobe output
      final output = probeResult.stdout.toString();
      final lines = output.split('\n');
      
      int originalSampleRate = 44100;
      int channels = 2;
      double duration = 0.0;
      
      for (var line in lines) {
        if (line.startsWith('sample_rate=')) {
          originalSampleRate = int.tryParse(line.split('=')[1]) ?? 44100;
        } else if (line.startsWith('channels=')) {
          channels = int.tryParse(line.split('=')[1]) ?? 2;
        } else if (line.startsWith('duration=')) {
          duration = double.tryParse(line.split('=')[1]) ?? 0.0;
        }
      }

      if (duration == 0.0) {
        return null;
      }

      // Extract audio data using FFmpeg
      // Convert to mono, downsample, and output as raw PCM float32
      final ffmpegResult = await Process.run(
        'ffmpeg',
        [
          '-i', filePath,
          '-map', '0:a:$trackIndex',
          '-ac', '1', // Convert to mono
          '-ar', targetSampleRate.toString(), // Downsample
          '-f', 'f32le', // Output as float32 little endian
          '-acodec', 'pcm_f32le',
          'pipe:1',
        ],
        stdoutEncoding: null, // Get raw bytes
      );

      if (ffmpegResult.exitCode != 0) {
        return null;
      }

      // Parse the raw audio data
      final rawData = ffmpegResult.stdout as List<int>;
      final samples = _parseFloat32Data(rawData, maxSamples);

      return WaveformData(
        filePath: filePath,
        trackIndex: trackIndex,
        sampleRate: targetSampleRate,
        duration: duration,
        samples: samples,
        channels: 1, // Always mono after conversion
      );
    } catch (e) {
      // Return null on any error
      return null;
    }
  }

  /// Parses raw float32 PCM data into a Float32List.
  Float32List _parseFloat32Data(List<int> rawData, int maxSamples) {
    // Each float32 is 4 bytes
    final numFloats = rawData.length ~/ 4;
    final actualSamples = numFloats < maxSamples ? numFloats : maxSamples;
    
    final samples = Float32List(actualSamples);
    final byteData = ByteData.sublistView(Uint8List.fromList(rawData));
    
    if (numFloats <= maxSamples) {
      // Use all samples
      for (int i = 0; i < actualSamples; i++) {
        samples[i] = byteData.getFloat32(i * 4, Endian.little);
      }
    } else {
      // Downsample by taking peaks in chunks
      final chunkSize = numFloats / maxSamples;
      for (int i = 0; i < actualSamples; i++) {
        final startIdx = (i * chunkSize).floor();
        final endIdx = ((i + 1) * chunkSize).floor();
        
        double peak = 0.0;
        for (int j = startIdx; j < endIdx && j < numFloats; j++) {
          final sample = byteData.getFloat32(j * 4, Endian.little);
          if (sample.abs() > peak.abs()) {
            peak = sample;
          }
        }
        samples[i] = peak;
      }
    }
    
    return samples;
  }

  /// Generates a simplified waveform for quick preview.
  /// This is faster but less accurate than generateWaveform.
  Future<WaveformData?> generateQuickWaveform(
    String filePath,
    int trackIndex,
  ) async {
    return generateWaveform(
      filePath,
      trackIndex,
      targetSampleRate: 100,
      maxSamples: 1000,
    );
  }
}

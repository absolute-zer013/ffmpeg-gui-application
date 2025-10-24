import 'dart:typed_data';

/// Model representing waveform data for audio visualization.
class WaveformData {
  /// The file path of the audio source.
  final String filePath;
  
  /// The audio track index.
  final int trackIndex;
  
  /// The sample rate of the waveform data.
  final int sampleRate;
  
  /// The duration of the audio in seconds.
  final double duration;
  
  /// The waveform samples (amplitude values normalized to -1.0 to 1.0).
  final Float32List samples;
  
  /// The number of channels (1 for mono, 2 for stereo, etc.).
  final int channels;

  const WaveformData({
    required this.filePath,
    required this.trackIndex,
    required this.sampleRate,
    required this.duration,
    required this.samples,
    required this.channels,
  });

  /// Returns the number of samples in the waveform.
  int get sampleCount => samples.length;

  /// Returns the sample at the given index (clamped to valid range).
  double getSample(int index) {
    if (index < 0 || index >= samples.length) return 0.0;
    return samples[index];
  }

  /// Returns samples for a specific time range.
  Float32List getSamplesInRange(double startTime, double endTime) {
    final startIndex = (startTime * sampleRate).floor().clamp(0, samples.length - 1);
    final endIndex = (endTime * sampleRate).ceil().clamp(0, samples.length);
    
    if (startIndex >= endIndex) return Float32List(0);
    
    return Float32List.sublistView(samples, startIndex, endIndex);
  }

  /// Returns the peak amplitude in a time range.
  double getPeakAmplitude(double startTime, double endTime) {
    final rangeSamples = getSamplesInRange(startTime, endTime);
    if (rangeSamples.isEmpty) return 0.0;
    
    double peak = 0.0;
    for (var sample in rangeSamples) {
      final abs = sample.abs();
      if (abs > peak) peak = abs;
    }
    return peak;
  }

  /// Returns the RMS (root mean square) amplitude in a time range.
  double getRMSAmplitude(double startTime, double endTime) {
    final rangeSamples = getSamplesInRange(startTime, endTime);
    if (rangeSamples.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (var sample in rangeSamples) {
      sum += sample * sample;
    }
    return (sum / rangeSamples.length).sqrt();
  }

  /// Detects silence regions (amplitude below threshold).
  List<SilenceRegion> detectSilence({double threshold = 0.01, double minDuration = 0.5}) {
    final regions = <SilenceRegion>[];
    bool inSilence = false;
    double silenceStart = 0.0;
    
    final samplesPerCheck = (sampleRate * 0.1).round(); // Check every 100ms
    
    for (int i = 0; i < samples.length; i += samplesPerCheck) {
      final endIdx = (i + samplesPerCheck).clamp(0, samples.length);
      final chunk = Float32List.sublistView(samples, i, endIdx);
      
      // Calculate RMS for this chunk
      double sum = 0.0;
      for (var sample in chunk) {
        sum += sample * sample;
      }
      final rms = (sum / chunk.length).sqrt();
      
      final time = i / sampleRate;
      
      if (rms < threshold) {
        if (!inSilence) {
          silenceStart = time;
          inSilence = true;
        }
      } else {
        if (inSilence) {
          final duration = time - silenceStart;
          if (duration >= minDuration) {
            regions.add(SilenceRegion(start: silenceStart, end: time));
          }
          inSilence = false;
        }
      }
    }
    
    // Handle silence at the end
    if (inSilence) {
      final duration = this.duration - silenceStart;
      if (duration >= minDuration) {
        regions.add(SilenceRegion(start: silenceStart, end: this.duration));
      }
    }
    
    return regions;
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'trackIndex': trackIndex,
      'sampleRate': sampleRate,
      'duration': duration,
      'sampleCount': samples.length,
      'channels': channels,
    };
  }
}

/// Represents a region of silence in the audio.
class SilenceRegion {
  /// Start time in seconds.
  final double start;
  
  /// End time in seconds.
  final double end;

  const SilenceRegion({
    required this.start,
    required this.end,
  });

  /// Duration of the silence region in seconds.
  double get duration => end - start;

  @override
  String toString() => 'SilenceRegion($start - $end, ${duration.toStringAsFixed(2)}s)';
}

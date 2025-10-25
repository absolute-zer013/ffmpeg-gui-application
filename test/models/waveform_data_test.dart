import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/waveform_data.dart';

void main() {
  group('WaveformData', () {
    test('creates instance with valid data', () {
      final samples = Float32List.fromList([0.0, 0.5, 1.0, -0.5, -1.0]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 1000,
        duration: 5.0,
        samples: samples,
        channels: 1,
      );

      expect(waveform.filePath, '/path/to/file.mkv');
      expect(waveform.trackIndex, 0);
      expect(waveform.sampleRate, 1000);
      expect(waveform.duration, 5.0);
      expect(waveform.sampleCount, 5);
      expect(waveform.channels, 1);
    });

    test('getSample returns correct value', () {
      final samples = Float32List.fromList([0.0, 0.5, 1.0, -0.5, -1.0]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 1000,
        duration: 5.0,
        samples: samples,
        channels: 1,
      );

      expect(waveform.getSample(0), 0.0);
      expect(waveform.getSample(1), 0.5);
      expect(waveform.getSample(2), 1.0);
      expect(waveform.getSample(3), -0.5);
      expect(waveform.getSample(4), -1.0);
    });

    test('getSample returns 0.0 for out of bounds index', () {
      final samples = Float32List.fromList([0.0, 0.5, 1.0]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 1000,
        duration: 3.0,
        samples: samples,
        channels: 1,
      );

      expect(waveform.getSample(-1), 0.0);
      expect(waveform.getSample(100), 0.0);
    });

    test('getSamplesInRange returns correct subset', () {
      final samples = Float32List.fromList([0.0, 0.1, 0.2, 0.3, 0.4, 0.5]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 2, // 2 samples per second
        duration: 3.0,
        samples: samples,
        channels: 1,
      );

      final range = waveform.getSamplesInRange(1.0, 2.0);
      expect(range.length, 2); // 1 second at 2 samples/second
      expect(range[0], 0.2);
      expect(range[1], 0.3);
    });

    test('getPeakAmplitude returns highest absolute value', () {
      final samples = Float32List.fromList([0.1, -0.8, 0.5, -0.3]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 4,
        duration: 1.0,
        samples: samples,
        channels: 1,
      );

      final peak = waveform.getPeakAmplitude(0.0, 1.0);
      expect(peak, 0.8); // Absolute value of -0.8
    });

    test('getRMSAmplitude calculates correctly', () {
      final samples = Float32List.fromList([0.5, 0.5, 0.5, 0.5]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 4,
        duration: 1.0,
        samples: samples,
        channels: 1,
      );

      final rms = waveform.getRMSAmplitude(0.0, 1.0);
      expect(rms, closeTo(0.5, 0.001)); // RMS of constant 0.5 is 0.5
    });

    test('detectSilence finds silent regions', () {
      // Create a waveform with silence in the middle
      final samples = Float32List(100);
      for (int i = 0; i < 20; i++) {
        samples[i] = 0.5; // Loud
      }
      for (int i = 20; i < 80; i++) {
        samples[i] = 0.005; // Silent
      }
      for (int i = 80; i < 100; i++) {
        samples[i] = 0.5; // Loud
      }

      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 10, // 10 samples per second
        duration: 10.0,
        samples: samples,
        channels: 1,
      );

      final silenceRegions =
          waveform.detectSilence(threshold: 0.01, minDuration: 0.5);

      expect(silenceRegions.isNotEmpty, true);
      // Should detect the middle silent section
    });

    test('toJson serializes metadata correctly', () {
      final samples = Float32List.fromList([0.0, 0.5, 1.0]);
      final waveform = WaveformData(
        filePath: '/path/to/file.mkv',
        trackIndex: 0,
        sampleRate: 1000,
        duration: 3.0,
        samples: samples,
        channels: 2,
      );

      final json = waveform.toJson();

      expect(json['filePath'], '/path/to/file.mkv');
      expect(json['trackIndex'], 0);
      expect(json['sampleRate'], 1000);
      expect(json['duration'], 3.0);
      expect(json['sampleCount'], 3);
      expect(json['channels'], 2);
    });
  });

  group('SilenceRegion', () {
    test('creates instance correctly', () {
      const region = SilenceRegion(start: 1.0, end: 3.0);

      expect(region.start, 1.0);
      expect(region.end, 3.0);
      expect(region.duration, 2.0);
    });

    test('toString formats correctly', () {
      const region = SilenceRegion(start: 1.5, end: 4.7);

      final str = region.toString();
      expect(str, contains('1.5'));
      expect(str, contains('4.7'));
      expect(str, contains('3.20')); // Duration
    });
  });
}

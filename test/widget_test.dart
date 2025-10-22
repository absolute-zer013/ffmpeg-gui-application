import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/main.dart';
import 'package:ffmpeg_filter_app/models/export_profile.dart';
import 'package:ffmpeg_filter_app/models/track.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';

void main() {
  group('Track model tests', () {
    test('Track initializes with correct values', () {
      final track = Track(
        position: 0,
        language: 'eng',
        title: 'English',
        description: 'Audio [eng]',
        streamIndex: 1,
        type: TrackType.audio,
      );

      expect(track.position, 0);
      expect(track.language, 'eng');
      expect(track.title, 'English');
      expect(track.streamIndex, 1);
      expect(track.type, TrackType.audio);
    });

    test('Track uses position as default streamIndex', () {
      final track = Track(
        position: 2,
        language: 'spa',
        description: 'Spanish audio',
        type: TrackType.audio,
      );

      expect(track.streamIndex, 2);
    });

    test('Track supports video type with codec info', () {
      final track = Track(
        position: 0,
        language: 'und',
        description: 'Video [H264 1920x1080]',
        type: TrackType.video,
        codec: 'h264',
        width: 1920,
        height: 1080,
      );

      expect(track.type, TrackType.video);
      expect(track.codec, 'h264');
      expect(track.width, 1920);
      expect(track.height, 1080);
    });
  });

  group('ExportProfile model tests', () {
    test('ExportProfile initializes with correct values', () {
      final profile = ExportProfile(
        id: 'profile_1',
        name: 'Japanese Only',
        description: 'Keeps only Japanese audio',
        selectedAudioLanguages: {'jpn'},
        selectedSubtitleDescriptions: {'eng (English)'},
        defaultSubtitleDescription: 'eng (English)',
      );

      expect(profile.id, 'profile_1');
      expect(profile.name, 'Japanese Only');
      expect(profile.description, 'Keeps only Japanese audio');
      expect(profile.selectedAudioLanguages.contains('jpn'), true);
      expect(
          profile.selectedSubtitleDescriptions.contains('eng (English)'), true);
      expect(profile.defaultSubtitleDescription, 'eng (English)');
    });

    test('ExportProfile converts to and from JSON', () {
      final profile = ExportProfile(
        id: 'profile_1',
        name: 'Test Profile',
        description: 'Test Description',
        selectedAudioLanguages: {'eng', 'jpn'},
        selectedSubtitleDescriptions: {'eng (English)', 'jpn (Japanese)'},
        defaultSubtitleDescription: 'eng (English)',
      );

      final json = profile.toJson();
      final restored = ExportProfile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.description, profile.description);
      expect(restored.selectedAudioLanguages, profile.selectedAudioLanguages);
      expect(restored.selectedSubtitleDescriptions,
          profile.selectedSubtitleDescriptions);
      expect(restored.defaultSubtitleDescription,
          profile.defaultSubtitleDescription);
    });

    test('ExportProfile copyWith creates modified copy', () {
      final original = ExportProfile(
        id: 'profile_1',
        name: 'Original',
        description: 'Original description',
      );

      final modified = original.copyWith(
        name: 'Modified',
        selectedAudioLanguages: {'eng'},
      );

      expect(modified.id, original.id);
      expect(modified.name, 'Modified');
      expect(modified.description, 'Original description');
      expect(modified.selectedAudioLanguages.contains('eng'), true);
    });
  });

  group('FileItem model tests', () {
    test('FileItem initializes with empty selections', () {
      final file = FileItem(
        path: '/test/file.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );

      expect(file.selectedVideo.isEmpty, true);
      expect(file.selectedAudio.isEmpty, true);
      expect(file.selectedSubtitles.isEmpty, true);
      expect(file.defaultVideo, null);
      expect(file.defaultAudio, null);
      expect(file.defaultSubtitle, null);
      expect(file.exportStatus, '');
      expect(file.exportProgress, 0.0);
    });

    test('FileItem can track selected video, audio and subtitle positions', () {
      final video1 = Track(
          position: 0,
          language: 'und',
          description: 'Video 1',
          type: TrackType.video);
      final audio1 = Track(
          position: 0,
          language: 'eng',
          description: 'Audio 1',
          type: TrackType.audio);
      final audio2 = Track(
          position: 1,
          language: 'spa',
          description: 'Audio 2',
          type: TrackType.audio);
      final sub1 = Track(
          position: 0,
          language: 'eng',
          description: 'Sub 1',
          type: TrackType.subtitle);

      final file = FileItem(
        path: '/test/file.mkv',
        videoTracks: [video1],
        audioTracks: [audio1, audio2],
        subtitleTracks: [sub1],
      );

      file.selectedVideo.add(0);
      file.selectedAudio.add(0);
      file.selectedAudio.add(1);
      file.selectedSubtitles.add(0);
      file.defaultVideo = 0;
      file.defaultAudio = 1;
      file.defaultSubtitle = 0;

      expect(file.selectedVideo.length, 1);
      expect(file.selectedAudio.length, 2);
      expect(file.selectedSubtitles.length, 1);
      expect(file.defaultVideo, 0);
      expect(file.defaultAudio, 1);
      expect(file.defaultSubtitle, 0);
    });

    test('FileItem export status can be updated', () {
      final file = FileItem(
        path: '/test/file.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );

      file.exportStatus = 'running';
      file.exportProgress = 0.5;

      expect(file.exportStatus, 'running');
      expect(file.exportProgress, 0.5);

      file.exportStatus = 'completed';
      file.exportProgress = 1.0;

      expect(file.exportStatus, 'completed');
      expect(file.exportProgress, 1.0);
    });
  });

  testWidgets('App builds and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('FFmpeg Export Tool'), findsOneWidget);
  });

  testWidgets('App shows Add Files button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Add Files'), findsOneWidget);
  });

  testWidgets('App shows batch mode checkbox', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Batch mode'), findsOneWidget);
  });
}

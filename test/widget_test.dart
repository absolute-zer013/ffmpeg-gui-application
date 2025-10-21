import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/main.dart';

void main() {
  group('Track model tests', () {
    test('Track initializes with correct values', () {
      final track = Track(
        position: 0,
        language: 'eng',
        title: 'English',
        description: 'Audio [eng]',
        streamIndex: 1,
      );

      expect(track.position, 0);
      expect(track.language, 'eng');
      expect(track.title, 'English');
      expect(track.streamIndex, 1);
    });

    test('Track uses position as default streamIndex', () {
      final track = Track(
        position: 2,
        language: 'spa',
        description: 'Spanish audio',
      );

      expect(track.streamIndex, 2);
    });
  });

  group('FileItem model tests', () {
    test('FileItem initializes with empty selections', () {
      final file = FileItem(
        path: '/test/file.mkv',
        audioTracks: [],
        subtitleTracks: [],
      );

      expect(file.selectedAudio.isEmpty, true);
      expect(file.selectedSubtitles.isEmpty, true);
      expect(file.defaultAudio, null);
      expect(file.defaultSubtitle, null);
      expect(file.exportStatus, '');
      expect(file.exportProgress, 0.0);
    });

    test('FileItem can track selected audio and subtitle positions', () {
      final audio1 =
          Track(position: 0, language: 'eng', description: 'Audio 1');
      final audio2 =
          Track(position: 1, language: 'spa', description: 'Audio 2');
      final sub1 = Track(position: 0, language: 'eng', description: 'Sub 1');

      final file = FileItem(
        path: '/test/file.mkv',
        audioTracks: [audio1, audio2],
        subtitleTracks: [sub1],
      );

      file.selectedAudio.add(0);
      file.selectedAudio.add(1);
      file.selectedSubtitles.add(0);
      file.defaultAudio = 1;
      file.defaultSubtitle = 0;

      expect(file.selectedAudio.length, 2);
      expect(file.selectedSubtitles.length, 1);
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
    expect(find.text('Export File - Fixed'), findsOneWidget);
  });

  testWidgets('App shows Add Files button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Add Files'), findsOneWidget);
  });

  testWidgets('App shows batch mode checkboxes for audio and subtitle',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // There should be two "Batch mode" labels - one for Audio and one for Subtitle
    expect(find.text('Batch mode'), findsNWidgets(2));
  });

  testWidgets('App shows export settings', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Export Settings'), findsOneWidget);
  });
}

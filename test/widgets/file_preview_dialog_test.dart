import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/widgets/file_preview_dialog.dart';
import 'package:ffmpeg_filter_app/models/file_item.dart';
import 'package:ffmpeg_filter_app/models/track.dart';
import 'package:ffmpeg_filter_app/models/metadata.dart';

void main() {
  group('FilePreviewDialog', () {
    late FileItem fileItem;

    setUp(() {
      fileItem = FileItem(
        path: '/path/to/video.mkv',
        audioTracks: [
          Track(
            position: 0,
            language: 'eng',
            description: 'English Audio',
            type: TrackType.audio,
            codec: 'aac',
            channels: 2,
          ),
          Track(
            position: 1,
            language: 'jpn',
            description: 'Japanese Audio',
            type: TrackType.audio,
            codec: 'aac',
            channels: 2,
          ),
        ],
        subtitleTracks: [
          Track(
            position: 0,
            language: 'eng',
            description: 'English Subtitles',
            type: TrackType.subtitle,
            codec: 'srt',
          ),
        ],
      );
      fileItem.videoTracks.add(Track(
        position: 0,
        language: 'und',
        description: 'Video',
        type: TrackType.video,
        codec: 'h264',
        width: 1920,
        height: 1080,
      ));
      fileItem.fileSize = 1024 * 1024 * 100; // 100 MB
      fileItem.duration = '01:30:00';
    });

    testWidgets('Dialog displays file name in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('File Preview'), findsOneWidget);
      expect(find.text('video.mkv'), findsOneWidget);
    });

    testWidgets('Dialog displays file information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('File Information'), findsOneWidget);
      expect(find.textContaining('video.mkv'), findsWidgets);
    });

    testWidgets('Dialog displays video tracks section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Video Tracks (1)'), findsOneWidget);
      expect(find.textContaining('h264'), findsOneWidget);
      expect(find.textContaining('1920x1080'), findsOneWidget);
    });

    testWidgets('Dialog displays audio tracks section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Audio Tracks (2)'), findsOneWidget);
      expect(find.textContaining('English Audio'), findsOneWidget);
      expect(find.textContaining('Japanese Audio'), findsOneWidget);
    });

    testWidgets('Dialog displays subtitle tracks section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Subtitle Tracks (1)'), findsOneWidget);
      expect(find.textContaining('English Subtitles'), findsOneWidget);
    });

    testWidgets('Dialog displays metadata section when available',
        (WidgetTester tester) async {
      fileItem.fileMetadata = FileMetadata(
        title: 'Test Movie',
        artist: 'Test Artist',
        album: 'Test Album',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.textContaining('Test Movie'), findsOneWidget);
      expect(find.textContaining('Test Artist'), findsOneWidget);
      expect(find.textContaining('Test Album'), findsOneWidget);
    });

    testWidgets('Dialog shows selected audio tracks',
        (WidgetTester tester) async {
      fileItem.selectedAudio.add(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Selected'), findsWidgets);
    });

    testWidgets('Dialog shows default tracks', (WidgetTester tester) async {
      fileItem.defaultAudio = 0;
      fileItem.defaultSubtitle = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsWidgets);
    });

    testWidgets('Dialog has Close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsNWidgets(2)); // Header X and footer button
    });

    testWidgets('Dialog has Open Location button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Open Location'), findsOneWidget);
    });

    testWidgets('Dialog can be closed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close').last);
      await tester.pumpAndSettle();

      expect(find.text('File Preview'), findsNothing);
    });

    testWidgets('Dialog handles files without video tracks',
        (WidgetTester tester) async {
      fileItem.videoTracks.clear();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(item: fileItem),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Video Tracks'), findsNothing);
    });
  });
}

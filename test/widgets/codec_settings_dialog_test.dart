import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/widgets/codec_settings_dialog.dart';

void main() {
  group('CodecSettingsDialog', () {
    testWidgets('Dialog shows correct title for single file video settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: true,
                    showBatchOptions: false,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Video Codec Settings'), findsOneWidget);
    });

    testWidgets('Dialog shows correct title for single file audio settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: false,
                    showBatchOptions: false,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Audio Codec Settings'), findsOneWidget);
    });

    testWidgets('Dialog shows batch mode title for video with file count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: true,
                    showBatchOptions: true,
                    fileCount: 5,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Video Codec Settings (5 files)'), findsOneWidget);
    });

    testWidgets('Dialog shows batch mode title for audio with file count',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: false,
                    showBatchOptions: true,
                    fileCount: 3,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Audio Codec Settings (3 files)'), findsOneWidget);
    });

    testWidgets('Dialog shows "Apply to All" button in batch mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: true,
                    showBatchOptions: true,
                    fileCount: 5,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Apply to All'), findsOneWidget);
    });

    testWidgets('Dialog shows "Apply" button in single file mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: true,
                    showBatchOptions: false,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Apply to All'), findsNothing);
    });

    testWidgets('Dialog returns applyToAll flag in batch mode',
        (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>?>(
                    context: context,
                    builder: (context) => const CodecSettingsDialog(
                      isVideoTrack: true,
                      showBatchOptions: true,
                      fileCount: 5,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Find and tap "Apply to All" button
      await tester.tap(find.text('Apply to All'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['applyToAll'], isTrue);
      expect(result!['codecSettings'], isNotNull);
    });

    testWidgets('Dialog includes video codec options for video track',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: true,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check that video codec section is visible
      expect(find.text('Video Codec'), findsOneWidget);
      expect(find.text('Audio Quality'), findsOneWidget);
    });

    testWidgets('Dialog includes audio codec options for audio track',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CodecSettingsDialog(
                    isVideoTrack: false,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Check that audio codec section is visible
      expect(find.text('Audio Codec'), findsOneWidget);
      expect(find.text('Audio Settings'), findsOneWidget);
    });

    testWidgets('Dialog can be cancelled', (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>?>(
                    context: context,
                    builder: (context) => const CodecSettingsDialog(
                      isVideoTrack: true,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}

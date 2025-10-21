# FFmpeg Filter App

This Flutter project implements a simple desktop utility for Windows that filters
Matroska (`.mkv`) files to remove English audio tracks and all subtitle
tracks except one that you choose. It uses
[`file_picker`](https://pub.dev/packages/file_picker) to select multiple files
and spawns the external `ffmpeg` and `ffprobe` tools to analyse and rewrite
the files.

## Features

- **Select multiple MKV files** using the system file picker.
- Specify the exact title of the subtitle track to keep. All other subtitles
  are dropped from the output.
- English audio tracks (`eng` language tag) are removed if present.
- Video streams, chapters, attachments and other audio/subtitle tracks are
  preserved.
- Processed files are saved into a `Filtered` sub‑directory with the same
  filename.

## Prerequisites

This application relies on external `ffmpeg` and `ffprobe` binaries being
available in the system `PATH`. You can download static builds of FFmpeg
for Windows from [ffmpeg.org](https://ffmpeg.org/download.html) or other
distributors. Make sure both `ffmpeg.exe` and `ffprobe.exe` are visible on
your command line.

To build and run this project, you also need Flutter with desktop support
enabled. See the official
[`Windows` documentation](https://docs.flutter.dev/platform-integration/windows/building)
for instructions on setting up Flutter for Windows development.

## Building and running

1. **Clone or unpack this repository** into a folder on your computer.
2. **Generate platform runners** if you haven’t already. From the project
   directory, run:
   
   ```bash
   flutter create --platforms=windows .
   ```
   
   This command adds the `windows` directory with a C++ runner. If you
   initialized the project using `flutter create`, this step is unnecessary.

3. **Fetch dependencies**:

   ```bash
   flutter pub get
   ```

4. **Run the application**:

   ```bash
   flutter run -d windows
   ```

When you click **Select MKV Files**, choose one or more `.mkv` files from
your disk. Enter the exact subtitle title (case‑sensitive) that you want to
keep in the field below, then press **Run Filter**. The application will
iterate over each file, examine its streams, and write a new file in the
`Filtered` folder.

## Notes

- The subtitle title must match exactly the title shown in tools like
  MKVToolNix or the `ffprobe` output. If a selected file does not contain
  the chosen title, all subtitle tracks are preserved for that file.
- This sample uses the `Process.run` API from `dart:io` to start
  `ffmpeg` and `ffprobe`. The application expects both commands to exit
  successfully; errors are reported in the log at the bottom of the UI.

Feel free to modify and extend this example to suit your needs. For example,
you could add a dialog that reads subtitle tracks from the first file and
lets you choose one interactively, or display progress indicators for each
file.

## New Features

### Export Profiles
The application now supports saving and reusing export configurations:

1. **Save Profile**: After selecting your desired audio/subtitle tracks, click "Save as Profile" to save the configuration
2. **Apply Profile**: Click "Profiles" to view saved profiles and apply them to new files
3. **Manage Profiles**: Delete unwanted profiles from the management dialog
4. **Persistent Storage**: Profiles are saved automatically and persist across sessions

Profiles store:
- Selected audio languages (e.g., Japanese, English)
- Selected subtitle descriptions
- Default subtitle track preference
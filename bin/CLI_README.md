# FFmpeg CLI - Command-Line Interface

A command-line interface for the FFmpeg Export Tool, enabling headless automation and scripting.

## Features

- **Headless Execution**: Process files without GUI
- **JSON Output**: Machine-readable output for scripting
- **File Information**: Inspect video/audio/subtitle tracks
- **Track Selection**: Choose specific tracks via arguments
- **Codec Configuration**: Specify video/audio codecs
- **Dry Run Mode**: Preview operations without execution
- **Verification Support**: Verify exported files

## Installation

### Prerequisites

- Dart SDK (included with Flutter)
- FFmpeg and FFprobe in system PATH

### Running from Source

```bash
dart run bin/ffmpeg_cli.dart [options]
```

### Compiling to Executable

```bash
# Windows
dart compile exe bin/ffmpeg_cli.dart -o ffmpeg_cli.exe

# Linux/Mac
dart compile exe bin/ffmpeg_cli.dart -o ffmpeg_cli
```

## Usage

### Basic Commands

```bash
# Show help
dart run bin/ffmpeg_cli.dart --help

# Show version
dart run bin/ffmpeg_cli.dart --version
```

### File Information

```bash
# Display file information
dart run bin/ffmpeg_cli.dart -i input.mkv --info

# Display as JSON
dart run bin/ffmpeg_cli.dart -i input.mkv --info --json
```

Example JSON output:
```json
{
  "fileName": "input.mkv",
  "filePath": "/path/to/input.mkv",
  "fileSize": 1073741824,
  "duration": "01:30:00",
  "format": "matroska,webm",
  "videoTracks": [
    {
      "index": 0,
      "codec": "h264",
      "language": "und"
    }
  ],
  "audioTracks": [
    {
      "index": 0,
      "codec": "aac",
      "title": "English",
      "language": "eng",
      "channels": 2
    },
    {
      "index": 1,
      "codec": "aac",
      "title": "Japanese",
      "language": "jpn",
      "channels": 2
    }
  ],
  "subtitleTracks": [
    {
      "index": 0,
      "codec": "ass",
      "title": "English",
      "language": "eng"
    }
  ]
}
```

### Track Selection

```bash
# Keep specific audio tracks (0 and 1)
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 -o output.mkv

# Keep specific subtitle tracks (0)
dart run bin/ffmpeg_cli.dart -i input.mkv -s 0 -o output.mkv

# Combine audio and subtitle selection
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 -s 0 -o output.mkv

# Keep all tracks (default if not specified)
dart run bin/ffmpeg_cli.dart -i input.mkv -o output.mkv
```

### Codec Conversion

```bash
# Convert video to H.264
dart run bin/ffmpeg_cli.dart -i input.mkv --video-codec h264 -o output.mkv

# Convert audio to AAC
dart run bin/ffmpeg_cli.dart -i input.mkv --audio-codec aac -o output.mkv

# Set audio bitrate
dart run bin/ffmpeg_cli.dart -i input.mkv --audio-codec aac --audio-bitrate 192k

# Combine video and audio conversion
dart run bin/ffmpeg_cli.dart -i input.mkv \
  --video-codec h264 \
  --audio-codec aac \
  --audio-bitrate 192k \
  -o output.mkv
```

### Output Format

```bash
# Specify output format (mkv, mp4, avi)
dart run bin/ffmpeg_cli.dart -i input.mkv -f mp4 -o output.mp4

# Default format is mkv
dart run bin/ffmpeg_cli.dart -i input.mkv -o output.mkv
```

### Dry Run

```bash
# Preview what would be done
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 --dry-run

# Dry run with JSON output
dart run bin/ffmpeg_cli.dart -i input.mkv -a 0,1 --dry-run --json
```

Example dry run output:
```
Dry run - would execute:
  Input: input.mkv
  Output: input_filtered.mkv
  Format: mkv
  Audio tracks: 0, 1
  Subtitle tracks: all
```

### Verification

```bash
# Verify exported file after export
dart run bin/ffmpeg_cli.dart -i input.mkv -o output.mkv --verify
```

## Command Reference

### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--help` | `-h` | Show help message | - |
| `--version` | `-v` | Show version | - |
| `--input` | `-i` | Input file path (required) | - |
| `--audio` | `-a` | Audio track indices (comma-separated) | All tracks |
| `--subtitle` | `-s` | Subtitle track indices (comma-separated) | All tracks |
| `--output` | `-o` | Output file path | `<input>_filtered.<format>` |
| `--format` | `-f` | Output format (mkv, mp4, avi) | `mkv` |
| `--json` | - | Output as JSON | `false` |
| `--info` | - | Show file info only | `false` |
| `--dry-run` | - | Preview without executing | `false` |
| `--video-codec` | - | Video codec (copy, h264, hevc, vp9, av1) | `copy` |
| `--audio-codec` | - | Audio codec (copy, aac, mp3, opus, ac3, flac) | `copy` |
| `--audio-bitrate` | - | Audio bitrate (e.g., 192k) | - |
| `--verify` | - | Verify output file | `false` |

### Supported Codecs

**Video Codecs:**
- `copy` - Copy without re-encoding (fastest)
- `h264` / `x264` - H.264/AVC
- `h265` / `hevc` / `x265` - H.265/HEVC
- `vp9` - VP9
- `av1` - AV1

**Audio Codecs:**
- `copy` - Copy without re-encoding (fastest)
- `aac` - AAC
- `mp3` - MP3
- `opus` - Opus
- `ac3` - AC3
- `flac` - FLAC

## Examples

### Example 1: Extract Japanese Audio Only

```bash
# Inspect file to find Japanese audio track index
dart run bin/ffmpeg_cli.dart -i anime.mkv --info

# Extract only Japanese audio (assuming it's track 1)
dart run bin/ffmpeg_cli.dart -i anime.mkv -a 1 -o anime_jp.mkv
```

### Example 2: Convert to MP4 with H.264/AAC

```bash
dart run bin/ffmpeg_cli.dart \
  -i input.mkv \
  -f mp4 \
  --video-codec h264 \
  --audio-codec aac \
  --audio-bitrate 192k \
  -o output.mp4
```

### Example 3: Batch Processing with Shell Script

**Windows (PowerShell):**
```powershell
Get-ChildItem *.mkv | ForEach-Object {
  dart run bin/ffmpeg_cli.dart -i $_.FullName -a 0 -s 0 --verify
}
```

**Linux/Mac (Bash):**
```bash
for file in *.mkv; do
  dart run bin/ffmpeg_cli.dart -i "$file" -a 0 -s 0 --verify
done
```

### Example 4: Extract File Metadata to JSON

```bash
# Extract metadata for all files in directory
for file in *.mkv; do
  dart run bin/ffmpeg_cli.dart -i "$file" --info --json > "${file%.mkv}.json"
done
```

### Example 5: Automated Pipeline with Error Handling

```bash
#!/bin/bash
for file in *.mkv; do
  echo "Processing: $file"
  
  # Export with verification
  result=$(dart run bin/ffmpeg_cli.dart \
    -i "$file" \
    -a 0,1 \
    -s 0 \
    --verify \
    --json)
  
  # Check if successful
  if echo "$result" | grep -q '"success": true'; then
    echo "✓ Success: $file"
  else
    echo "✗ Failed: $file"
    echo "$result"
  fi
done
```

## Exit Codes

- `0` - Success
- `1` - Error (file not found, FFmpeg error, export failed, etc.)

## Environment Variables

The CLI respects the same environment variables as FFmpeg:
- `PATH` - Must include FFmpeg and FFprobe executables
- `FLUTTER_TEST` - When set, skips certain checks (for testing)

## Troubleshooting

### FFmpeg Not Found

```
ERROR: Input file does not exist: /path/to/file.mkv
```

**Solution:** Install FFmpeg and add to PATH:
1. Download from https://ffmpeg.org/download.html
2. Extract to a folder
3. Add to system PATH
4. Verify: `ffmpeg -version`

### Permission Denied

```
ERROR: Permission denied: /path/to/output.mkv
```

**Solution:** Ensure you have write permissions to the output directory.

### Invalid Track Index

```
ERROR: Failed to analyze input file
```

**Solution:** Use `--info` to see available tracks and their indices.

## Integration with Other Tools

### CI/CD Pipeline (GitHub Actions)

```yaml
- name: Process videos
  run: |
    dart pub get
    dart run bin/ffmpeg_cli.dart -i input.mkv --verify --json
```

### Docker

```dockerfile
FROM dart:stable

RUN apt-get update && apt-get install -y ffmpeg

COPY . /app
WORKDIR /app

RUN dart pub get

ENTRYPOINT ["dart", "run", "bin/ffmpeg_cli.dart"]
```

Usage:
```bash
docker run -v $(pwd):/data myimage -i /data/input.mkv -o /data/output.mkv
```

## Performance

The CLI uses the same FFmpeg export service as the GUI:
- **Copy mode**: Fast (typically 1-5x realtime)
- **Re-encoding**: Slower (depends on codec and settings)
- **Verification**: Adds ~5-10% overhead

## Limitations

- No progress updates during export (use GUI for visual feedback)
- Cannot cancel running exports (use Ctrl+C)
- Limited to single file at a time (use shell scripts for batch)

## See Also

- Main application: `lib/main.dart`
- Export service: `lib/services/ffmpeg_export_service.dart`
- FFprobe service: `lib/services/ffprobe_service.dart`
- Documentation: `docs/`

## License

Same as the main FFmpeg Export Tool project.

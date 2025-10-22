# Quick Reference Guide

## Development Commands

### Testing
```bash
# Run all tests
.\run_tests.ps1 test

# Run model tests only
.\run_tests.ps1 test-models

# Run utility tests only
.\run_tests.ps1 test-utils

# Run tests with coverage
.\run_tests.ps1 coverage
```

### Code Quality
```bash
# Check code formatting
.\run_tests.ps1 format-check

# Auto-format code
.\run_tests.ps1 format

# Run static analysis
.\run_tests.ps1 analyze

# Run strict linting
.\run_tests.ps1 lint

# Run all quality checks
.\run_tests.ps1 all
```

### Cleaning
```bash
# Clean build artifacts
.\run_tests.ps1 clean

# Full flutter clean
flutter clean
```

## Building & Deployment

### Quick Build & Package
```bash
# Build and create distribution package
.\build_package.ps1 all

# Build only
.\build_package.ps1 build

# Package only (requires build first)
.\build_package.ps1 package
```

### Manual Build
```bash
# Build Windows release
flutter build windows --release

# Location: build\windows\x64\runner\Release\export_file.exe
```

## Running the Application

### Development Mode
```bash
# Run app in debug mode
flutter run -d windows
```

### Release Mode
```bash
# Direct execution (after build)
.\build\windows\x64\runner\Release\export_file.exe
```

## Git & Version Control

### Creating a Release
```bash
# Update version in pubspec.yaml first
# Then:

git add .
git commit -m "Release v1.0.1"
git tag v1.0.1
git push origin master v1.0.1
```

### GitHub Actions Build
- GitHub Actions automatically builds when tag is pushed
- Check: https://github.com/absolute-zer013/ffmpeg-gui-application/actions
- Release created automatically with artifacts

## Documentation Files

| File | Purpose | Details |
|------|---------|---------|
| `README.md` | Main overview | Features, setup, quick start |
| `FEATURES.md` | Feature list | All 20+ implemented features |
| `TESTING.md` | Testing guide | Test execution, CI/CD details |
| `DEPLOYMENT.md` | Release guide | Build, package, distribute |
| `CI_CD_SETUP.md` | CI/CD summary | Workflow overview, features |
| `ENHANCEMENTS.md` | Future features | 30 planned features by phase |
| `COMPLETION_SUMMARY.md` | Phase summary | What was completed, status |

## Project Structure

```
lib/
├── main.dart                 # Main app (997 lines)
├── models/
│   ├── track.dart           # Track model
│   ├── file_item.dart       # File item model
│   ├── export_profile.dart  # Export profile model
│   └── metadata.dart        # Metadata model
├── services/
│   ├── ffprobe_service.dart # FFprobe integration
│   ├── ffmpeg_export_service.dart # FFmpeg integration
│   └── profile_service.dart # Profile management
├── utils/
│   └── file_utils.dart      # Utility functions
└── widgets/
    ├── file_card.dart       # File card widget
    ├── audio_batch_card.dart # Batch audio widget
    └── subtitle_batch_card.dart # Batch subtitle widget

test/
├── widget_test.dart         # Widget tests
├── models/
│   ├── track_test.dart      # Track model tests
│   ├── file_item_test.dart  # FileItem tests
│   └── export_profile_test.dart # Profile tests
└── utils/
    └── file_utils_test.dart # Utility tests

.github/
└── workflows/
    └── ci-cd.yml            # GitHub Actions workflow
```

## Troubleshooting

### Tests Fail
```bash
# Clean and rebuild
flutter clean
flutter pub get
.\run_tests.ps1 test
```

### Build Fails
```bash
# Clear build cache
flutter clean

# Rebuild
flutter build windows --release
```

### FFmpeg Not Detected
1. Verify: `ffmpeg -version`
2. Add to PATH if needed
3. Restart application
4. Check app log for details

### Code Formatting Issues
```bash
# Auto-fix formatting
.\run_tests.ps1 format

# Verify format
.\run_tests.ps1 format-check
```

## Performance Tips

- Export uses stream copy (`-c copy`) for speed
- Parallel export supported (configurable 1-8)
- Real-time progress tracking
- Metadata preserved with `-map_metadata 0`

## Important Directories

```
build/windows/x64/runner/Release/    # Release executable
dist/                                # Distribution packages
coverage/                            # Test coverage reports
.github/workflows/                   # GitHub Actions
```

## Version Information

- **Flutter**: 3.0+
- **Dart SDK**: 3.0+
- **Windows**: 10 or later
- **FFmpeg**: Required (external)

## Support Resources

- Flutter Docs: https://flutter.dev/docs
- FFmpeg Docs: https://ffmpeg.org/documentation.html
- GitHub Issues: https://github.com/absolute-zer013/ffmpeg-gui-application/issues

## Common Task Workflows

### Before Committing
```bash
.\run_tests.ps1 all
git add .
git commit -m "Your message"
git push
```

### Creating a Release
```bash
# 1. Update version in pubspec.yaml
# 2. Build everything
.\build_package.ps1 all

# 3. Test the executable
.\build\windows\x64\runner\Release\export_file.exe

# 4. Commit and tag
git add .
git commit -m "Release v1.0.0"
git tag v1.0.0
git push origin master v1.0.0

# 5. GitHub Actions builds automatically
# 6. Release appears in GitHub
```

### Testing Specific Feature
```bash
# Run model tests
.\run_tests.ps1 test-models

# Add new tests in test/models/
# Run again to verify
```

### Debugging Export Issues
1. Check logs in app
2. Enable verbose FFmpeg: see FEATURES.md
3. Test file with: `ffprobe -show_streams <file>`
4. Create issue with detailed error log

---

**Last Updated**: October 22, 2025  
**Status**: All systems operational ✅

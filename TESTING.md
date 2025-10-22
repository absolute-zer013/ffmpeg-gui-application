# Testing & CI/CD Documentation

## Overview
This project includes comprehensive automated testing and a CI/CD pipeline using GitHub Actions. All code is automatically tested, linted, and built on every push and pull request.

## Local Testing

### Running Unit Tests
```bash
flutter test
```

Run only model tests:
```bash
flutter test test/models/
```

Run only utility tests:
```bash
flutter test test/utils/
```

Run with coverage:
```bash
flutter test --coverage
```

### Linting and Formatting

Check code formatting:
```bash
dart format --set-exit-if-changed .
```

Format code:
```bash
dart format .
```

Analyze code for issues:
```bash
flutter analyze
```

Run comprehensive lint checks:
```bash
dart analyze --fatal-infos
```

## Test Structure

### Model Tests
Located in `test/models/`:
- **track_test.dart** - Tests Track model with various track types (audio, video, subtitle)
- **file_item_test.dart** - Tests FileItem model with track selections and export status
- **export_profile_test.dart** - Tests ExportProfile model with language and subtitle selections

### Utility Tests
Located in `test/utils/`:
- **file_utils_test.dart** - Tests file format validation and byte formatting

### Widget Tests
Located in `test/`:
- **widget_test.dart** - Integration tests for main app functionality

### Current Test Coverage
- 23 unit tests across models and utilities
- All tests passing ✅
- Coverage reporting configured

## Continuous Integration / Continuous Deployment

### GitHub Actions Workflow

The project includes an automated CI/CD pipeline (`.github/workflows/ci-cd.yml`) with the following jobs:

#### 1. **Analyze & Lint Job**
- Runs on: Ubuntu (Linux)
- Triggers on: Push to master/develop, Pull requests
- Tasks:
  - Checks code formatting with `dart format`
  - Runs `flutter analyze` for code issues
  - Runs `dart analyze --fatal-infos` for strict linting

#### 2. **Test Job**
- Runs on: Ubuntu (Linux)
- Depends on: Analyze job (must pass first)
- Tasks:
  - Runs all unit and widget tests with coverage
  - Uploads coverage reports to Codecov
  - Generates coverage badge

#### 3. **Build Windows Job**
- Runs on: Windows (Windows Server)
- Depends on: Analyze & Test jobs (both must pass)
- Tasks:
  - Builds Windows release executable
  - Uploads build artifacts (7-day retention)
  - Creates release on version tags
  - Artifacts available for download

### Workflow Triggers

- **On Push**: Automatically runs pipeline on commits to `master` or `develop`
- **On Pull Request**: Validates all PRs before merging
- **On Tags**: Special handling for version tags (`v*`) to create releases

### Build Artifacts

After successful test and build:
- Windows executable available in GitHub Actions artifacts
- Artifacts retained for 7 days
- Automatic release creation on version tags

## Setting Up Codecov

To enable coverage reporting in GitHub:

1. Go to https://codecov.io
2. Connect your GitHub account
3. Select the repository
4. No additional setup needed - the workflow will automatically upload coverage

## Running Tests in CI Locally

To simulate the CI environment locally:

```bash
# Format check (like CI does)
dart format --set-exit-if-changed .

# Analyze code
flutter analyze

# Run tests with coverage
flutter test --coverage

# Build Windows release (requires Windows)
flutter build windows --release
```

## Adding New Tests

### Model Tests
1. Create new test file in `test/models/`
2. Follow pattern: `test/<entity>_test.dart`
3. Use descriptive test group and test names
4. Import model from `package:ffmpeg_filter_app/models/`

Example:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/your_model.dart';

void main() {
  group('YourModel', () {
    test('does something', () {
      final model = YourModel();
      expect(model.property, equals(expectedValue));
    });
  });
}
```

### Widget Tests
1. Add tests to `test/widget_test.dart`
2. Use `testWidgets` for widget tests (requires state management)
3. Mock external dependencies (file picker, process calls)

## Test Best Practices

1. **Isolated Tests**: Each test should be independent
2. **Clear Names**: Test names should describe what is being tested
3. **Single Assertion**: Each test should focus on one behavior
4. **Setup & Teardown**: Use `setUp()` and `tearDown()` for common initialization
5. **Mock External Calls**: Mock FFmpeg, file system calls in tests

## Debugging Failed Tests

### Local Test Failures
1. Run the specific test file
2. Check the error message and stack trace
3. Add debugging output with `print()` statements
4. Use `flutter test --verbose` for detailed output

### CI Failures
1. Check GitHub Actions workflow run logs
2. Download artifacts to inspect build issues
3. Replicate locally with same Dart/Flutter versions
4. Test using the exact commands in the workflow

## Performance

- Unit tests run in ~10 seconds locally
- Full CI pipeline completes in ~5-10 minutes
- Coverage analysis adds ~30 seconds

## Future Enhancements

- [ ] Integration tests for FFmpeg service
- [ ] Performance benchmarks for export operations
- [ ] E2E tests with real video files
- [ ] Automated release notes generation
- [ ] Multi-platform builds (if cross-platform support added)
- [ ] SonarQube integration for code quality

## Troubleshooting

### Tests fail locally but pass in CI
- Check Dart SDK version (`flutter --version`)
- Ensure all dependencies installed (`flutter pub get`)
- Clear build cache (`flutter clean`)

### CI build fails on Windows
- Check availability of external tools (FFmpeg)
- Verify path environment variables
- Check storage space and memory

### Coverage not uploading
- Verify Codecov token is set (if private repo)
- Check `lcov.info` exists after tests
- Verify GitHub Actions has internet access

## References
- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.io/)

# Deployment & Distribution Guide

## Overview

This guide covers building, packaging, and distributing the FFmpeg Export Tool for Windows.

## Build Process

### Prerequisites
- Flutter 3.0+ installed and configured
- Windows 10 or later
- Visual Studio Build Tools or Visual Studio Community
- FFmpeg installed (for testing)

### Step 1: Local Testing & Build

**Using PowerShell:**
```bash
.\scripts\build_package.ps1 all
```

**Using Batch:**
```bash
scripts\build_package.bat all
```

**Or manually:**
```bash
# Run all checks
.\scripts\run_tests.ps1 all

# Build release
flutter build windows --release
```

### Step 2: Verify Build

The executable is located at:
```
build\windows\x64\runner\Release\export_file.exe
```

Test locally:
1. Ensure FFmpeg is installed
2. Run: `build\windows\x64\runner\Release\export_file.exe`
3. Verify app launches and FFmpeg is detected

## Packaging for Distribution

### Create Distribution Package

**Using PowerShell:**
```bash
.\scripts\build_package.ps1 package
```

**Using Batch:**
```bash
scripts\build_package.bat package
```

### Package Contents

The generated ZIP file (`dist/FFmpegExportTool-v*.zip`) contains:

```
FFmpegExportTool-v1.0.0-release/
├── bin/
│   ├── export_file.exe              # Main application
│   ├── flutter_windows.dll          # Flutter runtime
│   ├── desktop_drop_plugin.dll      # Drag-and-drop support
│   └── local_notifier_plugin.dll    # Notifications
├── data/
│   ├── flutter_assets/              # Application assets
│   └── fonts/                       # Custom fonts
├── docs/
│   ├── README.md                    # Full documentation
│   ├── FEATURES.md                  # Feature list
│   ├── TESTING.md                   # Testing guide
│   └── CI_CD_SETUP.md               # CI/CD documentation
└── README.txt                       # Quick start guide
```

## Installation Instructions for Users

### System Requirements
- Windows 10 or later
- FFmpeg installed and in system PATH
- 100MB free disk space

### Installation Steps

1. **Install FFmpeg** (if not already installed)
   - Download from: https://ffmpeg.org/download.html
   - Extract to a folder (e.g., `C:\ffmpeg`)
   - Add to PATH:
     - Right-click "This PC" → Properties
     - Advanced system settings → Environment Variables
     - Add FFmpeg bin folder to PATH

2. **Extract Application**
   - Extract `FFmpegExportTool-v*.zip` to desired location
   - e.g., `C:\Program Files\FFmpegExportTool`

3. **Run Application**
   - Double-click `bin\export_file.exe`
   - Or create shortcut to this file

4. **Verify FFmpeg**
   - App will show FFmpeg detection status on startup
   - If not detected, ensure FFmpeg is in PATH and restart

## Release Process

### 1. Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.1+2
```

Format: `MAJOR.MINOR.PATCH+BUILD`

### 2. Create Release Locally

```bash
# Build and package everything
.\scripts\build_package.ps1 all

# Commit changes
git add .
git commit -m "Release v1.0.1"

# Create version tag
git tag v1.0.1
git push origin v1.0.1
```

### 3. GitHub Actions Automatic Build

When you push a version tag (e.g., `v1.0.1`), GitHub Actions will:
1. Run all tests
2. Build Windows executable
3. Create release with artifacts
4. Upload package ZIP

### 4. Publish Release

The GitHub Actions workflow automatically creates a release. You can then:
- Add release notes
- Upload additional artifacts
- Mark as pre-release if needed

### Manual Release Creation

```bash
# Build release locally
.\scripts\build_package.ps1 all

# Create GitHub release and upload
# 1. Go to: https://github.com/absolute-zer013/ffmpeg-gui-application/releases
# 2. Click "Create a new release"
# 3. Tag version: v1.0.1
# 4. Title: Release 1.0.1
# 5. Upload: dist/FFmpegExportTool-v*.zip
# 6. Publish
```

## Build Artifacts

### Size Information
- Main executable: ~15-20 MB
- DLLs: ~30-50 MB
- Data/Assets: ~5-10 MB
- **Total package**: ~60-80 MB

### File Structure Best Practices
- Keep executable and DLLs together in `bin/` folder
- Don't move DLLs separately
- Keep relative paths consistent
- Include all required runtime files

## Automated CI/CD

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) automatically:

**On every push to master/develop:**
- ✅ Runs all tests
- ✅ Checks code formatting
- ✅ Analyzes code for issues
- ✅ Builds Windows release
- ✅ Uploads build artifacts

**On version tags (v*):**
- ✅ Performs all above checks
- ✅ Creates release on GitHub
- ✅ Attaches executable

### Check Build Status
1. Go to: https://github.com/absolute-zer013/ffmpeg-gui-application/actions
2. Click on latest workflow run
3. View job details and logs

## Troubleshooting Distribution Issues

### App Won't Start
1. Verify FFmpeg is installed: `ffmpeg -version`
2. Check FFmpeg is in PATH
3. Ensure all DLLs are in `bin/` folder with executable
4. Check system event viewer for error details

### Missing DLLs
- Error: "The code execution cannot proceed because [DLL] was not found"
- Solution: Ensure all DLLs from build\windows\x64\runner\Release\ are copied

### Slow Performance
- Ensure FFmpeg uses stream copy (`-c copy`)
- Check CPU/disk usage during export
- Verify FFmpeg version is recent
- See FEATURES.md for performance tips

### FFmpeg Not Detected
- Verify FFmpeg installed: `ffmpeg -version` in terminal
- Add FFmpeg bin folder to system PATH
- Restart application after PATH changes
- Check Event Viewer for detailed errors

## Updating Distribution

To update version and create new release:

```bash
# 1. Update version in pubspec.yaml
# 2. Run all checks and build
.\scripts\build_package.ps1 all

# 3. Commit and tag
git add pubspec.yaml scripts/build_package.ps1
git commit -m "Prepare v1.0.2"
git tag v1.0.2
git push origin master v1.0.2

# 4. Monitor build
# Go to GitHub Actions tab
# Wait for workflow to complete
# Release will be created automatically
```

## Download Statistics

To track downloads:
1. Go to: https://github.com/absolute-zer013/ffmpeg-gui-application/releases
2. View download counts for each artifact
3. Use GitHub Analytics for detailed metrics

## Support & Bug Reports

Users can:
1. Create issue on GitHub
2. Include error logs from log viewer
3. Specify Windows version and FFmpeg version
4. Provide export settings that failed

## Future Enhancements

- [ ] Create NSIS installer (.msi)
- [ ] Add Windows app signing (Authenticode)
- [ ] Setup automatic updates
- [ ] Create portable executable variant
- [ ] Build for other platforms (macOS, Linux)
- [ ] Create user installer with registry entries
- [ ] Add crash reporting

## Summary

**Quick Release Process:**
1. Update version in `pubspec.yaml`
2. Run: `.\scripts\build_package.ps1 all`
3. Commit and create version tag
4. Push to GitHub
5. GitHub Actions builds and releases automatically

**Manual Distribution:**
1. Run: `.\scripts\build_package.ps1 all`
2. Find package in `dist/` folder
3. Share ZIP file with users
4. Users extract and run `bin\export_file.exe`

---

**Status:** Ready for production deployment! 🚀

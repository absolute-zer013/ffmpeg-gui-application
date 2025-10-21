/// Utility functions for file operations
class FileUtils {
  /// Check if a file path is a supported video format
  static bool isSupportedVideoFormat(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mkv') ||
        lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mov');
  }

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

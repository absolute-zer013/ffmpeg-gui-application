/// Model for dual pane mode configuration and state.
class DualPaneMode {
  /// Whether dual pane mode is enabled.
  final bool enabled;
  
  /// The layout orientation (horizontal or vertical).
  final DualPaneOrientation orientation;
  
  /// The position of the divider (0.0 to 1.0).
  final double dividerPosition;
  
  /// The file to display in the left/top pane (null for none).
  final String? leftPaneFilePath;
  
  /// The file to display in the right/bottom pane (null for none).
  final String? rightPaneFilePath;
  
  /// Whether to show differences view.
  final bool showDifferences;

  const DualPaneMode({
    this.enabled = false,
    this.orientation = DualPaneOrientation.horizontal,
    this.dividerPosition = 0.5,
    this.leftPaneFilePath,
    this.rightPaneFilePath,
    this.showDifferences = false,
  });

  DualPaneMode copyWith({
    bool? enabled,
    DualPaneOrientation? orientation,
    double? dividerPosition,
    String? leftPaneFilePath,
    String? rightPaneFilePath,
    bool? showDifferences,
  }) {
    return DualPaneMode(
      enabled: enabled ?? this.enabled,
      orientation: orientation ?? this.orientation,
      dividerPosition: dividerPosition ?? this.dividerPosition,
      leftPaneFilePath: leftPaneFilePath ?? this.leftPaneFilePath,
      rightPaneFilePath: rightPaneFilePath ?? this.rightPaneFilePath,
      showDifferences: showDifferences ?? this.showDifferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'orientation': orientation.toString().split('.').last,
      'dividerPosition': dividerPosition,
      'leftPaneFilePath': leftPaneFilePath,
      'rightPaneFilePath': rightPaneFilePath,
      'showDifferences': showDifferences,
    };
  }

  factory DualPaneMode.fromJson(Map<String, dynamic> json) {
    return DualPaneMode(
      enabled: json['enabled'] as bool? ?? false,
      orientation: DualPaneOrientation.values.firstWhere(
        (e) => e.toString().split('.').last == json['orientation'],
        orElse: () => DualPaneOrientation.horizontal,
      ),
      dividerPosition: (json['dividerPosition'] as num?)?.toDouble() ?? 0.5,
      leftPaneFilePath: json['leftPaneFilePath'] as String?,
      rightPaneFilePath: json['rightPaneFilePath'] as String?,
      showDifferences: json['showDifferences'] as bool? ?? false,
    );
  }
}

/// Orientation for dual pane layout.
enum DualPaneOrientation {
  /// Horizontal layout (left and right panes).
  horizontal,
  
  /// Vertical layout (top and bottom panes).
  vertical,
}

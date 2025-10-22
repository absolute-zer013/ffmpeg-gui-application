/// Data model representing an auto-detection rule for automatic track selection
class AutoDetectRule {
  final String id;
  final String name;
  final String description;
  final RuleType type;
  final RuleCondition condition;
  final String? conditionValue;
  final RuleAction action;
  final String? actionValue;
  final int priority;
  final bool enabled;
  final DateTime createdAt;
  final DateTime modifiedAt;

  AutoDetectRule({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.condition,
    this.conditionValue,
    required this.action,
    this.actionValue,
    this.priority = 0,
    this.enabled = true,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create rule from JSON
  factory AutoDetectRule.fromJson(Map<String, dynamic> json) {
    return AutoDetectRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: RuleType.values.firstWhere(
        (e) => e.toString() == 'RuleType.${json['type']}',
        orElse: () => RuleType.audio,
      ),
      condition: RuleCondition.values.firstWhere(
        (e) => e.toString() == 'RuleCondition.${json['condition']}',
        orElse: () => RuleCondition.languageEquals,
      ),
      conditionValue: json['conditionValue'] as String?,
      action: RuleAction.values.firstWhere(
        (e) => e.toString() == 'RuleAction.${json['action']}',
        orElse: () => RuleAction.select,
      ),
      actionValue: json['actionValue'] as String?,
      priority: json['priority'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }

  /// Convert rule to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'condition': condition.toString().split('.').last,
      'conditionValue': conditionValue,
      'action': action.toString().split('.').last,
      'actionValue': actionValue,
      'priority': priority,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  AutoDetectRule copyWith({
    String? id,
    String? name,
    String? description,
    RuleType? type,
    RuleCondition? condition,
    String? conditionValue,
    RuleAction? action,
    String? actionValue,
    int? priority,
    bool? enabled,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return AutoDetectRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      condition: condition ?? this.condition,
      conditionValue: conditionValue ?? this.conditionValue,
      action: action ?? this.action,
      actionValue: actionValue ?? this.actionValue,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Get predefined example rules
  static List<AutoDetectRule> getPredefinedRules() {
    return [
      AutoDetectRule(
        id: 'rule_japanese_audio',
        name: 'Select Japanese Audio',
        description: 'Automatically select all Japanese audio tracks',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        conditionValue: 'jpn',
        action: RuleAction.select,
        priority: 10,
      ),
      AutoDetectRule(
        id: 'rule_english_audio',
        name: 'Select English Audio',
        description: 'Automatically select all English audio tracks',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        conditionValue: 'eng',
        action: RuleAction.select,
        priority: 5,
      ),
      AutoDetectRule(
        id: 'rule_remove_commentary',
        name: 'Remove Commentary',
        description: 'Remove audio tracks with commentary in the title',
        type: RuleType.audio,
        condition: RuleCondition.titleContains,
        conditionValue: 'commentary',
        action: RuleAction.deselect,
        priority: 20,
      ),
      AutoDetectRule(
        id: 'rule_full_subtitles',
        name: 'Select Full Subtitles',
        description: 'Select subtitles with "Full" in title',
        type: RuleType.subtitle,
        condition: RuleCondition.titleContains,
        conditionValue: 'Full',
        action: RuleAction.select,
        priority: 10,
      ),
      AutoDetectRule(
        id: 'rule_forced_subtitles',
        name: 'Select Forced Subtitles',
        description: 'Select forced subtitle tracks',
        type: RuleType.subtitle,
        condition: RuleCondition.titleContains,
        conditionValue: 'Forced',
        action: RuleAction.select,
        priority: 15,
      ),
    ];
  }
}

/// Type of track this rule applies to
enum RuleType {
  audio,
  subtitle,
  video,
}

/// Condition to match against tracks
enum RuleCondition {
  languageEquals,
  languageContains,
  titleEquals,
  titleContains,
  codecEquals,
  codecContains,
  channelsEquals,
  channelsGreaterThan,
}

/// Action to take when rule matches
enum RuleAction {
  select,
  deselect,
  setDefault,
}

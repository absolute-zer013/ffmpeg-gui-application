import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auto_detect_rule.dart';
import '../models/file_item.dart';
import '../models/track.dart';

/// Service for managing and applying auto-detect rules
class RuleService {
  static const String _rulesKey = 'auto_detect_rules';

  /// Load all saved rules
  static Future<List<AutoDetectRule>> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getString(_rulesKey);

    if (rulesJson == null || rulesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(rulesJson);
      return decoded.map((ruleJson) => AutoDetectRule.fromJson(ruleJson)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a rule
  static Future<void> saveRule(AutoDetectRule rule) async {
    final rules = await loadRules();

    // Check if rule with same ID exists
    final existingIndex = rules.indexWhere((r) => r.id == rule.id);

    if (existingIndex != -1) {
      // Update existing rule
      rules[existingIndex] = rule.copyWith(modifiedAt: DateTime.now());
    } else {
      // Add new rule
      rules.add(rule);
    }

    // Sort by priority (higher priority first)
    rules.sort((a, b) => b.priority.compareTo(a.priority));

    await _saveRules(rules);
  }

  /// Delete a rule by ID
  static Future<void> deleteRule(String ruleId) async {
    final rules = await loadRules();
    rules.removeWhere((r) => r.id == ruleId);
    await _saveRules(rules);
  }

  /// Get a specific rule by ID
  static Future<AutoDetectRule?> getRule(String ruleId) async {
    final rules = await loadRules();
    try {
      return rules.firstWhere((r) => r.id == ruleId);
    } catch (e) {
      return null;
    }
  }

  /// Save all rules to SharedPreferences
  static Future<void> _saveRules(List<AutoDetectRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = json.encode(rules.map((r) => r.toJson()).toList());
    await prefs.setString(_rulesKey, rulesJson);
  }

  /// Generate a unique ID for a new rule
  static String generateRuleId() {
    return 'rule_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Apply rules to a file item to automatically select tracks
  static void applyRules(FileItem file, List<AutoDetectRule> rules) {
    // Filter enabled rules and sort by priority
    final enabledRules = rules.where((r) => r.enabled).toList();
    enabledRules.sort((a, b) => b.priority.compareTo(a.priority));

    // Apply rules in priority order
    for (final rule in enabledRules) {
      switch (rule.type) {
        case RuleType.audio:
          _applyRuleToTracks(file.audioTracks, rule, (index, action) {
            if (action == RuleAction.select) {
              file.selectedAudio.add(index);
            } else if (action == RuleAction.deselect) {
              file.selectedAudio.remove(index);
            } else if (action == RuleAction.setDefault) {
              file.defaultAudio = index;
            }
          });
          break;
        case RuleType.subtitle:
          _applyRuleToTracks(file.subtitleTracks, rule, (index, action) {
            if (action == RuleAction.select) {
              file.selectedSubtitles.add(index);
            } else if (action == RuleAction.deselect) {
              file.selectedSubtitles.remove(index);
            } else if (action == RuleAction.setDefault) {
              file.defaultSubtitle = index;
            }
          });
          break;
        case RuleType.video:
          _applyRuleToTracks(file.videoTracks, rule, (index, action) {
            if (action == RuleAction.select) {
              file.selectedVideo.add(index);
            } else if (action == RuleAction.deselect) {
              file.selectedVideo.remove(index);
            } else if (action == RuleAction.setDefault) {
              file.defaultVideo = index;
            }
          });
          break;
      }
    }
  }

  /// Apply a rule to a list of tracks
  static void _applyRuleToTracks(
    List<Track> tracks,
    AutoDetectRule rule,
    void Function(int index, RuleAction action) callback,
  ) {
    for (final track in tracks) {
      if (_matchesCondition(track, rule.condition, rule.conditionValue)) {
        callback(track.streamIndex, rule.action);
      }
    }
  }

  /// Check if a track matches a rule condition
  static bool _matchesCondition(
    Track track,
    RuleCondition condition,
    String? conditionValue,
  ) {
    if (conditionValue == null) return false;

    switch (condition) {
      case RuleCondition.languageEquals:
        return track.language?.toLowerCase() == conditionValue.toLowerCase();

      case RuleCondition.languageContains:
        return track.language
                ?.toLowerCase()
                .contains(conditionValue.toLowerCase()) ??
            false;

      case RuleCondition.titleEquals:
        return track.title?.toLowerCase() == conditionValue.toLowerCase();

      case RuleCondition.titleContains:
        return track.title
                ?.toLowerCase()
                .contains(conditionValue.toLowerCase()) ??
            false;

      case RuleCondition.codecEquals:
        return track.codec?.toLowerCase() == conditionValue.toLowerCase();

      case RuleCondition.codecContains:
        return track.codec
                ?.toLowerCase()
                .contains(conditionValue.toLowerCase()) ??
            false;

      case RuleCondition.channelsEquals:
        final targetChannels = int.tryParse(conditionValue);
        return targetChannels != null && track.channels == targetChannels;

      case RuleCondition.channelsGreaterThan:
        final targetChannels = int.tryParse(conditionValue);
        return targetChannels != null &&
            track.channels != null &&
            track.channels! > targetChannels;
    }
  }

  /// Get a summary of what rules would do to a file
  static String getRuleSummary(FileItem file, List<AutoDetectRule> rules) {
    final enabledRules = rules.where((r) => r.enabled).toList();
    if (enabledRules.isEmpty) {
      return 'No rules enabled';
    }

    int audioMatches = 0;
    int subtitleMatches = 0;
    int videoMatches = 0;

    for (final rule in enabledRules) {
      switch (rule.type) {
        case RuleType.audio:
          audioMatches += file.audioTracks
              .where((t) => _matchesCondition(t, rule.condition, rule.conditionValue))
              .length;
          break;
        case RuleType.subtitle:
          subtitleMatches += file.subtitleTracks
              .where((t) => _matchesCondition(t, rule.condition, rule.conditionValue))
              .length;
          break;
        case RuleType.video:
          videoMatches += file.videoTracks
              .where((t) => _matchesCondition(t, rule.condition, rule.conditionValue))
              .length;
          break;
      }
    }

    final parts = <String>[];
    if (audioMatches > 0) parts.add('$audioMatches audio');
    if (subtitleMatches > 0) parts.add('$subtitleMatches subtitle');
    if (videoMatches > 0) parts.add('$videoMatches video');

    if (parts.isEmpty) {
      return 'No matching tracks';
    }

    return 'Would affect: ${parts.join(', ')} tracks';
  }
}

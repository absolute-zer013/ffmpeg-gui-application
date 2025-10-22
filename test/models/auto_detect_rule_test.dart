import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/auto_detect_rule.dart';

void main() {
  group('AutoDetectRule Model', () {
    test('AutoDetectRule creation with all fields', () {
      final rule = AutoDetectRule(
        id: 'rule_1',
        name: 'Japanese Audio',
        description: 'Select Japanese audio tracks',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        conditionValue: 'jpn',
        action: RuleAction.select,
        priority: 10,
        enabled: true,
      );

      expect(rule.id, equals('rule_1'));
      expect(rule.name, equals('Japanese Audio'));
      expect(rule.description, equals('Select Japanese audio tracks'));
      expect(rule.type, equals(RuleType.audio));
      expect(rule.condition, equals(RuleCondition.languageEquals));
      expect(rule.conditionValue, equals('jpn'));
      expect(rule.action, equals(RuleAction.select));
      expect(rule.priority, equals(10));
      expect(rule.enabled, isTrue);
    });

    test('AutoDetectRule with default values', () {
      final rule = AutoDetectRule(
        id: 'rule_2',
        name: 'Simple Rule',
        type: RuleType.subtitle,
        condition: RuleCondition.titleContains,
        action: RuleAction.select,
      );

      expect(rule.description, isEmpty);
      expect(rule.priority, equals(0));
      expect(rule.enabled, isTrue);
    });

    test('AutoDetectRule toJson/fromJson roundtrip', () {
      final original = AutoDetectRule(
        id: 'rule_3',
        name: 'Test Rule',
        description: 'Test description',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        conditionValue: 'eng',
        action: RuleAction.select,
        priority: 5,
        enabled: false,
      );

      final json = original.toJson();
      final decoded = AutoDetectRule.fromJson(json);

      expect(decoded.id, equals(original.id));
      expect(decoded.name, equals(original.name));
      expect(decoded.description, equals(original.description));
      expect(decoded.type, equals(original.type));
      expect(decoded.condition, equals(original.condition));
      expect(decoded.conditionValue, equals(original.conditionValue));
      expect(decoded.action, equals(original.action));
      expect(decoded.priority, equals(original.priority));
      expect(decoded.enabled, equals(original.enabled));
    });

    test('AutoDetectRule copyWith creates modified copy', () {
      final original = AutoDetectRule(
        id: 'rule_4',
        name: 'Original',
        type: RuleType.audio,
        condition: RuleCondition.languageEquals,
        action: RuleAction.select,
        priority: 1,
      );

      final modified = original.copyWith(
        name: 'Modified',
        priority: 10,
        enabled: false,
      );

      expect(modified.name, equals('Modified'));
      expect(modified.priority, equals(10));
      expect(modified.enabled, isFalse);
      expect(modified.id, equals(original.id));
      expect(modified.type, equals(original.type));
    });

    test('getPredefinedRules returns list of rules', () {
      final rules = AutoDetectRule.getPredefinedRules();

      expect(rules, isNotEmpty);
      expect(rules.length, greaterThanOrEqualTo(3));

      // Check all rules have required fields
      for (final rule in rules) {
        expect(rule.id, isNotEmpty);
        expect(rule.name, isNotEmpty);
        expect(rule.enabled, isTrue);
      }
    });

    test('predefined rules include Japanese audio', () {
      final rules = AutoDetectRule.getPredefinedRules();
      final japaneseRule = rules.firstWhere(
        (r) => r.conditionValue == 'jpn',
        orElse: () => rules.first,
      );

      expect(japaneseRule.type, equals(RuleType.audio));
      expect(japaneseRule.condition, equals(RuleCondition.languageEquals));
    });

    test('predefined rules include English audio', () {
      final rules = AutoDetectRule.getPredefinedRules();
      final englishRule = rules.firstWhere(
        (r) => r.conditionValue == 'eng',
        orElse: () => rules.first,
      );

      expect(englishRule.type, equals(RuleType.audio));
      expect(englishRule.condition, equals(RuleCondition.languageEquals));
    });

    test('predefined rules have different priorities', () {
      final rules = AutoDetectRule.getPredefinedRules();
      final priorities = rules.map((r) => r.priority).toSet();

      // Should have multiple priority levels
      expect(priorities.length, greaterThan(1));
    });

    test('RuleType enum has expected values', () {
      expect(RuleType.values, contains(RuleType.audio));
      expect(RuleType.values, contains(RuleType.subtitle));
      expect(RuleType.values, contains(RuleType.video));
    });

    test('RuleCondition enum has language conditions', () {
      expect(RuleCondition.values, contains(RuleCondition.languageEquals));
      expect(RuleCondition.values, contains(RuleCondition.languageContains));
    });

    test('RuleCondition enum has title conditions', () {
      expect(RuleCondition.values, contains(RuleCondition.titleEquals));
      expect(RuleCondition.values, contains(RuleCondition.titleContains));
    });

    test('RuleAction enum has expected values', () {
      expect(RuleAction.values, contains(RuleAction.select));
      expect(RuleAction.values, contains(RuleAction.deselect));
      expect(RuleAction.values, contains(RuleAction.setDefault));
    });
  });
}

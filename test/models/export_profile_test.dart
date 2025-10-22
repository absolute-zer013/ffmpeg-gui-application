import 'package:flutter_test/flutter_test.dart';
import 'package:ffmpeg_filter_app/models/export_profile.dart';

void main() {
  group('ExportProfile Model', () {
    test('ExportProfile creation with all fields', () {
      final profile = ExportProfile(
        id: 'profile_1',
        name: 'Japanese Only',
        description: 'Keep only Japanese audio',
        selectedAudioLanguages: {'ja'},
        selectedSubtitleDescriptions: {'Japanese'},
        defaultSubtitleDescription: 'Japanese',
      );

      expect(profile.id, equals('profile_1'));
      expect(profile.name, equals('Japanese Only'));
      expect(profile.description, equals('Keep only Japanese audio'));
      expect(profile.selectedAudioLanguages, contains('ja'));
      expect(profile.selectedSubtitleDescriptions, contains('Japanese'));
      expect(profile.defaultSubtitleDescription, equals('Japanese'));
    });

    test('ExportProfile with multiple languages', () {
      final profile = ExportProfile(
        id: 'profile_2',
        name: 'Multi Language',
        description: '',
        selectedAudioLanguages: {'en', 'ja', 'es'},
        selectedSubtitleDescriptions: {'English', 'Japanese', 'Spanish'},
        defaultSubtitleDescription: 'English',
      );

      expect(profile.selectedAudioLanguages.length, equals(3));
      expect(profile.selectedSubtitleDescriptions.length, equals(3));
      expect(profile.selectedAudioLanguages, contains('en'));
      expect(profile.selectedAudioLanguages, contains('ja'));
      expect(profile.selectedAudioLanguages, contains('es'));
    });

    test('ExportProfile with empty selections', () {
      final profile = ExportProfile(
        id: 'profile_3',
        name: 'Empty Profile',
        description: 'Test empty',
        selectedAudioLanguages: {},
        selectedSubtitleDescriptions: {},
      );

      expect(profile.selectedAudioLanguages.isEmpty, isTrue);
      expect(profile.selectedSubtitleDescriptions.isEmpty, isTrue);
      expect(profile.defaultSubtitleDescription, isNull);
    });

    test('ExportProfile can identify duplicate IDs', () {
      final profile1 = ExportProfile(
        id: 'same_id',
        name: 'Profile 1',
        description: '',
        selectedAudioLanguages: {'en'},
        selectedSubtitleDescriptions: {},
      );

      final profile2 = ExportProfile(
        id: 'same_id',
        name: 'Profile 2',
        description: '',
        selectedAudioLanguages: {'ja'},
        selectedSubtitleDescriptions: {},
      );

      expect(profile1.id, equals(profile2.id));
      expect(profile1.name, isNot(equals(profile2.name)));
    });
  });
}

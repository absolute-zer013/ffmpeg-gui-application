import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/export_profile.dart';

/// Service for managing export profiles
class ProfileService {
  static const String _profilesKey = 'export_profiles';

  /// Load all saved profiles
  static Future<List<ExportProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);

    if (profilesJson == null || profilesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(profilesJson);
      return decoded
          .map((profileJson) => ExportProfile.fromJson(profileJson))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Save a profile
  static Future<void> saveProfile(ExportProfile profile) async {
    final profiles = await loadProfiles();

    // Check if profile with same ID exists
    final existingIndex = profiles.indexWhere((p) => p.id == profile.id);

    if (existingIndex != -1) {
      // Update existing profile
      profiles[existingIndex] = profile.copyWith(modifiedAt: DateTime.now());
    } else {
      // Add new profile
      profiles.add(profile);
    }

    await _saveProfiles(profiles);
  }

  /// Delete a profile by ID
  static Future<void> deleteProfile(String profileId) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    await _saveProfiles(profiles);
  }

  /// Get a specific profile by ID
  static Future<ExportProfile?> getProfile(String profileId) async {
    final profiles = await loadProfiles();
    try {
      return profiles.firstWhere((p) => p.id == profileId);
    } catch (e) {
      return null;
    }
  }

  /// Save all profiles to SharedPreferences
  static Future<void> _saveProfiles(List<ExportProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, profilesJson);
  }

  /// Generate a unique ID for a new profile
  static String generateProfileId() {
    return 'profile_${DateTime.now().millisecondsSinceEpoch}';
  }
}

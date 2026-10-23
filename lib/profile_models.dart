import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing parent/guardian settings and information
class ParentProfile {
  String name;
  String email;
  String language;
  bool soundEnabled;
  bool musicEnabled;

  ParentProfile({
    this.name = 'Sarah',
    this.email = 'parent@example.com',
    this.language = 'English',
    this.soundEnabled = true,
    this.musicEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'language': language,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
      };

  factory ParentProfile.fromJson(Map<String, dynamic> json) => ParentProfile(
        name: json['name'] as String? ?? 'Sarah',
        email: json['email'] as String? ?? 'parent@example.com',
        language: json['language'] as String? ?? 'English',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? true,
      );
}

/// Model representing the child's learning profile
class BabyProfile {
  String nickname;
  int age;
  String
      avatarName; // e.g. 'Teddy', 'Duckling', 'Kitten', 'Bunny', 'Puppy', 'Lion', 'Dolphin'
  String language;
  List<String> preferences;

  BabyProfile({
    this.nickname = 'Emma',
    this.age = 4,
    this.avatarName = 'Teddy',
    this.language = 'English',
    List<String>? preferences,
  }) : preferences = preferences ??
            [
              'Phonics & Letters',
              'Numbers & Math',
              'Colors & Art',
              'Puzzles & Games',
            ];

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'age': age,
        'avatarName': avatarName,
        'language': language,
        'preferences': preferences,
      };

  factory BabyProfile.fromJson(Map<String, dynamic> json) => BabyProfile(
        nickname: json['nickname'] as String? ?? 'Emma',
        age: json['age'] as int? ?? 4,
        avatarName: json['avatarName'] as String? ?? 'Teddy',
        language: json['language'] as String? ?? 'English',
        preferences: (json['preferences'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [
              'Phonics & Letters',
              'Numbers & Math',
              'Colors & Art',
              'Puzzles & Games',
            ],
      );
}

/// Repository to persist and retrieve parent and baby information safely
class ProfileRepository {
  static const _parentKey = 'teddy_parent_profile_v1';
  static const _babyKey = 'teddy_baby_profile_v1';

  static Future<ParentProfile> loadParentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_parentKey);
      if (str != null && str.isNotEmpty) {
        return ParentProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading parent profile: $e');
    }
    return ParentProfile();
  }

  static Future<bool> saveParentProfile(ParentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_parentKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Error saving parent profile: $e');
      return false;
    }
  }

  static Future<BabyProfile> loadBabyProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_babyKey);
      if (str != null && str.isNotEmpty) {
        return BabyProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
      // Also fallback to childAge if stored in old format
      final oldAge = prefs.getInt('childAge');
      if (oldAge != null) {
        return BabyProfile(age: oldAge);
      }
    } catch (e) {
      debugPrint('Error loading baby profile: $e');
    }
    return BabyProfile();
  }

  static Future<bool> saveBabyProfile(BabyProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep childAge in sync for backward compatibility
      await prefs.setInt('childAge', profile.age);
      return await prefs.setString(_babyKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Error saving baby profile: $e');
      return false;
    }
  }
}

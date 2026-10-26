import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model representing parent/guardian settings and information
class ParentProfile {
  String name;
  String email;
  String phone;
  String relationship;
  String language;
  bool notificationsEnabled;
  bool soundEnabled;
  bool musicEnabled;
  bool welcomeGreetingEnabled;
  bool screenTimeLimitEnabled;
  int screenTimeLimitMinutes;
  bool contentLockEnabled;

  ParentProfile({
    this.name = 'Sarah Johnson',
    this.email = 'parent@example.com',
    this.phone = '+1 (555) 234-5678',
    this.relationship = 'Mother',
    this.language = 'English',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.welcomeGreetingEnabled = true,
    this.screenTimeLimitEnabled = true,
    this.screenTimeLimitMinutes = 30,
    this.contentLockEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'relationship': relationship,
        'language': language,
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'musicEnabled': musicEnabled,
        'welcomeGreetingEnabled': welcomeGreetingEnabled,
        'screenTimeLimitEnabled': screenTimeLimitEnabled,
        'screenTimeLimitMinutes': screenTimeLimitMinutes,
        'contentLockEnabled': contentLockEnabled,
      };

  factory ParentProfile.fromJson(Map<String, dynamic> json) => ParentProfile(
        name: json['name'] as String? ?? 'Sarah Johnson',
        email: json['email'] as String? ?? 'parent@example.com',
        phone: json['phone'] as String? ?? '+1 (555) 234-5678',
        relationship: json['relationship'] as String? ?? 'Mother',
        language: json['language'] as String? ?? 'English',
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        musicEnabled: json['musicEnabled'] as bool? ?? true,
        welcomeGreetingEnabled: json['welcomeGreetingEnabled'] as bool? ?? true,
        screenTimeLimitEnabled: json['screenTimeLimitEnabled'] as bool? ?? true,
        screenTimeLimitMinutes: json['screenTimeLimitMinutes'] as int? ?? 30,
        contentLockEnabled: json['contentLockEnabled'] as bool? ?? true,
      );
  ParentProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? relationship,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? welcomeGreetingEnabled,
    bool? screenTimeLimitEnabled,
    int? screenTimeLimitMinutes,
    bool? contentLockEnabled,
  }) =>
      ParentProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
        language: language ?? this.language,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        welcomeGreetingEnabled:
            welcomeGreetingEnabled ?? this.welcomeGreetingEnabled,
        screenTimeLimitEnabled:
            screenTimeLimitEnabled ?? this.screenTimeLimitEnabled,
        screenTimeLimitMinutes:
            screenTimeLimitMinutes ?? this.screenTimeLimitMinutes,
        contentLockEnabled: contentLockEnabled ?? this.contentLockEnabled,
      );
}

/// Model representing the child's learning profile
class BabyProfile {
  String fullName;
  String nickname;
  DateTime dateOfBirth;
  int age;
  String gender; // 'Boy', 'Girl', 'Prefer not to say'
  String
      avatarName; // e.g. 'Teddy', 'Duckling', 'Kitten', 'Bunny', 'Puppy', 'Lion', 'Dolphin', 'Koala', 'Panda'
  String language;
  List<String> favoriteAnimals;
  List<String> favoriteColors;
  List<String> favoriteActivities;
  List<String> preferences; // General learning subjects

  BabyProfile({
    this.fullName = 'Emma Rose',
    this.nickname = 'Emma',
    DateTime? dateOfBirth,
    int? age,
    this.gender = 'Girl',
    this.avatarName = 'Teddy',
    this.language = 'English',
    List<String>? favoriteAnimals,
    List<String>? favoriteColors,
    List<String>? favoriteActivities,
    List<String>? preferences,
  })  : dateOfBirth = dateOfBirth ?? DateTime(2022, 4, 15),
        age = age ?? 4,
        favoriteAnimals = favoriteAnimals ?? ['Teddy Bear', 'Bunny', 'Kitten'],
        favoriteColors =
            favoriteColors ?? ['Pastel Pink', 'Sky Blue', 'Mint Green'],
        favoriteActivities = favoriteActivities ??
            ['Alphabet Rhymes', 'Coloring Butterfly', 'Music & Dance'],
        preferences = preferences ??
            [
              'Phonics & Letters',
              'Numbers & Math',
              'Colors & Art',
              'Puzzles & Games',
            ];

  BabyProfile copyWith({
    String? fullName,
    String? nickname,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? avatarName,
    String? language,
    List<String>? favoriteAnimals,
    List<String>? favoriteColors,
    List<String>? favoriteActivities,
    List<String>? preferences,
  }) =>
      BabyProfile(
        fullName: fullName ?? this.fullName,
        nickname: nickname ?? this.nickname,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        avatarName: avatarName ?? this.avatarName,
        language: language ?? this.language,
        favoriteAnimals: favoriteAnimals ?? List.from(this.favoriteAnimals),
        favoriteColors: favoriteColors ?? List.from(this.favoriteColors),
        favoriteActivities:
            favoriteActivities ?? List.from(this.favoriteActivities),
        preferences: preferences ?? List.from(this.preferences),
      );

  /// Calculate age accurately from date of birth
  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int calculated = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      calculated--;
    }
    return calculated.clamp(1, 10);
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'nickname': nickname,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'age': age,
        'gender': gender,
        'avatarName': avatarName,
        'language': language,
        'favoriteAnimals': favoriteAnimals,
        'favoriteColors': favoriteColors,
        'favoriteActivities': favoriteActivities,
        'preferences': preferences,
      };

  factory BabyProfile.fromJson(Map<String, dynamic> json) {
    DateTime parsedDob;
    try {
      parsedDob = json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : DateTime(2022, 4, 15);
    } catch (_) {
      parsedDob = DateTime(2022, 4, 15);
    }

    final rawAge = json['age'] as int?;
    final computedAge = calculateAge(parsedDob);
    final finalAge = rawAge ?? computedAge;

    return BabyProfile(
      fullName: json['fullName'] as String? ?? 'Emma Rose',
      nickname: json['nickname'] as String? ?? 'Emma',
      dateOfBirth: parsedDob,
      age: finalAge,
      gender: json['gender'] as String? ?? 'Girl',
      avatarName: json['avatarName'] as String? ?? 'Teddy',
      language: json['language'] as String? ?? 'English',
      favoriteAnimals: (json['favoriteAnimals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Teddy Bear', 'Bunny', 'Kitten'],
      favoriteColors: (json['favoriteColors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Pastel Pink', 'Sky Blue', 'Mint Green'],
      favoriteActivities: (json['favoriteActivities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Alphabet Rhymes', 'Coloring Butterfly', 'Music & Dance'],
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
}

/// Repository to persist and retrieve parent and baby information safely
class ProfileRepository {
  static const _parentKey = 'teddy_parent_profile_v1';
  static const _babyKey = 'teddy_baby_profile_v1';

  static Future<ParentProfile> loadParentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_parentKey);
      ParentProfile profile;
      if (str != null && str.isNotEmpty) {
        profile =
            ParentProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
      } else {
        profile = ParentProfile();
      }

      // Keep individual AudioVoiceService preferences synchronized
      final sound = prefs.getBool('parent_sound_enabled');
      if (sound != null) profile.soundEnabled = sound;

      final music = prefs.getBool('parent_music_enabled');
      if (music != null) profile.musicEnabled = music;

      final welcome = prefs.getBool('parent_welcome_greeting_enabled');
      if (welcome != null) profile.welcomeGreetingEnabled = welcome;

      return profile;
    } catch (e) {
      debugPrint('Error loading parent profile: $e');
    }
    return ParentProfile();
  }

  static Future<bool> saveParentProfile(ParentProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep individual keys synchronized for AudioVoiceService
      await prefs.setBool('parent_sound_enabled', profile.soundEnabled);
      await prefs.setBool('parent_music_enabled', profile.musicEnabled);
      await prefs.setBool(
          'parent_welcome_greeting_enabled', profile.welcomeGreetingEnabled);
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

  static const _onboardingCompletedKey = 'teddy_onboarding_completed_v1';
  static const _onboardingStepKey = 'teddy_onboarding_step_v1';

  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding completion: $e');
      return false;
    }
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, completed);
      // Synchronize legacy 'started' flag for backward compatibility
      await prefs.setBool('started', completed);
    } catch (e) {
      debugPrint('Error saving onboarding completed: $e');
    }
  }

  static Future<int> getOnboardingStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_onboardingStepKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> setOnboardingStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_onboardingStepKey, step);
    } catch (e) {
      debugPrint('Error setting onboarding step: $e');
    }
  }
}

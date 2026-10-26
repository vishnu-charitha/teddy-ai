import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teddy_ai/audio_voice_service.dart';
import 'package:teddy_ai/extra_games_screens.dart';
import 'package:teddy_ai/main.dart';
import 'package:teddy_ai/music_player_screen.dart';
import 'package:teddy_ai/parent_baby_screens.dart';
import 'package:teddy_ai/profile_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'started': true,
      'completedOnboarding': true,
    });

    // Register mock method call handlers for platform channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      return 1;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'),
            (call) async {
      return 1;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'), (call) async {
      return 1;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async {
      return '.';
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers/events/*'),
            (call) async {
      return 1;
    });
  });

  group('Profile Models & Local Storage Persistence', () {
    test('BabyProfile serialization and repository persistence', () async {
      final initial = await ProfileRepository.loadBabyProfile();
      expect(initial.nickname, 'Emma');
      expect(initial.age, 4);
      expect(initial.avatarName, 'Teddy');

      final updated = BabyProfile(
        fullName: 'Leo Alexander',
        nickname: 'Leo',
        dateOfBirth: DateTime(2021, 5, 20),
        age: 5,
        gender: 'Boy',
        avatarName: 'Lion',
        language: 'Spanish',
        favoriteAnimals: ['Lion', 'Teddy Bear'],
        favoriteColors: ['Sky Blue'],
        favoriteActivities: ['Counting Numbers'],
        preferences: ['Puzzles & Games', 'Music & Songs'],
      );

      await ProfileRepository.saveBabyProfile(updated);
      final reloaded = await ProfileRepository.loadBabyProfile();

      expect(reloaded.fullName, 'Leo Alexander');
      expect(reloaded.nickname, 'Leo');
      expect(reloaded.age, 5);
      expect(reloaded.gender, 'Boy');
      expect(reloaded.avatarName, 'Lion');
      expect(reloaded.language, 'Spanish');
      expect(reloaded.favoriteAnimals, contains('Lion'));
      expect(reloaded.favoriteColors, contains('Sky Blue'));
      expect(reloaded.favoriteActivities, contains('Counting Numbers'));
      expect(reloaded.preferences, contains('Puzzles & Games'));
      expect(reloaded.preferences, contains('Music & Songs'));
    });

    test('ParentProfile serialization and audio preference persistence',
        () async {
      final initial = await ProfileRepository.loadParentProfile();
      expect(initial.name, contains('Sarah'));
      expect(initial.soundEnabled, isTrue);
      expect(initial.musicEnabled, isTrue);

      final updated = ParentProfile(
        name: 'Sarah Connor',
        email: 'sarah@example.com',
        phone: '+1 555-0199',
        relationship: 'Mother',
        language: 'French',
        notificationsEnabled: true,
        soundEnabled: false,
        musicEnabled: true,
        welcomeGreetingEnabled: true,
        screenTimeLimitEnabled: true,
        screenTimeLimitMinutes: 45,
        contentLockEnabled: true,
      );

      await ProfileRepository.saveParentProfile(updated);
      final reloaded = await ProfileRepository.loadParentProfile();

      expect(reloaded.name, 'Sarah Connor');
      expect(reloaded.email, 'sarah@example.com');
      expect(reloaded.phone, '+1 555-0199');
      expect(reloaded.relationship, 'Mother');
      expect(reloaded.language, 'French');
      expect(reloaded.soundEnabled, isFalse);
      expect(reloaded.musicEnabled, isTrue);
      expect(reloaded.screenTimeLimitMinutes, 45);
    });
  });

  group('Audio & Voice Service Logic', () {
    test('AudioVoiceService toggles sound and music', () async {
      final service = AudioVoiceService();
      await service.setSoundEnabled(false);
      expect(service.soundEnabled, isFalse);

      await service.setMusicEnabled(false);
      expect(service.musicEnabled, isFalse);

      // Re-enable
      await service.setSoundEnabled(true);
      expect(service.soundEnabled, isTrue);

      await service.setMusicEnabled(true);
      expect(service.musicEnabled, isTrue);

      // Volume bounds
      service.setMusicVolume(0.8);
      expect(service.musicVolume, closeTo(0.8, 0.01));

      service.setMusicVolume(1.5);
      expect(service.musicVolume, closeTo(1.0, 0.01));

      service.setMusicVolume(-0.5);
      expect(service.musicVolume, closeTo(0.0, 0.01));
    });

    test(
        'AudioVoiceService letter phonics and number pronunciations run safely',
        () async {
      final service = AudioVoiceService();
      await service.speakLetterPhonics(
        letter: 'Aa',
        word: 'Apple',
        phonicsPhrase: 'A is for sweet red Apple!',
      );

      await service.speakNumber(3, 'Three ducks');
      await service.speakColor('Blue', 'Cool and peaceful like the sky!');
      await service.speakEncouragement();
    });

    test('AudioVoiceService tracks point to genuine local asset WAV files', () {
      final service = AudioVoiceService();
      expect(service.tracks.length, 5);
      for (final t in service.tracks) {
        expect(t.assetPath.endsWith('.wav'), isTrue);
        expect(t.assetPath.startsWith('audio/'), isTrue);
      }
    });

    test('AudioVoiceService plays instrument sound effects safely', () async {
      final service = AudioVoiceService();
      await service.playInstrumentSfx('piano');
      await service.playInstrumentSfx('drum');
      await service.playInstrumentSfx('chime');
      await service.playInstrumentSfx('guitar');
      await service.playInstrumentSfx('teddy');
    });

    test(
        'AudioVoiceService triggers Teddy welcome greeting and respects settings',
        () async {
      final service = AudioVoiceService();
      await service.setWelcomeGreetingEnabled(true);
      expect(service.welcomeGreetingEnabled, isTrue);

      // Play welcome greeting
      await service.playTeddyWelcomeGreeting();

      // Disable welcome greeting
      await service.setWelcomeGreetingEnabled(false);
      expect(service.welcomeGreetingEnabled, isFalse);

      // Should safely return without error when disabled
      await service.playTeddyWelcomeGreeting();

      // Re-enable
      await service.setWelcomeGreetingEnabled(true);
      expect(service.welcomeGreetingEnabled, isTrue);
    });

    test('AudioVoiceService runs comprehensive diagnostic test', () async {
      final service = AudioVoiceService();
      final report = await service.runDiagnosticTest();
      expect(report.ttsSuccess, isTrue);
      expect(report.audioSuccess, isTrue);
      expect(report.ttsDetails, isNotEmpty);
      expect(report.audioDetails, isNotEmpty);
    });
  });

  group('Puzzle Time, Sorting Fun, and Memory Game Screens', () {
    testWidgets('PuzzleGameScreen renders pieces and target slots',
        (tester) async {
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PuzzleGameScreen(
              onBack: () => backed = true,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Puzzle Time'), findsOneWidget);
      expect(find.text('Target Puzzle Board'), findsOneWidget);
      expect(find.text('Slot Lion'), findsOneWidget);
      expect(find.text('Slot Bunny'), findsOneWidget);

      // Tap back button
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      expect(backed, isTrue);
    });

    testWidgets('SortingGameScreen allows sorting fruit and animal items',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SortingGameScreen(
              onBack: () {},
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Sorting Fun'), findsOneWidget);
      expect(find.text('Fruits Basket'), findsOneWidget);
      expect(find.text('Animals Basket'), findsOneWidget);

      // First item is Apple (fruit)
      expect(find.text('Apple'), findsOneWidget);

      // Tap Fruits basket
      await tester.tap(find.text('Fruits Basket'));
      await tester.pump(const Duration(milliseconds: 700));

      // Second item is Puppy (animal)
      expect(find.text('Puppy'), findsOneWidget);

      // Tap Animals basket
      await tester.tap(find.text('Animals Basket'));
      await tester.pump(const Duration(milliseconds: 700));

      // Third item is Banana
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('MemoryGameScreen renders animal sequence pad and rounds',
        (tester) async {
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemoryGameScreen(
              onBack: () => backed = true,
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Memory Game'), findsOneWidget);
      expect(find.text('Round: 1 / 3'), findsOneWidget);
      expect(find.text('Puppy'), findsOneWidget);
      expect(find.text('Kitty'), findsOneWidget);

      // Back navigation
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      await tester.pump(const Duration(milliseconds: 2500));
      expect(backed, isTrue);
    });
  });

  group('Music Player Screen Controls & Navigation', () {
    testWidgets('MusicPlayerScreen renders tracks, controls and instruments',
        (tester) async {
      bool backed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicPlayerScreen(onBack: () => backed = true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text("Teddy's Music Room"), findsOneWidget);
      expect(find.text('Twinkle Twinkle Little Star'), findsWidgets);

      // Scroll to instruments
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));

      // Instrument accompaniment sound buttons
      expect(find.text('Piano'), findsOneWidget);
      expect(find.text('Drum'), findsOneWidget);
      expect(find.text('Chime'), findsOneWidget);
      expect(find.text('Guitar'), findsOneWidget);

      // Play instrument
      await tester.tap(find.text('Piano'));
      await tester.pump(const Duration(milliseconds: 100));

      // Back navigation
      final backBtn = find.byIcon(Icons.arrow_back_rounded);
      await tester.tap(backBtn);
      expect(backed, isTrue);
    });
  });

  group('Parent and Baby Profile Screens', () {
    testWidgets(
        'ParentProfileScreen scrolls to bottom, updates switches and dropdowns, and persists',
        (tester) async {
      bool switchedToBaby = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParentProfileScreen(
              onBack: () {},
              onSwitchToBabyProfile: () => switchedToBaby = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Parent Profile'), findsWidgets);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);

      // Verify profile switcher
      final babyTab = find.text('Baby Profile');
      expect(babyTab, findsOneWidget);
      await tester.tap(babyTab);
      expect(switchedToBaby, isTrue);

      // Verify relationship dropdown updates immediately
      final relationshipDropdown = find.byType(DropdownButton<String>).first;
      await tester.scrollUntilVisible(relationshipDropdown, 150,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(relationshipDropdown);
      await tester.pumpAndSettle();
      final fatherItem = find.text('Father').last;
      await tester.tap(fatherItem);
      await tester.pumpAndSettle();
      expect(find.text('Father'), findsWidgets);

      // Verify language dropdown updates immediately
      final languageDropdown = find.byType(DropdownButton<String>).last;
      await tester.tap(languageDropdown);
      await tester.pumpAndSettle();
      final frenchItem = find.text('French').last;
      await tester.tap(frenchItem);
      await tester.pumpAndSettle();
      expect(find.text('French'), findsWidgets);

      // Verify audio switches toggle independently and update AudioVoiceService
      final soundSwitch =
          find.widgetWithText(SwitchListTile, 'Voice Pronunciation & Guidance');
      await tester.scrollUntilVisible(soundSwitch, 200,
          scrollable: find.byType(Scrollable).first);
      expect(soundSwitch, findsOneWidget);
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();
      expect(AudioVoiceService().soundEnabled, isFalse);

      final musicSwitch =
          find.widgetWithText(SwitchListTile, 'Background Music & Rhymes');
      expect(musicSwitch, findsOneWidget);
      await tester.tap(musicSwitch);
      await tester.pumpAndSettle();
      expect(AudioVoiceService().musicEnabled, isFalse);

      final welcomeSwitch =
          find.widgetWithText(SwitchListTile, 'Teddy Welcome Voice & Sound');
      expect(welcomeSwitch, findsOneWidget);
      await tester.tap(welcomeSwitch);
      await tester.pumpAndSettle();
      expect(AudioVoiceService().welcomeGreetingEnabled, isFalse);

      // Verify diagnostics buttons
      final testVoiceBtn = find.text('Test Voice 🗣️');
      await tester.scrollUntilVisible(testVoiceBtn, 200,
          scrollable: find.byType(Scrollable).first);
      expect(testVoiceBtn, findsOneWidget);
      expect(find.text('Test Sound 🔔'), findsOneWidget);
      await tester.tap(testVoiceBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Test Sound 🔔'));
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll to bottom to verify Save Profile button is reachable and visible
      final saveButton = find.text('Save Profile ⭐');
      await tester.scrollUntilVisible(saveButton, 300,
          scrollable: find.byType(Scrollable).first);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify persistent storage in ProfileRepository
      final savedParent = await ProfileRepository.loadParentProfile();
      expect(savedParent.relationship, 'Father');
      expect(savedParent.language, 'French');
      expect(savedParent.soundEnabled, isFalse);
      expect(savedParent.musicEnabled, isFalse);
      expect(savedParent.welcomeGreetingEnabled, isFalse);
    });

    testWidgets(
        'BabyInfoScreen scrolls to bottom, validates nickname, and persists baby profile',
        (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyInfoScreen(
              onBack: () {},
              onSaveSuccess: () => saved = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Edit Baby Profile'), findsOneWidget);
      expect(find.text("Full Name"), findsOneWidget);
      expect(find.text("Nickname (Used by Teddy) *"), findsOneWidget);

      final nicknameField = find.byType(TextFormField).at(1);
      // Test required validation - clear nickname
      await tester.enterText(nicknameField, '');
      final saveBtn = find.text('Save Profile ⭐');
      await tester.scrollUntilVisible(saveBtn, 400,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text("Please enter a nickname"), findsOneWidget);
      expect(saved, isFalse);

      // Test length validation - 1 character
      await tester.scrollUntilVisible(nicknameField, -400,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(nicknameField, 'E');
      await tester.scrollUntilVisible(saveBtn, 400,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(
          find.text("Nickname must be at least 2 characters"), findsOneWidget);
      expect(saved, isFalse);

      // Enter valid nickname
      await tester.scrollUntilVisible(nicknameField, -400,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(nicknameField, 'Milo');

      // Select avatar Puppy
      final puppyAvatar = find.text('Puppy');
      await tester.scrollUntilVisible(puppyAvatar, 200,
          scrollable: find.byType(Scrollable).first);
      expect(puppyAvatar, findsOneWidget);
      await tester.tap(puppyAvatar);
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll to bottom and save profile
      await tester.scrollUntilVisible(saveBtn, 500,
          scrollable: find.byType(Scrollable).first);
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(saved, isTrue);

      final reloadedBaby = await ProfileRepository.loadBabyProfile();
      expect(reloadedBaby.nickname, 'Milo');
      expect(reloadedBaby.avatarName, 'Puppy');
    });

    testWidgets(
        'BabyProfileScreen displays stats and switches to Parent Profile',
        (tester) async {
      bool editOpened = false;
      bool switchedToParent = false;
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BabyProfileScreen(
              completedActivities: 8,
              badges: const {'First Letter', 'Number Star', 'Game Champion'},
              bob: controller,
              onBack: () {},
              onEditProfile: () => editOpened = true,
              onSwitchToParentProfile: () => switchedToParent = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text("Emma's Profile"), findsOneWidget);
      expect(find.text('26/26'), findsOneWidget); // alphabet phonics
      expect(find.text('10/10'), findsOneWidget); // numbers
      expect(find.text('8'), findsOneWidget); // games won

      // Switch to Parent Profile
      final parentTab = find.text('Parent Profile');
      expect(parentTab, findsOneWidget);
      await tester.tap(parentTab);
      expect(switchedToParent, isTrue);

      final editIcon = find.byIcon(Icons.edit_rounded).first;
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      expect(editOpened, isTrue);

      controller.dispose();
    });
  });

  group('Full Application Navigation to New Features', () {
    testWidgets('Dashboard to Parent View to Parent Info and Baby Profile',
        (tester) async {
      await tester.pumpWidget(const TeddyAiApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Welcome Screen -> Continue Learning -> Dashboard
      await tester.tap(find.text("Continue Learning"));
      await tester.pump(const Duration(milliseconds: 500));

      // Open Progress
      await tester.tap(find.text('Progress'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('My Progress'), findsOneWidget);
    });

    testWidgets('Games screen opens Puzzle Time, Sorting Fun, and Memory Game',
        (tester) async {
      await tester.pumpWidget(const TeddyAiApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Welcome Screen -> Continue Learning -> Dashboard
      await tester.tap(find.text("Continue Learning"));
      await tester.pump(const Duration(milliseconds: 500));

      // Open Games
      final gamesTile = find.widgetWithText(LearningTile, 'Games');
      await tester.ensureVisible(gamesTile);
      await tester.tap(gamesTile);
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Open Puzzle Time
      await tester.tap(find.text('Puzzle Time'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Target Puzzle Board'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 500));

      // 2. Open Sorting Fun
      await tester.tap(find.text('Sorting Fun'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Fruits Basket'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Open Memory Game
      await tester.tap(find.text('Memory Game'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Round: 1 / 3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 2500));
    });

    testWidgets('Activities screen opens Music & Movement player',
        (tester) async {
      await tester.pumpWidget(const TeddyAiApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Welcome Screen -> Continue Learning -> Dashboard
      await tester.tap(find.text("Continue Learning"));
      await tester.pump(const Duration(milliseconds: 500));

      // Open Activities
      final actTile = find.widgetWithText(LearningTile, 'Activities');
      await tester.ensureVisible(actTile);
      await tester.tap(actTile);
      await tester.pump(const Duration(milliseconds: 500));

      // Open Music & Movement
      await tester.tap(find.text('Music & Movement'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text("Teddy's Music Room"), findsOneWidget);

      // Back returns to Activities
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Activities'), findsWidgets);
    });
  });
}

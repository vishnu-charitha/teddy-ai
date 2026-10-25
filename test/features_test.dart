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
    SharedPreferences.setMockInitialValues({});

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
        nickname: 'Leo',
        age: 5,
        avatarName: 'Lion',
        language: 'Spanish',
        preferences: ['Puzzles & Games', 'Music & Songs'],
      );

      await ProfileRepository.saveBabyProfile(updated);
      final reloaded = await ProfileRepository.loadBabyProfile();

      expect(reloaded.nickname, 'Leo');
      expect(reloaded.age, 5);
      expect(reloaded.avatarName, 'Lion');
      expect(reloaded.language, 'Spanish');
      expect(reloaded.preferences, contains('Puzzles & Games'));
      expect(reloaded.preferences, contains('Music & Songs'));
    });

    test('ParentProfile serialization and audio preference persistence',
        () async {
      final initial = await ProfileRepository.loadParentProfile();
      expect(initial.name, 'Sarah');
      expect(initial.soundEnabled, isTrue);
      expect(initial.musicEnabled, isTrue);

      final updated = ParentProfile(
        name: 'Sarah',
        email: 'sarah@example.com',
        language: 'French',
        soundEnabled: false,
        musicEnabled: true,
      );

      await ProfileRepository.saveParentProfile(updated);
      final reloaded = await ProfileRepository.loadParentProfile();

      expect(reloaded.name, 'Sarah');
      expect(reloaded.email, 'sarah@example.com');
      expect(reloaded.language, 'French');
      expect(reloaded.soundEnabled, isFalse);
      expect(reloaded.musicEnabled, isTrue);
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
    testWidgets('ParentInfoScreen edits guardian info and audio switches',
        (tester) async {
      bool profileOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParentInfoScreen(
              onBack: () {},
              onOpenBabyProfile: () => profileOpened = true,
              onEditBabyInfo: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Parent Information'), findsOneWidget);
      expect(find.text('Guardian Name'), findsOneWidget);

      // Scroll down to see Save Settings and toggles
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Save Settings'), findsOneWidget);

      // Verify and tap diagnostic buttons
      expect(find.text('Audio & Voice Diagnostics'), findsOneWidget);
      expect(find.text('Test Voice'), findsOneWidget);
      expect(find.text('Test Music / SFX'), findsOneWidget);
      await tester.tap(find.text('Test Voice'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Test Music / SFX'));
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll further down to reach shortcut buttons
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Child Profile shortcut button
      await tester.tap(find.text('Child Profile'));
      expect(profileOpened, isTrue);
    });

    testWidgets('BabyInfoScreen saves child nickname and age', (tester) async {
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

      expect(find.text('Baby Information'), findsOneWidget);
      expect(find.text("Child's First Name or Nickname"), findsOneWidget);

      // Select age 5
      final age5 = find.text('5');
      expect(age5, findsOneWidget);
      await tester.tap(age5);
      await tester.pump(const Duration(milliseconds: 100));

      // Select avatar Puppy
      final puppyAvatar = find.text('Puppy');
      expect(puppyAvatar, findsOneWidget);
      await tester.tap(puppyAvatar);
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll and save profile
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 200));

      final saveBtn = find.text('Save Profile ⭐');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(saved, isTrue);
    });

    testWidgets('BabyProfileScreen displays stats and opens edit profile',
        (tester) async {
      bool editOpened = false;
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
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text("Emma's Profile"), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // completed activities
      expect(find.text('3'), findsOneWidget); // badges unlocked

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

      // Welcome -> Age -> Dashboard
      await tester.tap(find.text("Let's Start Learning"));
      await tester.pump(const Duration(milliseconds: 500));
      final continueBtn = find.text('Continue ✨');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
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

      // Welcome -> Dashboard
      await tester.tap(find.text("Let's Start Learning"));
      await tester.pump(const Duration(milliseconds: 500));
      final continueBtn = find.text('Continue ✨');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
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

      // Welcome -> Dashboard
      await tester.tap(find.text("Let's Start Learning"));
      await tester.pump(const Duration(milliseconds: 500));
      final continueBtn = find.text('Continue ✨');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
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

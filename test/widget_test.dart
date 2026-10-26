import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teddy_ai/main.dart';
import 'package:teddy_ai/mascot.dart';

import 'package:flutter/services.dart';
import 'package:teddy_ai/parent_baby_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'started': true,
      'completedOnboarding': true,
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async => 1);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'),
            (call) async => 1);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'),
            (call) async => 1);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '.');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers/events/*'),
            (call) async => 1);
  });

  testWidgets('Teddy AI welcome screen renders with mascot and actions',
      (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Teddy AI'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Parent Log In'), findsOneWidget);
    expect(find.byType(TeddyMascot), findsOneWidget);

    // Drain startup greeting delayed timer
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('Returning user taps Continue Learning and enters Dashboard',
      (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    final startButton = find.text('Continue Learning');
    expect(startButton, findsOneWidget);
    await tester.tap(startButton);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hi, Emma! 👋'), findsOneWidget);
  });

  testWidgets(
      'First-time user onboarding flow Step 1 -> Step 2 -> Step 3 -> Dashboard',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'started': false,
      'completedOnboarding': false,
    });

    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen has "Get Started / Create Profile"
    expect(find.text('Get Started / Create Profile'), findsOneWidget);
    await tester.tap(find.text('Get Started / Create Profile'));
    await tester.pump(const Duration(milliseconds: 500));

    // Step 1: Parent Setup
    expect(find.text('Step 1 of 3: Parent Setup'), findsOneWidget);
    final saveParentBtn = find.descendant(
      of: find.byType(ParentProfileScreen),
      matching: find.text('Save Profile ⭐'),
    );
    await tester.ensureVisible(saveParentBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(saveParentBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Step 2: Baby Details
    expect(find.text('Step 2 of 3: Baby Details'), findsOneWidget);
    final saveBabyBtn = find.descendant(
      of: find.byType(BabyInfoScreen),
      matching: find.text('Save Profile ⭐'),
    );
    await tester.ensureVisible(saveBabyBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(saveBabyBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Step 3: Review Profiles
    expect(find.text('Step 3 of 3: Confirmation'), findsOneWidget);
    final enterBtn = find.text('Enter Teddy AI Dashboard ✨');
    await tester.ensureVisible(enterBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(enterBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Dashboard
    expect(find.text('Hi, Emma! 👋'), findsOneWidget);

    // Reset back to returning user for subsequent test cases
    SharedPreferences.setMockInitialValues({
      'started': true,
      'completedOnboarding': true,
    });
  });

  testWidgets('Learning screen previous and next navigation works correctly',
      (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Open Alphabet from Dashboard
    await tester.tap(find.text('Alphabet & Phonics'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Apple'), findsOneWidget);

    // Tap Next (Chevron right) -> Bear
    final nextBtn = find.byIcon(Icons.chevron_right_rounded);
    await tester.tap(nextBtn);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bear'), findsOneWidget);

    // Tap Previous (Chevron left) -> Apple (verifying onPrev works!)
    final prevBtn = find.byIcon(Icons.chevron_left_rounded);
    await tester.tap(prevBtn);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Apple'), findsOneWidget);

    // Tap in-app Back -> Dashboard
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hi, Emma! 👋'), findsOneWidget);
  });

  testWidgets('Badges back navigation returns to originating screen',
      (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test 1: Open Badges from Dashboard -> Back returns to Dashboard
    final dashBadges = find.text('Badges');
    await tester.scrollUntilVisible(dashBadges, 300,
        scrollable: find.byType(Scrollable).first);
    expect(dashBadges, findsOneWidget);
    await tester.tap(dashBadges);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('First Letter'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('👋'), findsOneWidget);

    // Test 2: Open Badges from Progress -> Back returns to Progress
    await tester.tap(find.text('Progress'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('My Progress'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
    final badgesBtn = find.text('Badges');
    expect(badgesBtn, findsWidgets);
    await tester.tap(badgesBtn.last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('First Letter'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('My Progress'), findsOneWidget);
  });

  testWidgets('Activities and Coloring back navigation works', (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Open Activities
    final actTile = find.text('Activities');
    await tester.ensureVisible(actTile);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(actTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Drawing & Coloring'), findsOneWidget);

    // Open Coloring
    await tester.tap(find.text('Drawing & Coloring'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Color the Butterfly'), findsOneWidget);

    // Back -> Activities
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Drawing & Coloring'), findsOneWidget);

    // Back -> Dashboard
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Hi, Emma! 👋'), findsOneWidget);
  });

  testWidgets('Numbers and Colors learning screens work with selections',
      (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Open Numbers
    final numbersTile = find.widgetWithText(LearningTile, 'Numbers');
    await tester.ensureVisible(numbersTile);
    await tester.tap(numbersTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Three ducks'), findsOneWidget);

    // Tap number chip '5'
    final chip5 = find.text('5');
    await tester.ensureVisible(chip5);
    await tester.tap(chip5);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Five apples'), findsOneWidget);

    // Back -> Dashboard
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));

    // Open Colors
    final colorsTile = find.widgetWithText(LearningTile, 'Colors & Shapes');
    await tester.ensureVisible(colorsTile);
    await tester.tap(colorsTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Colors & Shapes'), findsWidgets);
    expect(find.text('I know this color! ⭐'), findsOneWidget);

    // Tap '🟦' (Blue)
    final blueCard = find.text('🟦');
    await tester.ensureVisible(blueCard);
    await tester.tap(blueCard);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('Stories and Reading Dialog open correctly', (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Open Stories
    final storiesTile = find.widgetWithText(LearningTile, 'Stories');
    await tester.ensureVisible(storiesTile);
    await tester.tap(storiesTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Stories'), findsWidgets);

    // Tap 'Read Story'
    final readBtn = find.text('Read Story');
    await tester.ensureVisible(readBtn);
    await tester.tap(readBtn);
    await tester.pump(const Duration(milliseconds: 500));

    // Dialog appears with 'The End ⭐'
    expect(find.text('The End ⭐'), findsOneWidget);
    await tester.tap(find.text('The End ⭐'));
    // Advance beyond celebration timer duration (2200ms)
    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.text('The End ⭐'), findsNothing);
  });

  testWidgets('Games and Memory Match Game flip cards', (tester) async {
    await tester.pumpWidget(const TeddyAiApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Welcome Screen -> Continue Learning -> Dashboard
    await tester.tap(find.text('Continue Learning'));
    await tester.pump(const Duration(milliseconds: 500));

    // Open Games
    final gamesTile = find.widgetWithText(LearningTile, 'Games');
    await tester.ensureVisible(gamesTile);
    await tester.tap(gamesTile);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Games'), findsWidgets);

    // Tap Match the Pairs
    final matchPairs = find.text('Match the Pairs');
    await tester.ensureVisible(matchPairs);
    await tester.tap(matchPairs);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Progress: '), findsOneWidget);

    // Cards have '?'
    expect(find.text('?'), findsNWidgets(6));

    // Tap card 0
    await tester.tap(find.text('?').first);
    await tester.pump(const Duration(milliseconds: 300));

    // Back to Games
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Games'), findsWidgets);
  });

  testWidgets(
      'TeddyMascot mouth animates while speaking and closes when silent',
      (tester) async {
    final speakingNotifier = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimationSheetTestWrapper(
              speakingNotifier: speakingNotifier,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(TeddyMascot), findsOneWidget);

    // Initial state: not speaking (mouth closed)
    expect(speakingNotifier.value, isFalse);
    await tester.pump(const Duration(milliseconds: 100));

    // Transition to speaking: true
    speakingNotifier.value = true;
    await tester.pump(); // Register listener notification
    await tester
        .pump(const Duration(milliseconds: 130)); // Mid animation (mouth open)

    // Transition to speaking: false
    speakingNotifier.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200)); // Smooth closure
  });
}

class AnimationSheetTestWrapper extends StatefulWidget {
  final ValueNotifier<bool> speakingNotifier;
  const AnimationSheetTestWrapper({super.key, required this.speakingNotifier});

  @override
  State<AnimationSheetTestWrapper> createState() =>
      _AnimationSheetTestWrapperState();
}

class _AnimationSheetTestWrapperState extends State<AnimationSheetTestWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TeddyMascot(
      bob: _bob,
      size: 140,
      isSpeakingListenable: widget.speakingNotifier,
    );
  }
}

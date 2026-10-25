import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_voice_service.dart';
import 'design_system.dart';
import 'extra_games_screens.dart';
import 'mascot.dart';
import 'music_player_screen.dart';
import 'parent_baby_screens.dart';
import 'profile_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Teddy AI: main() started');
  runApp(const TeddyAiApp());
}

class TeddyAiApp extends StatelessWidget {
  const TeddyAiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Teddy AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: warmWhite,
          colorScheme: ColorScheme.fromSeed(
            seedColor: lavenderDeep,
            primary: purple,
            surface: warmWhite,
          ),
          fontFamily: 'Nunito',
          appBarTheme: const AppBarTheme(
            backgroundColor: warmWhite,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const TeddyShell(),
      );
}

class TeddyShell extends StatefulWidget {
  const TeddyShell({super.key});

  @override
  State<TeddyShell> createState() => _TeddyShellState();
}

class _TeddyShellState extends State<TeddyShell> with TickerProviderStateMixin {
  int page = 0;
  int age = 4;
  int completed = 0;
  int letterIndex = 0;
  int numberIndex = 2;
  int colorIndex = 0;
  int selectedColor = 0;
  int gameTurns = 0;
  bool started = false;
  bool parentLog = false;
  int _badgesSource = 2;
  bool _celebrating = false;
  bool _hasPlayedWelcomeGreeting = false;

  BabyProfile babyProfile = BabyProfile();
  ParentProfile parentProfile = ParentProfile();

  final Set<int> flipped = {};
  final Set<int> matched = {};
  final Set<String> badges = {'First Letter'};

  // Coloring screen parts map
  final Map<int, Color> butterflyColors = {
    0: Colors.red.shade300,
    1: Colors.orange.shade300,
    2: Colors.blue.shade300,
    3: Colors.purple.shade300,
  };

  late final AnimationController bob;

  final letters = const [
    ('Aa', 'Apple', '🍎', 'A is for sweet red Apple!'),
    ('Bb', 'Bear', '🧸', 'B is for friendly Teddy Bear!'),
    ('Cc', 'Cat', '🐱', 'C is for playful little Kitten!'),
    ('Dd', 'Dog', '🐶', 'D is for happy playful Puppy!'),
    ('Ee', 'Elephant', '🐘', 'E is for gentle wise Elephant!'),
    ('Ff', 'Fish', '🐠', 'F is for colorful swimming Fish!'),
    ('Gg', 'Giraffe', '🦒', 'G is for tall friendly Giraffe!'),
    ('Hh', 'House', '🏠', 'H is for warm cozy House!'),
    ('Ii', 'Ice Cream', '🍦', 'I is for yummy cool Ice Cream!'),
    ('Jj', 'Juice', '🧃', 'J is for sweet fruit Juice!'),
    ('Kk', 'Kite', '🪁', 'K is for high flying Kite!'),
    ('Ll', 'Lion', '🦁', 'L is for brave little Lion!'),
    ('Mm', 'Monkey', '🐵', 'M is for cheerful swinging Monkey!'),
    ('Nn', 'Nest', '🪺', 'N is for cozy birdie Nest!'),
    ('Oo', 'Owl', '🦉', 'O is for wise night Owl!'),
    ('Pp', 'Panda', '🐼', 'P is for cuddly gentle Panda!'),
    ('Qq', 'Queen', '👑', 'Q is for kind royal Queen!'),
    ('Rr', 'Rainbow', '🌈', 'R is for bright colorful Rainbow!'),
    ('Ss', 'Sun', '☀️', 'S is for warm cheerful Sun!'),
    ('Tt', 'Tiger', '🐯', 'T is for strong friendly Tiger!'),
    ('Uu', 'Umbrella', '☂️', 'U is for rainy day Umbrella!'),
    ('Vv', 'Violin', '🎻', 'V is for lovely musical Violin!'),
    ('Ww', 'Whale', '🐋', 'W is for big blue Whale!'),
    ('Xx', 'Xylophone', '🎼', 'X is for cheerful musical Xylophone!'),
    ('Yy', 'Yak', '🐂', 'Y is for fluffy mountain Yak!'),
    ('Zz', 'Zebra', '🦓', 'Z is for striped fast Zebra!'),
  ];

  final numbers = const [
    (1, 'One duck', '🐥'),
    (2, 'Two ducks', '🐥🐥'),
    (3, 'Three ducks', '🐥🐥🐥'),
    (4, 'Four stars', '⭐️⭐️⭐️⭐️'),
    (5, 'Five apples', '🍎🍎🍎🍎🍎'),
    (6, 'Six flowers', '🌼🌼🌼🌼🌼🌼'),
    (7, 'Seven fish', '🐟🐟🐟🐟🐟🐟🐟'),
    (8, 'Eight balls', '⚽️⚽️⚽️⚽️⚽️⚽️⚽️⚽️'),
    (9, 'Nine stars', '⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️⭐️'),
    (10, 'Ten ducks', '🐥🐥🐥🐥🐥🐥🐥🐥🐥🐥'),
  ];

  final colors = const [
    ('Red', Color(0xFFFF555D), '🔴', 'Bright and warm like strawberries!'),
    ('Blue', Color(0xFF4BA9F5), '🟦', 'Cool and peaceful like the sky!'),
    ('Yellow', Color(0xFFFFC928), '🔺', 'Cheerful like the morning sun!'),
    ('Green', Color(0xFF43C588), '⭐', 'Fresh like green garden leaves!'),
    ('Purple', Color(0xFFAA72ED), '💜', 'Magical like lavender flowers!'),
    ('Orange', Color(0xFFFF9D42), '🟠', 'Energetic and happy like oranges!'),
  ];

  final gameEmojis = const ['🍎', '🍌', '🍎', '🍌', '🐥', '🐥'];

  @override
  void initState() {
    super.initState();
    bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _initAppAndGreeting();
  }

  Future<void> _initAppAndGreeting() async {
    debugPrint('Teddy AI: _initAppAndGreeting() starting...');
    await AudioVoiceService().init();
    await _load();
    if (!mounted) return;

    // Use WidgetsBinding post-frame callback so the initial welcome/home screen is fully rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hasPlayedWelcomeGreeting) {
        _hasPlayedWelcomeGreeting = true;
        debugPrint(
            'Teddy AI: Post-frame callback executing. Initial page is $page. Starting greeting...');
        // Gentle delay after first frame to let Android audio track and TTS service settle
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            debugPrint(
                'Teddy AI: Triggering AudioVoiceService().playTeddyWelcomeGreeting()...');
            AudioVoiceService().playTeddyWelcomeGreeting();
          }
        });
      }
    });
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final baby = await ProfileRepository.loadBabyProfile();
      final parent = await ProfileRepository.loadParentProfile();

      if (!mounted) return;
      setState(() {
        babyProfile = baby;
        parentProfile = parent;
        age = baby.age;
        completed = p.getInt('completed') ?? 0;
        started = p.getBool('started') ?? false;
        final savedBadges = p.getStringList('badges');
        if (savedBadges != null && savedBadges.isNotEmpty) {
          badges.addAll(savedBadges);
        }
      });
      debugPrint(
          'Teddy AI: _load() completed. started=$started, initial page=$page');
      if (started) {
        setState(() => page = 2);
        debugPrint(
            'Teddy AI: User previously started onboarding, page set to 2');
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('childAge', age);
      await p.setInt('completed', completed);
      await p.setBool('started', started);
      await p.setStringList('badges', badges.toList());
      babyProfile.age = age;
      await ProfileRepository.saveBabyProfile(babyProfile);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  void go(int p) {
    setState(() => page = p);
    if (p == 3) {
      _speakAlphabet(letterIndex);
    } else if (p == 4) {
      _speakNumber(numberIndex);
    } else if (p == 5) {
      _speakColor(colorIndex);
    }
  }

  void _speakAlphabet(int idx) {
    if (idx < 0 || idx >= letters.length) return;
    final l = letters[idx];
    AudioVoiceService().speakLetterPhonics(
      letter: l.$1,
      word: l.$2,
      phonicsPhrase: l.$4,
    );
  }

  void _speakNumber(int idx) {
    if (idx < 0 || idx >= numbers.length) return;
    final n = numbers[idx];
    AudioVoiceService().speakNumber(n.$1, n.$2);
  }

  void _speakColor(int idx) {
    if (idx < 0 || idx >= colors.length) return;
    final c = colors[idx];
    AudioVoiceService().speakColor(c.$1, c.$4);
  }

  void _startGame() {
    setState(() {
      flipped.clear();
      matched.clear();
      gameTurns = 0;
      page = 8;
    });
    AudioVoiceService().speak('Tap two cards to find a matching pair!');
  }

  void _triggerCelebration() {
    setState(() => _celebrating = true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  // Handles back navigation across all screens.
  void _handleBack() {
    if (!mounted) return;
    switch (page) {
      case 1: // Age selection -> welcome
        setState(() => page = 0);
        break;
      case 8: // Matching game -> games menu
      case 14: // Puzzle game -> games menu
      case 15: // Sorting game -> games menu
      case 16: // Memory game -> games menu
        setState(() => page = 7);
        break;
      case 10: // Coloring -> activities menu
      case 17: // Music -> activities menu
        AudioVoiceService().pauseMusic();
        setState(() => page = 9);
        break;
      case 12: // Badges -> return to source
        setState(() => page = _badgesSource);
        break;
      case 18: // Parent Info -> Parent Screen
        setState(() => page = 13);
        break;
      case 19: // Baby Info -> Baby Profile
        setState(() => page = 20);
        break;
      case 20: // Baby Profile -> Parent Screen
        setState(() => page = 13);
        break;
      case 0: // Welcome screen -> system back can pop
        break;
      case 2: // Dashboard -> welcome, and reset onboarding state.
        setState(() {
          page = 0;
          started = false;
        });
        _save();
        break;
      default: // All other feature screens -> dashboard.
        setState(() => page = 2);
        break;
    }
  }

  void finishActivity({String? specificBadge}) {
    setState(() {
      completed++;
      if (specificBadge != null) {
        badges.add(specificBadge);
      }
      badges.addAll(completed >= 3 ? {'Number Star'} : {});
      badges.addAll(completed >= 5 ? {'Story Explorer'} : {});
      badges.addAll(completed >= 7 ? {'Game Champion'} : {});
      badges.addAll(completed >= 9 ? {'Creative Kid'} : {});
      badges.addAll(completed >= 12 ? {'Nature Friend'} : {});
    });
    _save();
    _triggerCelebration();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            Text('⭐ ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                'Great job! Your learning progress is saved.',
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Teddy AI: build() page $page');
    PageFrame.defaultBackAction = _handleBack;

    final pages = <Widget>[
      WelcomeScreen(onStart: () => go(1), bob: bob),
      AgeScreen(
        age: age,
        onAge: (v) => setState(() => age = v),
        onContinue: () {
          setState(() {
            started = true;
            page = 2;
          });
          _save();
        },
        bob: bob,
      ),
      Dashboard(
        age: age,
        completed: completed,
        bob: bob,
        onOpen: (p) {
          if (p == 12) _badgesSource = 2;
          go(p);
        },
      ),
      LearningScreen(
        title: 'Alphabet & Phonics',
        hero: letters[letterIndex].$1,
        subtitle: letters[letterIndex].$2,
        emoji: letters[letterIndex].$3,
        bg: cream,
        onPrev: () {
          setState(() => letterIndex =
              (letterIndex - 1 + letters.length) % letters.length);
          _speakAlphabet(letterIndex);
        },
        onNext: () {
          setState(() => letterIndex = (letterIndex + 1) % letters.length);
          _speakAlphabet(letterIndex);
        },
        chips: letters.map((e) => e.$1).toList(),
        onChip: (i) {
          setState(() => letterIndex = i);
          _speakAlphabet(i);
        },
        onSpeak: () => _speakAlphabet(letterIndex),
        onComplete: () => finishActivity(specificBadge: 'First Letter'),
        bob: bob,
      ),
      LearningScreen(
        title: 'Numbers',
        hero: '${numbers[numberIndex].$1}',
        subtitle: numbers[numberIndex].$2,
        emoji: numbers[numberIndex].$3,
        bg: mint,
        onPrev: () {
          setState(() => numberIndex =
              (numberIndex - 1 + numbers.length) % numbers.length);
          _speakNumber(numberIndex);
        },
        onNext: () {
          setState(() => numberIndex = (numberIndex + 1) % numbers.length);
          _speakNumber(numberIndex);
        },
        chips: List.generate(10, (i) => '${i + 1}'),
        onChip: (i) {
          setState(() => numberIndex = i);
          _speakNumber(i);
        },
        onSpeak: () => _speakNumber(numberIndex),
        onComplete: () => finishActivity(specificBadge: 'Number Star'),
        bob: bob,
      ),
      ColorsScreen(
        colors: colors,
        selected: colorIndex,
        onSelect: (i) {
          setState(() => colorIndex = i);
          _speakColor(i);
        },
        onComplete: () => finishActivity(),
      ),
      StoriesScreen(
        onRead: () => _story(context),
        onComplete: () => finishActivity(specificBadge: 'Story Explorer'),
      ),
      GamesScreen(
        onPlay: _startGame,
        onComplete: () => finishActivity(specificBadge: 'Game Champion'),
        onPuzzle: () => go(14),
        onSorting: () => go(15),
        onMemory: () => go(16),
      ),
      GamePlayScreen(
        emojis: gameEmojis,
        flipped: flipped,
        matched: matched,
        onTap: (i) {
          if (matched.contains(i) ||
              flipped.contains(i) ||
              flipped.length >= 2) {
            return;
          }
          setState(() {
            flipped.add(i);
            if (flipped.length == 2) {
              final a = flipped.toList();
              if (gameEmojis[a[0]] == gameEmojis[a[1]]) {
                matched.addAll(a);
              }
              Future.delayed(const Duration(milliseconds: 650), () {
                if (mounted) {
                  setState(() {
                    flipped.clear();
                    if (matched.length == gameEmojis.length) {
                      finishActivity(specificBadge: 'Game Champion');
                    }
                  });
                }
              });
            }
          });
        },
        onReset: _startGame,
        onBack: () => go(7),
      ),
      ActivitiesScreen(
        onColor: () => go(10),
        onComplete: () => finishActivity(specificBadge: 'Nature Friend'),
        onMusic: () => go(17),
      ),
      ColoringScreen(
        selectedColor: selectedColor,
        coloredParts: butterflyColors,
        onColorPart: (part) {
          final cs = [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            purple,
            Colors.pink,
            const Color(0xFF00BCD4),
          ];
          setState(() {
            butterflyColors[part] = cs[selectedColor];
          });
        },
        onSelectColor: (i) => setState(() => selectedColor = i),
        onClear: () {
          setState(() {
            butterflyColors.clear();
          });
        },
        onComplete: () => finishActivity(specificBadge: 'Creative Kid'),
      ),
      ProgressScreen(
        completed: completed,
        onBadges: () {
          _badgesSource = 11;
          go(12);
        },
      ),
      BadgesScreen(badges: badges),
      ParentScreen(
        completed: completed,
        log: parentLog,
        onToggle: (v) => setState(() => parentLog = v),
        onParentSettings: () => go(18),
        onBabyProfile: () => go(20),
      ),
      // --- Page 14: Puzzle Time Game ---
      PuzzleGameScreen(
        onBack: () => go(7),
        onComplete: () => finishActivity(specificBadge: 'Puzzle Master'),
      ),
      // --- Page 15: Sorting Fun Game ---
      SortingGameScreen(
        onBack: () => go(7),
        onComplete: () => finishActivity(specificBadge: 'Sorting Star'),
      ),
      // --- Page 16: Animal Memory Sequence Game ---
      MemoryGameScreen(
        onBack: () => go(7),
        onComplete: () => finishActivity(specificBadge: 'Super Memory'),
      ),
      // --- Page 17: Full Music Player ---
      MusicPlayerScreen(
        onBack: () => go(9),
      ),
      // --- Page 18: Parent Information & Audio Preferences ---
      ParentInfoScreen(
        onBack: () => go(13),
        onOpenBabyProfile: () => go(20),
        onEditBabyInfo: () => go(19),
      ),
      // --- Page 19: Baby Information (Editable details) ---
      BabyInfoScreen(
        onBack: () => go(20),
        onSaveSuccess: () async {
          final b = await ProfileRepository.loadBabyProfile();
          if (mounted) {
            setState(() {
              babyProfile = b;
              age = b.age;
            });
          }
          go(20);
        },
      ),
      // --- Page 20: Baby Profile (Dashboard view) ---
      BabyProfileScreen(
        completedActivities: completed,
        badges: badges,
        bob: bob,
        onBack: () => go(13),
        onEditProfile: () => go(19),
      ),
    ];

    final useNav = page >= 2 &&
        page != 8 &&
        page != 10 &&
        page != 14 &&
        page != 15 &&
        page != 16 &&
        page != 17 &&
        page != 18 &&
        page != 19;

    return PopScope<Object?>(
      canPop: page == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: ConfettiOverlay(
            celebrate: _celebrating,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0.015),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(page), child: pages[page]),
            ),
          ),
        ),
        bottomNavigationBar: useNav
            ? TeddyNav(
                current: page,
                onTap: go,
              )
            : null,
      ),
    );
  }

  void _story(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: warmWhite,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: lavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🧸📖', style: TextStyle(fontSize: 34)),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Brave Little Bear',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'One starry night, Teddy heard a tiny sound in the forest. A little bluebird had lost its way home.\n\nTeddy shared his warm lantern and held the bird’s wing. Step by step, they found the cozy nest high in the whispering pine.\n\n“Being brave means being kind,” Teddy smiled under the moon. ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              BouncyButton(
                onTap: () {
                  Navigator.pop(ctx);
                  finishActivity(specificBadge: 'Story Explorer');
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [purple, lavenderDeep],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'The End ⭐',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Navigation Bar ---

class TeddyNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const TeddyNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Home', Icons.home_rounded, 2),
      ('Learn', Icons.auto_stories_rounded, 3),
      ('Stories', Icons.menu_book_rounded, 6),
      ('Games', Icons.sports_esports_rounded, 7),
      ('Progress', Icons.insights_rounded, 11),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D2850).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: items.map((e) {
          final active = current == e.$3 ||
              (current == 4 && e.$3 == 3) ||
              (current == 5 && e.$3 == 3);
          return Expanded(
            child: InkWell(
              onTap: () => onTap(e.$3),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? purple.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        e.$2,
                        color: active ? purple : inkSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                        color: active ? purple : inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Screen 0: Welcome Screen ---

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  final AnimationController bob;
  const WelcomeScreen({super.key, required this.onStart, required this.bob});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8CDDF9),
              Color(0xFFEAF8FE),
              Color(0xFFC7F3C1),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating background clouds and sun
            const Positioned(
              top: 40,
              left: 20,
              child: Text('☁️', style: TextStyle(fontSize: 42)),
            ),
            const Positioned(
              top: 75,
              left: 130,
              child: Opacity(
                opacity: 0.8,
                child: Text('☁️', style: TextStyle(fontSize: 28)),
              ),
            ),
            const Positioned(
              top: 30,
              right: 28,
              child: Text('☀️', style: TextStyle(fontSize: 44)),
            ),
            // Bottom meadow flora
            const Positioned(
              left: 24,
              bottom: 90,
              child: Text('🌼 🌷 🌼', style: TextStyle(fontSize: 26)),
            ),
            const Positioned(
              right: 24,
              bottom: 90,
              child: Text('🌷 🌸 🌼', style: TextStyle(fontSize: 26)),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // Early learning age tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D2850)
                                  .withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐ ', style: TextStyle(fontSize: 14)),
                            Text(
                              'Early Learning for Ages 1–7',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Teddy AI',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9E3D20),
                          letterSpacing: -1.0,
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 6,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Learn • Play • Grow',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A brighter tomorrow\nfor every child',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: ink,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Animated waving Mascot
                      TeddyMascot(
                        bob: bob,
                        size: 210,
                        waving: true,
                        interactive: true,
                        onTap: () {
                          AudioVoiceService().playTeddyWelcomeGreeting();
                        },
                      ),
                      const SizedBox(height: 28),
                      BouncyButton(
                        onTap: onStart,
                        child: Container(
                          width: double.infinity,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9E2C), Color(0xFFFF6F59)],
                            ),
                            borderRadius: BorderRadius.circular(31),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6F59)
                                    .withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.white, size: 26),
                              SizedBox(width: 8),
                              Text(
                                "Let's Start Learning",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'A safe little world to learn and explore ✨',
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

// --- Screen 1: Age Selection ---

class AgeScreen extends StatelessWidget {
  final int age;
  final ValueChanged<int> onAge;
  final VoidCallback onContinue;
  final AnimationController bob;

  const AgeScreen({
    super.key,
    required this.age,
    required this.onAge,
    required this.onContinue,
    required this.bob,
  });

  @override
  Widget build(BuildContext context) {
    final companions = [
      ('🐥', 'Duckling', pink),
      ('🐱', 'Kitten', cream),
      ('🐰', 'Bunny', const Color(0xFFD4F6EF)),
      ('🧸', 'Teddy', mint),
      ('🐶', 'Puppy', const Color(0xFFDDEBFF)),
      ('🦁', 'Lion Cub', lavender),
      ('🐬', 'Dolphin', const Color(0xFFF4D9FF)),
    ];

    return PageFrame(
      title: 'How old is your child?',
      back: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const Text(
              "We'll personalize activities for their age.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: inkSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(7, (i) {
                final n = i + 1;
                final isSelected = age == n;
                final comp = companions[i];
                final cardWidth = (MediaQuery.of(context).size.width - 64) / 3;

                return BouncyButton(
                  onTap: () => onAge(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: cardWidth,
                    height: 104,
                    decoration: BoxDecoration(
                      color: comp.$3,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? purple : Colors.white,
                        width: isSelected ? 3.2 : 2.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: purple.withValues(alpha: 0.32),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF0D2850)
                                    .withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                comp.$1,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$n',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? purple : ink,
                                ),
                              ),
                              Text(
                                n == 1 ? 'Year' : 'Years',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? purple : inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.check_circle_rounded,
                                size: 18, color: purple),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TeddyMascot(bob: bob, size: 130),
            const SizedBox(height: 16),
            BouncyButton(
              onTap: onContinue,
              child: Container(
                width: double.infinity,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, lavenderDeep],
                  ),
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Continue ✨',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// --- Screen 2: Dashboard ---

class Dashboard extends StatelessWidget {
  final int age, completed;
  final AnimationController bob;
  final ValueChanged<int> onOpen;

  const Dashboard({
    super.key,
    required this.age,
    required this.completed,
    required this.bob,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top greeting banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFFDDF4FF), Color(0xFFFFF0D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2850).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi, Emma! 👋',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Let's learn and play!",
                          style: TextStyle(
                            color: inkSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        BouncyButton(
                          onTap: () => onOpen(1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D2850)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Age $age',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: ink,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_rounded,
                                    size: 14, color: purple),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TeddyMascot(
                    bob: bob,
                    size: 96,
                    interactive: true,
                    onTap: () {
                      AudioVoiceService().playTeddyWelcomeGreeting();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              "Today's Learning",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            // 2x3 Activity Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
              children: [
                LearningTile(
                  title: 'Alphabet & Phonics',
                  emoji: '🔤',
                  color: pink,
                  onTap: () => onOpen(3),
                ),
                LearningTile(
                  title: 'Numbers',
                  emoji: '🔢',
                  color: cream,
                  onTap: () => onOpen(4),
                ),
                LearningTile(
                  title: 'Colors & Shapes',
                  emoji: '🎨',
                  color: const Color(0xFFFFE0D9),
                  onTap: () => onOpen(5),
                ),
                LearningTile(
                  title: 'Stories',
                  emoji: '📚',
                  color: lavender,
                  onTap: () => onOpen(6),
                ),
                LearningTile(
                  title: 'Games',
                  emoji: '🎮',
                  color: const Color(0xFFD9EEFF),
                  onTap: () => onOpen(7),
                ),
                LearningTile(
                  title: 'Activities',
                  emoji: '🖍️',
                  color: const Color(0xFFFFE4F2),
                  onTap: () => onOpen(9),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Goal card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goldLight,
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: gold.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Goal",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ink,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          completed >= 2
                              ? 'Goal accomplished! Super star!'
                              : 'Complete 2 activities',
                          style: const TextStyle(
                              color: inkSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '${completed % 3}/2',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Keep exploring!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MiniAction(
                    emoji: '🏆',
                    title: 'My Badges',
                    onTap: () => onOpen(12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MiniAction(
                    emoji: '👨‍👩‍👧',
                    title: 'Parent View',
                    onTap: () => onOpen(13),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class LearningTile extends StatelessWidget {
  final String title, emoji;
  final Color color;
  final VoidCallback onTap;

  const LearningTile({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D2850).withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      );
}

class MiniAction extends StatelessWidget {
  final String emoji, title;
  final VoidCallback onTap;

  const MiniAction({
    super.key,
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EFF7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: inkSecondary),
            ],
          ),
        ),
      );
}

// --- Screen 3 & 4: Learning Screen (Alphabet & Numbers) ---

class LearningScreen extends StatelessWidget {
  final String title, hero, subtitle, emoji;
  final Color bg;
  final VoidCallback onPrev, onNext, onComplete;
  final List<String> chips;
  final ValueChanged<int> onChip;
  final AnimationController bob;
  final VoidCallback? onSpeak;

  const LearningScreen({
    super.key,
    required this.title,
    required this.hero,
    required this.subtitle,
    required this.emoji,
    required this.bg,
    required this.onPrev,
    required this.onNext,
    required this.chips,
    required this.onChip,
    required this.onComplete,
    required this.bob,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) => PageFrame(
        title: title,
        trailing: IconButton(
          onPressed: () {
            onSpeak?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                content: Text('$hero sounds cheerful and fun! 🔊'),
              ),
            );
          },
          icon: const Icon(Icons.volume_up_rounded, color: purple, size: 26),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            children: [
              // Hero card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D2850).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hero,
                            style: TextStyle(
                              fontSize: title == 'Numbers' ? 92 : 82,
                              fontWeight: FontWeight.w900,
                              color: title == 'Numbers'
                                  ? const Color(0xFF169C5A)
                                  : const Color(0xFFE84C55),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: Text(
                                  emoji,
                                  key: ValueKey(emoji),
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                              const SizedBox(width: 14),
                              TeddyMascot(
                                bob: bob,
                                size: 84,
                                interactive: true,
                                onTap: onSpeak,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BouncyButton(
                                onTap: onPrev,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE2EAF2),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.chevron_left_rounded,
                                      color: ink, size: 30),
                                ),
                              ),
                              const SizedBox(width: 20),
                              BouncyButton(
                                onTap: onNext,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [purple, lavenderDeep],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: purple.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded,
                                      color: Colors.white, size: 32),
                                ),
                              ),
                              const SizedBox(width: 16),
                              BouncyButton(
                                onTap: () {
                                  onSpeak?.call();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      content: Text('$hero says hello! 🔊'),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: const Color(0xFFE2EAF2),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.volume_up_rounded,
                                      color: purple, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Chips for quick tapping
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(
                  chips.length,
                  (i) {
                    final selected = chips[i] == hero;
                    return BouncyButton(
                      onTap: () => onChip(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: chips.length > 8 ? 48 : 62,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? purple
                              : [pink, cream, mint, lavender, sky][i % 5],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? purple : Colors.white,
                            width: 2,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: purple.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          chips[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: selected ? Colors.white : ink,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              BouncyButton(
                onTap: onComplete,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [purple, lavenderDeep],
                    ),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'I learned this!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// --- Screen 5: Colors Screen ---

class ColorsScreen extends StatelessWidget {
  final List<(String, Color, String, String)> colors;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onComplete;

  const ColorsScreen({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelect,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors[selected];
    return PageFrame(
      title: 'Colors & Shapes',
      trailing: IconButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Text('${c.$1}: ${c.$4}'),
          ),
        ),
        icon: const Icon(Icons.volume_up_rounded, color: purple, size: 26),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2850).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(selected),
                    tween: Tween(begin: 0.75, end: 1.0),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: c.$2,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: c.$2.withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selected == 0 ? '☺' : c.$3,
                        style: const TextStyle(
                          fontSize: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.$2,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: c.$2.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      c.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: List.generate(
                colors.length,
                (i) => BouncyButton(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected == i ? purple : const Color(0xFFE5EFF5),
                        width: selected == i ? 3 : 1.5,
                      ),
                      boxShadow: selected == i
                          ? [
                              BoxShadow(
                                color: purple.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        colors[i].$3,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            BouncyButton(
              onTap: onComplete,
              child: Container(
                width: double.infinity,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, lavenderDeep],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  'I know this color! ⭐',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Screen 6: Stories Screen ---

class StoriesScreen extends StatelessWidget {
  final VoidCallback onRead, onComplete;
  const StoriesScreen(
      {super.key, required this.onRead, required this.onComplete});

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Stories',
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Featured hero story
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF233575), Color(0xFF5E48B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF233575).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🌙 ⭐ ✨', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  const Text('🧸📖', style: TextStyle(fontSize: 82)),
                  const SizedBox(height: 8),
                  const Text(
                    'The Brave Little Bear',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A story about kindness and courage',
                    style: TextStyle(
                      color: Color(0xFFE2E6FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BouncyButton(
                    onTap: onRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Read Story',
                        style: TextStyle(
                          color: purple,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'More Stories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              ('🐱', 'The Lost Kitten', 'Help a kitten find home'),
              ('🐮', 'A Day at the Farm', 'Meet friendly farm animals'),
              ('🌈', 'Under the Rainbow', 'A colorful adventure'),
            ].map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFE8EEF5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(s.$1, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: ink,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.$3,
                            style: const TextStyle(
                              color: inkSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BouncyButton(
                      onTap: onComplete,
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: purple,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// --- Screen 7: Games Menu Screen ---

class GamesScreen extends StatelessWidget {
  final VoidCallback onPlay, onComplete;
  final VoidCallback? onPuzzle, onSorting, onMemory;
  const GamesScreen({
    super.key,
    required this.onPlay,
    required this.onComplete,
    this.onPuzzle,
    this.onSorting,
    this.onMemory,
  });

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Games',
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            GameMenuTile(
              emoji: '🍎🍌',
              title: 'Match the Pairs',
              subtitle: 'Find the same objects',
              color: mint,
              onTap: onPlay,
            ),
            GameMenuTile(
              emoji: '🦋',
              title: 'Puzzle Time',
              subtitle: 'Complete the picture',
              color: lavender,
              onTap: onPuzzle ?? onComplete,
            ),
            GameMenuTile(
              emoji: '🦁🐘',
              title: 'Memory Game',
              subtitle: 'Remember and match',
              color: cream,
              onTap: onMemory ?? onPlay,
            ),
            GameMenuTile(
              emoji: '🔺🟢',
              title: 'Sorting Fun',
              subtitle: 'Sort by color or shape',
              color: pink,
              onTap: onSorting ?? onComplete,
            ),
          ],
        ),
      );
}

class GameMenuTile extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const GameMenuTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BouncyButton(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D2850).withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: inkSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_filled_rounded,
                  color: purple, size: 32),
            ],
          ),
        ),
      );
}

// --- Screen 8: Matching Game Play Screen (with 3D Card Flip Animation) ---

class GamePlayScreen extends StatelessWidget {
  final List<String> emojis;
  final Set<int> flipped, matched;
  final ValueChanged<int> onTap;
  final VoidCallback onReset;
  final VoidCallback onBack;

  const GamePlayScreen({
    super.key,
    required this.emojis,
    required this.flipped,
    required this.matched,
    required this.onTap,
    required this.onReset,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Match the Pairs',
        onBack: onBack,
        trailing: IconButton(
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded, color: purple, size: 26),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('Progress: ',
                        style:
                            TextStyle(fontWeight: FontWeight.w800, color: ink)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: matched.length / emojis.length,
                          minHeight: 12,
                          backgroundColor: sky.withValues(alpha: 0.3),
                          color: const Color(0xFF42C485),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${matched.length ~/ 2}/3',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  itemCount: emojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, i) {
                    final isRevealed =
                        flipped.contains(i) || matched.contains(i);
                    final isMatched = matched.contains(i);

                    return BouncyButton(
                      onTap: () => onTap(i),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: isRevealed ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutBack,
                        builder: (context, val, _) {
                          final isBack = val > 0.5;
                          final angle = val * math.pi;

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: isBack
                                ? Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..rotateY(math.pi),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isMatched
                                            ? mint
                                            : const Color(0xFFFFF7EA),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: isMatched
                                              ? const Color(0xFF42C485)
                                              : Colors.white,
                                          width: 3.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0D2850)
                                                .withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        emojis[i],
                                        style: const TextStyle(fontSize: 42),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8CDDF9),
                                          Color(0xFF5ABFE7)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                          color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5ABFE7)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap two cards to find a matching pair!',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
}

// --- Screen 9: Activities Menu Screen ---

class ActivitiesScreen extends StatelessWidget {
  final VoidCallback onColor, onComplete;
  final VoidCallback? onMusic;
  const ActivitiesScreen({
    super.key,
    required this.onColor,
    required this.onComplete,
    this.onMusic,
  });

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Activities',
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            GameMenuTile(
              emoji: '🎨',
              title: 'Drawing & Coloring',
              subtitle: 'Create and express',
              color: pink,
              onTap: onColor,
            ),
            GameMenuTile(
              emoji: '✂️',
              title: 'Craft Ideas',
              subtitle: 'Fun DIY activities',
              color: lavender,
              onTap: onComplete,
            ),
            GameMenuTile(
              emoji: '🎵',
              title: 'Music & Movement',
              subtitle: 'Sing, dance and play',
              color: sky,
              onTap: onMusic ?? onComplete,
            ),
            GameMenuTile(
              emoji: '🌿',
              title: 'Nature Exploration',
              subtitle: 'Learn about the world',
              color: mint,
              onTap: onComplete,
            ),
          ],
        ),
      );
}

// --- Screen 10: Coloring Screen (Interactive Butterfly) ---

class ColoringScreen extends StatelessWidget {
  final int selectedColor;
  final Map<int, Color> coloredParts;
  final ValueChanged<int> onColorPart;
  final ValueChanged<int> onSelectColor;
  final VoidCallback onClear;
  final VoidCallback onComplete;

  const ColoringScreen({
    super.key,
    required this.selectedColor,
    required this.coloredParts,
    required this.onColorPart,
    required this.onSelectColor,
    required this.onClear,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      purple,
      Colors.pink,
      const Color(0xFF00BCD4),
    ];

    return PageFrame(
      title: 'Color the Butterfly',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Interactive drawing canvas
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE3EFF7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: InteractiveButterfly(
                    currentColor: cs[selectedColor],
                    coloredParts: coloredParts,
                    onTapPart: onColorPart,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Color palette selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  cs.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: BouncyButton(
                      onTap: () => onSelectColor(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selectedColor == i ? 46 : 36,
                        height: selectedColor == i ? 46 : 36,
                        decoration: BoxDecoration(
                          color: cs[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: selectedColor == i ? 3.5 : 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs[i].withValues(
                                  alpha: selectedColor == i ? 0.45 : 0.2),
                              blurRadius: selectedColor == i ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: selectedColor == i
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                BouncyButton(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE2EAF2), width: 1.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded, color: ink, size: 20),
                        SizedBox(width: 4),
                        Text('Reset',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: ink)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                BouncyButton(
                  onTap: onComplete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [purple, lavenderDeep],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Finish art',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InteractiveButterfly extends StatelessWidget {
  final Color currentColor;
  final Map<int, Color> coloredParts;
  final ValueChanged<int> onTapPart;

  const InteractiveButterfly({
    super.key,
    required this.currentColor,
    required this.coloredParts,
    required this.onTapPart,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapUp: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.globalPosition);
          final midX = box.size.width / 2;
          final midY = box.size.height / 2;

          // Quadrant tapping for wings
          if (local.dx < midX && local.dy < midY) {
            onTapPart(0); // Top-left wing
          } else if (local.dx >= midX && local.dy < midY) {
            onTapPart(1); // Top-right wing
          } else if (local.dx < midX && local.dy >= midY) {
            onTapPart(2); // Bottom-left wing
          } else {
            onTapPart(3); // Bottom-right wing
          }
        },
        child: CustomPaint(
          size: const Size(280, 290),
          painter: ButterflyPainter(
            color: currentColor,
            coloredParts: coloredParts,
          ),
        ),
      );
}

class ButterflyPainter extends CustomPainter {
  final Color color;
  final Map<int, Color>? coloredParts;

  ButterflyPainter({required this.color, this.coloredParts});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF26364D);

    final cx = size.width / 2, cy = size.height / 2;

    // Wing parts (0: Top-left, 1: Top-right, 2: Bottom-left, 3: Bottom-right)
    final parts = [
      (0, -1.0, -1.0, coloredParts?[0] ?? color.withValues(alpha: 0.28)),
      (1, 1.0, -1.0, coloredParts?[1] ?? color.withValues(alpha: 0.28)),
      (2, -1.0, 1.0, coloredParts?[2] ?? color.withValues(alpha: 0.28)),
      (3, 1.0, 1.0, coloredParts?[3] ?? color.withValues(alpha: 0.28)),
    ];

    for (final item in parts) {
      final side = item.$2;
      final y = item.$3;
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = item.$4;

      final rect = Rect.fromCenter(
        center:
            Offset(cx + side * size.width * 0.21, cy + y * size.height * 0.15),
        width: size.width * 0.38,
        height: size.height * 0.36,
      );
      canvas.drawOval(rect, fillPaint);
      canvas.drawOval(rect, p);

      // Decorative dots on wings
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(
        Offset(cx + side * size.width * 0.21, cy + y * size.height * 0.15),
        11,
        dotPaint,
      );
      canvas.drawCircle(
        Offset(cx + side * size.width * 0.21, cy + y * size.height * 0.15),
        11,
        p..strokeWidth = 2,
      );
    }

    // Butterfly body
    final bodyPaint = Paint()
      ..color = const Color(0xFF324765)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.20),
      Offset(cx, cy + size.height * 0.28),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(
      Offset(cx, cy - size.height * 0.22),
      9.0,
      Paint()..color = const Color(0xFF324765),
    );

    // Antennae
    final antPaint = Paint()
      ..color = const Color(0xFF324765)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftAnt = Path()
      ..moveTo(cx, cy - size.height * 0.23)
      ..quadraticBezierTo(
          cx - 16, cy - size.height * 0.28, cx - 18, cy - size.height * 0.35);
    canvas.drawPath(leftAnt, antPaint);
    canvas.drawCircle(Offset(cx - 18, cy - size.height * 0.35), 3.5,
        Paint()..color = const Color(0xFF324765));

    final rightAnt = Path()
      ..moveTo(cx, cy - size.height * 0.23)
      ..quadraticBezierTo(
          cx + 16, cy - size.height * 0.28, cx + 18, cy - size.height * 0.35);
    canvas.drawPath(rightAnt, antPaint);
    canvas.drawCircle(Offset(cx + 18, cy - size.height * 0.35), 3.5,
        Paint()..color = const Color(0xFF324765));
  }

  @override
  bool shouldRepaint(covariant ButterflyPainter old) =>
      old.color != color || old.coloredParts != coloredParts;
}

// --- Screen 11: Progress Screen ---

class ProgressScreen extends StatelessWidget {
  final int completed;
  final VoidCallback onBadges;

  const ProgressScreen({
    super.key,
    required this.completed,
    required this.onBadges,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Alphabet',
      'Numbers',
      'Colors & Shapes',
      'Stories',
      'Games',
    ];

    return PageFrame(
      title: 'My Progress',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Cheerful reward summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: goldLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: gold.withValues(alpha: 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 44)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're doing great!",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ink,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Keep learning a little every day!',
                        style: TextStyle(
                          color: inkSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Learning Areas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(labels.length, (i) {
            final val = [0.6, 0.4, 0.8, 0.4, 0.6][i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    ['🔤', '🔢', '🎨', '📚', '🎮'][i],
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 11,
                        backgroundColor: const Color(0xFFE7F0F5),
                        color: const Color(0xFF42C485),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(val * 5).round()}/5',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, size: 34, color: purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$completed activities completed so far!',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                BouncyButton(
                  onTap: onBadges,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: purple,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: purple.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Badges',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// --- Screen 12: Badges Screen ---

class BadgesScreen extends StatelessWidget {
  final Set<String> badges;
  const BadgesScreen({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final all = [
      ('First Letter', '🔤', 'Great start!'),
      ('Number Star', '⭐', 'Well done!'),
      ('Story Explorer', '📚', 'Keep reading!'),
      ('Game Champion', '🎮', 'Amazing!'),
      ('Creative Kid', '🎨', 'So talented!'),
      ('Nature Friend', '🌿', 'Wonderful!'),
    ];

    return PageFrame(
      title: 'My Badges',
      child: GridView.count(
        padding: const EdgeInsets.all(18),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.94,
        children: all.map((b) {
          final unlocked = badges.contains(b.$1);
          return Container(
            decoration: BoxDecoration(
              color: unlocked ? goldLight : const Color(0xFFF3F6F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: unlocked ? gold.withValues(alpha: 0.6) : Colors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (unlocked ? gold : Colors.black)
                      .withValues(alpha: unlocked ? 0.16 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: unlocked
                          ? [orange, const Color(0xFFFFD447)]
                          : [Colors.grey.shade300, Colors.grey.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (unlocked ? orange : Colors.black)
                            .withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unlocked ? b.$2 : '🔒',
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  b.$1,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: unlocked ? ink : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked ? b.$3 : 'Keep learning!',
                  style: TextStyle(
                    color: unlocked ? inkSecondary : Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- Screen 13: Parent Section ---

class ParentScreen extends StatelessWidget {
  final int completed;
  final bool log;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onParentSettings;
  final VoidCallback? onBabyProfile;

  const ParentScreen({
    super.key,
    required this.completed,
    required this.log,
    required this.onToggle,
    this.onParentSettings,
    this.onBabyProfile,
  });

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Parent View',
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E9FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Overview',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      selected: !log,
                      onSelected: (v) => onToggle(false),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Activity Log',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      selected: log,
                      onSelected: (v) => onToggle(true),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!log) ...[
              if (onParentSettings != null || onBabyProfile != null) ...[
                Row(
                  children: [
                    if (onParentSettings != null)
                      Expanded(
                        child: BouncyButton(
                          onTap: onParentSettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: lavender,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: purple.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('⚙️ ', style: TextStyle(fontSize: 18)),
                                Text(
                                  'Parent Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: purple,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (onParentSettings != null && onBabyProfile != null)
                      const SizedBox(width: 10),
                    if (onBabyProfile != null)
                      Expanded(
                        child: BouncyButton(
                          onTap: onBabyProfile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: mintLight,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: mintDeep.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('👶 ', style: TextStyle(fontSize: 18)),
                                Text(
                                  'Baby Profile',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E824C),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'This Week',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      emoji: '⭐',
                      number: '${completed + 8}',
                      label: 'Activities',
                      color: cream,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: StatCard(
                      emoji: '📚',
                      number: '3',
                      label: 'Stories',
                      color: lavender,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: StatCard(
                      emoji: '🎮',
                      number: '2',
                      label: 'Games',
                      color: pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Learning Time',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: ink,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '42 minutes this week',
                style: TextStyle(
                  color: purple,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: const Color(0xFFE5EFF7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      7,
                      (i) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 24,
                            height: [45, 65, 35, 78, 54, 88, 40][i].toDouble(),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  [sky, purple, const Color(0xFF55D697)][i % 3],
                                  [
                                    sky.withValues(alpha: 0.6),
                                    purple.withValues(alpha: 0.6),
                                    const Color(0xFF55D697)
                                        .withValues(alpha: 0.6)
                                  ][i % 3],
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🧸 ', style: TextStyle(fontSize: 24)),
                    Expanded(
                      child: Text(
                        'Emma is showing great interest in letters and colors! Try a short phonics game together tomorrow.',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                'Alphabet & Phonics',
                'Numbers',
                'Color the Butterfly',
                'The Brave Little Bear',
                'Match the Pairs',
              ].map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFE8EEF5), width: 1.2),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: lavender,
                      child: Icon(Icons.check_rounded, color: purple),
                    ),
                    title: Text(
                      e,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    subtitle: const Text(
                      'Completed • Today',
                      style: TextStyle(color: inkSecondary, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  final String emoji, number, label;
  final Color color;

  const StatCard({
    super.key,
    required this.emoji,
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D2850).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: inkSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

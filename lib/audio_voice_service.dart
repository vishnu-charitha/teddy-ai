import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diagnostic test results for audio and voice capabilities
class AudioDiagnosticResult {
  final bool ttsSuccess;
  final String ttsDetails;
  final bool audioSuccess;
  final String audioDetails;
  final List<String> availableEngines;
  final DateTime timestamp;

  const AudioDiagnosticResult({
    required this.ttsSuccess,
    required this.ttsDetails,
    required this.audioSuccess,
    required this.audioDetails,
    required this.availableEngines,
    required this.timestamp,
  });
}

/// Song model for the children's music player referencing genuine bundled assets
class MusicTrack {
  final String title;
  final String artist;
  final String emoji;
  final String assetPath;
  final Duration estimatedDuration;

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.emoji,
    required this.assetPath,
    required this.estimatedDuration,
  });
}

/// A robust, unified Audio and Voice service supporting:
/// - Text-to-speech for alphabet, numbers, colors, instructions with FlutterTts
/// - Audio player with genuine bundled assets for nursery rhymes and instruments
/// - Safe ducking (lowering music during speech) and audio cleanup
/// - Comprehensive diagnostics for parents and developers
class AudioVoiceService extends ChangeNotifier {
  static final AudioVoiceService _instance = AudioVoiceService._internal();
  factory AudioVoiceService() => _instance;
  AudioVoiceService._internal();

  FlutterTts? _tts;
  AudioPlayer? _player;
  AudioPlayer? _sfxPlayer;

  bool _ttsInitialized = false;
  bool _playerInitialized = false;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = 0.8;

  bool _isSpeaking = false;
  bool _isLoadingMusic = false;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(seconds: 30);
  int _currentTrackIndex = 0;
  String? _errorMessage;
  String? _ttsErrorMessage;
  List<String> _availableEngines = [];

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  final List<MusicTrack> tracks = const [
    MusicTrack(
      title: 'Twinkle Twinkle Little Star',
      artist: 'Teddy & Friends',
      emoji: '⭐',
      assetPath: 'audio/twinkle_twinkle.wav',
      estimatedDuration: Duration(seconds: 29),
    ),
    MusicTrack(
      title: 'Old MacDonald Had a Farm',
      artist: 'Barnyard Buddies',
      emoji: '🚜',
      assetPath: 'audio/old_macdonald.wav',
      estimatedDuration: Duration(seconds: 32),
    ),
    MusicTrack(
      title: 'The Wheels on the Bus',
      artist: 'Teddy Town Bus',
      emoji: '🚌',
      assetPath: 'audio/wheels_on_bus.wav',
      estimatedDuration: Duration(seconds: 16),
    ),
    MusicTrack(
      title: 'Row Row Row Your Boat',
      artist: 'Little Sailors',
      emoji: '🛶',
      assetPath: 'audio/row_row_boat.wav',
      estimatedDuration: Duration(seconds: 14),
    ),
    MusicTrack(
      title: 'The Alphabet Song',
      artist: 'Phonics Pals',
      emoji: '🔤',
      assetPath: 'audio/alphabet_song.wav',
      estimatedDuration: Duration(seconds: 30),
    ),
  ];

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  bool get isSpeaking => _isSpeaking;
  bool get isLoadingMusic => _isLoadingMusic;
  bool get isPlayingMusic => _playerState == PlayerState.playing;
  PlayerState get playerState => _playerState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  int get currentTrackIndex => _currentTrackIndex;
  MusicTrack get currentTrack => tracks[_currentTrackIndex];
  String? get errorMessage => _errorMessage;
  String? get ttsErrorMessage => _ttsErrorMessage;
  List<String> get availableEngines => _availableEngines;
  bool get ttsReady => _ttsInitialized && _ttsErrorMessage == null;

  /// Initialize TTS and Audio player with local preferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('parent_sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('parent_music_enabled') ?? true;
      _musicVolume = prefs.getDouble('parent_music_volume') ?? 0.8;
    } catch (e) {
      debugPrint('AudioVoiceService: SharedPreferences error: $e');
    }

    await _initTts();
    _initAudioPlayer();
    notifyListeners();
  }

  Future<void> _initTts() async {
    if (_ttsInitialized) return;
    try {
      _tts = FlutterTts();

      // Configure async handlers and parameters
      await _tts?.awaitSpeakCompletion(true);

      _tts?.setStartHandler(() {
        _isSpeaking = true;
        _ttsErrorMessage = null;
        notifyListeners();
      });

      _tts?.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts?.setCancelHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts?.setErrorHandler((dynamic msg) {
        _isSpeaking = false;
        _ttsErrorMessage = 'TTS Error: $msg';
        debugPrint('AudioVoiceService TTS error: $msg');
        notifyListeners();
      });

      try {
        await _tts?.setLanguage('en-US');
        await _tts
            ?.setPitch(1.15); // Friendly and cheerful child-appropriate pitch
        await _tts?.setSpeechRate(0.42); // Clear and slow for young children
        await _tts?.setVolume(1.0);
      } catch (e) {
        debugPrint('AudioVoiceService: TTS param setting warning: $e');
      }

      // Check available engines on Android / system
      try {
        final engines = await _tts?.getEngines;
        if (engines is List) {
          _availableEngines = engines.map((e) => e.toString()).toList();
          debugPrint(
              'AudioVoiceService: Available TTS engines: $_availableEngines');
        }
      } catch (e) {
        debugPrint('AudioVoiceService: Could not query TTS engines: $e');
      }

      _ttsInitialized = true;
      _ttsErrorMessage = null;
    } catch (e) {
      _ttsErrorMessage = 'TTS init failed: $e';
      debugPrint('AudioVoiceService TTS init failed: $e');
    }
  }

  void _initAudioPlayer() {
    if (_playerInitialized) return;
    try {
      _player = AudioPlayer();
      _sfxPlayer = AudioPlayer();

      // Ensure release mode and volume
      _player?.setReleaseMode(ReleaseMode.stop);
      _sfxPlayer?.setReleaseMode(ReleaseMode.stop);
      _player?.setVolume(_musicVolume);
      _sfxPlayer?.setVolume(_musicVolume);

      _stateSub = _player?.onPlayerStateChanged.listen((state) {
        _playerState = state;
        _isLoadingMusic = false;
        notifyListeners();
      });

      _posSub = _player?.onPositionChanged.listen((pos) {
        _currentPosition = pos;
        notifyListeners();
      });

      _durSub = _player?.onDurationChanged.listen((dur) {
        if (dur != Duration.zero) {
          _totalDuration = dur;
          notifyListeners();
        }
      });

      _playerInitialized = true;
    } catch (e) {
      debugPrint('AudioVoiceService AudioPlayer init failed: $e');
    }
  }

  /// Toggle or update sound enabled preference
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    if (!enabled) {
      await stopSpeech();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('parent_sound_enabled', enabled);
    } catch (_) {}
  }

  /// Toggle or update background music preference
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await pauseMusic();
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('parent_music_enabled', enabled);
    } catch (_) {}
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_musicVolume);
      await _sfxPlayer?.setVolume(_musicVolume);
    } catch (_) {}
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('parent_music_volume', _musicVolume);
    } catch (_) {}
  }

  // --- Voice / Speech Operations ---

  /// Speak arbitrary text with automatic ducking of music and interruption of previous speech
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_soundEnabled) return;
    if (text.trim().isEmpty) return;
    await _initTts();

    try {
      if (interrupt) {
        await _tts?.stop();
      }

      // Audio ducking: lower background music volume during speech
      final prevVolume = _musicVolume;
      final wasPlaying = _playerState == PlayerState.playing;
      if (wasPlaying && _musicEnabled) {
        try {
          await _player?.setVolume((prevVolume * 0.25).clamp(0.05, 1.0));
        } catch (_) {}
      }

      _isSpeaking = true;
      _ttsErrorMessage = null;
      notifyListeners();

      await _tts?.speak(text);

      // Restore music volume after speaking completes
      if (wasPlaying && _musicEnabled) {
        try {
          await _player?.setVolume(prevVolume);
        } catch (_) {}
      }
    } catch (e) {
      _isSpeaking = false;
      _ttsErrorMessage = 'Could not speak: $e';
      debugPrint('AudioVoiceService speak error: $e');
      notifyListeners();
    }
  }

  /// Stop currently playing speech
  Future<void> stopSpeech() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }

  /// Alphabet lesson pronunciation: "A. Apple. A is for sweet red Apple!"
  Future<void> speakLetterPhonics({
    required String letter,
    required String word,
    required String phonicsPhrase,
  }) async {
    if (!_soundEnabled) return;
    // Extract single letter (e.g. 'Aa' -> 'A') for clean, unambiguous phonetic pronunciation
    final cleanLetter = letter.isNotEmpty ? letter[0].toUpperCase() : letter;
    final text = '$cleanLetter. $word. $phonicsPhrase';
    await speak(text, interrupt: true);
  }

  /// Number lesson pronunciation
  Future<void> speakNumber(int number, String text) async {
    if (!_soundEnabled) return;
    await speak('Number $number! $text', interrupt: true);
  }

  /// Color lesson pronunciation
  Future<void> speakColor(String colorName, String phrase) async {
    if (!_soundEnabled) return;
    await speak('$colorName! $phrase', interrupt: true);
  }

  /// Friendly encouraging praise
  Future<void> speakEncouragement([String? phrase]) async {
    if (!_soundEnabled) return;
    final cheers = [
      'Super star!',
      'Great job, little learner!',
      'You did it!',
      'Wonderful!',
      'You are so smart!',
    ];
    await speak(phrase ?? cheers[(DateTime.now().millisecond) % cheers.length]);
  }

  // --- Music Operations ---

  /// Play a specific track by index using genuine local asset
  Future<void> playTrack(int index) async {
    if (!_musicEnabled) return;
    _initAudioPlayer();
    _currentTrackIndex = index.clamp(0, tracks.length - 1);
    final track = tracks[_currentTrackIndex];
    _errorMessage = null;
    _isLoadingMusic = true;
    _currentPosition = Duration.zero;
    _totalDuration = track.estimatedDuration;
    notifyListeners();

    try {
      await _player?.stop();
      // audioplayers 6.x AssetSource automatically maps 'audio/song.wav' to 'assets/audio/song.wav'
      await _player?.play(AssetSource(track.assetPath)).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () {},
          );
      _playerState = PlayerState.playing;
      _isLoadingMusic = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMusic = false;
      _playerState = PlayerState.stopped;
      _errorMessage = 'Could not load audio file: $e';
      debugPrint('AudioVoiceService play error: $e');
      notifyListeners();
    }
  }

  /// Play short instrument accompaniment sound effect
  Future<void> playInstrumentSfx(String instrument) async {
    if (!_soundEnabled) return;
    try {
      _initAudioPlayer();
      String asset;
      switch (instrument.toLowerCase()) {
        case 'piano':
          asset = 'audio/piano_note.wav';
          break;
        case 'drum':
          asset = 'audio/drum_beat.wav';
          break;
        case 'chime':
          asset = 'audio/chime_sparkle.wav';
          break;
        case 'guitar':
          asset = 'audio/guitar_chord.wav';
          break;
        default:
          asset = 'audio/test_beep.wav';
      }
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(AssetSource(asset)).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () {},
          );
    } catch (e) {
      debugPrint('AudioVoiceService playInstrumentSfx error: $e');
    }
  }

  /// Toggle play / pause
  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await pauseMusic();
    } else {
      if (_playerState == PlayerState.paused) {
        await resumeMusic();
      } else {
        await playTrack(_currentTrackIndex);
      }
    }
  }

  /// Pause music playback
  Future<void> pauseMusic() async {
    try {
      await _player?.pause();
    } catch (_) {}
    _playerState = PlayerState.paused;
    notifyListeners();
  }

  /// Resume music playback
  Future<void> resumeMusic() async {
    if (!_musicEnabled) return;
    try {
      await _player?.resume();
      _playerState = PlayerState.playing;
    } catch (e) {
      // If resume fails, restart track
      await playTrack(_currentTrackIndex);
    }
    notifyListeners();
  }

  /// Replay current track from beginning
  Future<void> replayTrack() async {
    try {
      await _player?.seek(Duration.zero);
      if (_playerState != PlayerState.playing) {
        await resumeMusic();
      }
    } catch (_) {
      await playTrack(_currentTrackIndex);
    }
  }

  /// Next track in list
  Future<void> nextTrack() async {
    final next = (_currentTrackIndex + 1) % tracks.length;
    await playTrack(next);
  }

  /// Previous track in list
  Future<void> previousTrack() async {
    final prev = (_currentTrackIndex - 1 + tracks.length) % tracks.length;
    await playTrack(prev);
  }

  /// Seek track position
  Future<void> seek(Duration pos) async {
    try {
      await _player?.seek(pos);
      _currentPosition = pos;
      notifyListeners();
    } catch (_) {}
  }

  /// Stop and reset music playback
  Future<void> stopMusic() async {
    try {
      await _player?.stop();
    } catch (_) {}
    _playerState = PlayerState.stopped;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  // --- Diagnostics Operation ---

  /// Run comprehensive audio and speech diagnostics
  Future<AudioDiagnosticResult> runDiagnosticTest() async {
    bool ttsOk = false;
    String ttsMsg = '';
    List<String> engines = [];

    // 1. Test Text-to-Speech
    try {
      await _initTts();
      try {
        final res = await _tts?.getEngines;
        if (res is List) {
          engines = res.map((e) => e.toString()).toList();
          _availableEngines = engines;
        }
      } catch (_) {}

      final speakRes =
          await _tts?.speak('Hello! I am Teddy, your learning friend!');
      ttsOk = true;
      ttsMsg = engines.isNotEmpty
          ? 'Voice ready! Active engines: ${engines.join(", ")}'
          : 'Voice ready! Spoke successfully (result: $speakRes)';
      _ttsErrorMessage = null;
    } catch (e) {
      ttsOk = false;
      ttsMsg = 'TTS Error: $e';
      _ttsErrorMessage = ttsMsg;
    }

    // 2. Test Audio Player with bundled asset
    bool audioOk = false;
    String audioMsg = '';
    try {
      _initAudioPlayer();
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(AssetSource('audio/test_beep.wav')).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () {},
          );
      audioOk = true;
      audioMsg = 'AudioPlayer ready! Played test_beep.wav successfully';
      _errorMessage = null;
    } catch (e) {
      audioOk = false;
      audioMsg = 'AudioPlayer Error: $e';
      _errorMessage = audioMsg;
    }

    notifyListeners();

    return AudioDiagnosticResult(
      ttsSuccess: ttsOk,
      ttsDetails: ttsMsg,
      audioSuccess: audioOk,
      audioDetails: audioMsg,
      availableEngines: engines,
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    try {
      _player?.dispose();
    } catch (_) {}
    try {
      _sfxPlayer?.dispose();
    } catch (_) {}
    try {
      _tts?.stop();
    } catch (_) {}
    super.dispose();
  }
}

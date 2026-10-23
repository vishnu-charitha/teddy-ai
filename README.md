# Teddy AI — Flutter Early-Learning & Phonics App

Teddy AI is a modern, interactive early-learning companion app for children aged 1 to 7, built with Flutter. It combines phonics teaching, nursery music, cognitive games, creative coloring, and parent dashboards into a playful, child-friendly experience featuring an animated teddy mascot.

---

## ✨ Features

- **Alphabet & Phonics Teaching**:
  - Full A–Z interactive alphabet board.
  - Dynamic teaching voice using `flutter_tts` that pronounces each letter name and example word (e.g., *"A is for Apple"*).
  - Speaker replay button and speech interruption protection for rapid tapping.
- **Music & Movement Player**:
  - Built-in nursery rhymes (*Twinkle Twinkle Little Star*, *Old MacDonald*, *Wheels on the Bus*, *Row Row Row Your Boat*, *Alphabet Song*).
  - High-quality offline 16-bit 44.1 kHz PCM audio assets powered by `audioplayers`.
  - Interactive instrument soundboard with piano notes, drum beats, chime sparkles, and guitar chords.
  - Play, pause, resume, seek, track switching, and background music ducking during voice instruction.
- **Cognitive Games & Creative Activities**:
  - **Puzzle Time**: Drag-and-drop shape and animal piece matching.
  - **Sorting Fun**: Fruit and animal category sorting with real-time feedback.
  - **Memory Match**: Card-flipping pair matching game.
  - **Butterfly Coloring**: Interactive coloring canvas with a child-safe palette.
- **Learning & Stories**:
  - Interactive numbers (1–10) and colors & shapes exploration.
  - Illustrated bedtime and discovery stories with reading dialogs.
- **Profiles & Progress**:
  - **Baby Profile**: Editable child details (nickname, birthday, favorite color, mascot avatar) persisted locally via `shared_preferences`.
  - **Parent Dashboard**: Weekly learning statistics, time limits, activity history, and audio toggles.
  - **Audio & Voice Diagnostics**: Developer and parent utility to verify TTS engines, speech synthesis, and audio playback status in real time.
  - **Rewards & Badges**: Star milestones and celebratory badges for learning progress.

---

## 🛠 Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.3.0`)
- **Audio Playback**: [`audioplayers`](https://pub.dev/packages/audioplayers) (`^6.7.1`)
- **Speech Synthesis**: [`flutter_tts`](https://pub.dev/packages/flutter_tts) (`^4.2.5`)
- **Persistence**: [`shared_preferences`](https://pub.dev/packages/shared_preferences) (`^2.3.2`)
- **Icons**: `cupertino_icons` (`^1.0.8`)
- **Design System**: Custom pastel palette, typography, responsive cards, and animated mascots.

---

## 📁 Project Structure

```text
teddy_ai/
├── android/                  # Android native project & manifest configurations
├── assets/
│   ├── animations/           # Animation assets
│   ├── audio/                # 10 bundled offline 16-bit PCM WAV audio tracks & SFX
│   └── images/               # Image resources
├── lib/
│   ├── audio_voice_service.dart   # Centralized TTS and audio playback service
│   ├── design_system.dart         # Design tokens, color palette, styles
│   ├── games_screens.dart         # Puzzle, Sorting, and Memory games
│   ├── main.dart                  # Core application routing & screen definitions
│   ├── mascot.dart                # Animated Teddy mascot widget
│   ├── music_player_screen.dart   # Music & Movement player with soundboard
│   └── parent_baby_screens.dart   # Parent info, baby info, and baby profile
├── test/
│   ├── features_test.dart         # Audio, profile persistence, and games tests
│   └── widget_test.dart           # Navigation, screen rendering, and UI flow tests
├── generate_audio_assets.py  # Audio generator script for bundled WAV assets
├── pubspec.yaml              # Flutter dependencies and asset registrations
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3.0 or higher)
- Android Studio / Android SDK (API 21+) or Xcode (macOS for iOS builds)
- A connected physical device or emulator

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/vishnu-charitha/teddy-ai.git
   cd teddy-ai
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify code quality & tests**:
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```

4. **Run the app**:
   ```bash
   # Run on connected Android device or emulator
   flutter run

   # Or run on Chrome
   flutter run -d chrome
   ```

---

## 🧪 Testing

The project includes 26 unit and widget tests covering profile serialization, local storage persistence, TTS logic, audio player lifecycle, game interactions, and multi-screen navigation flows.

```bash
flutter test
```

---

## 📄 License

This project is licensed under the MIT License — see the repository for details.

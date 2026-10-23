import 'package:flutter/material.dart';
import 'audio_voice_service.dart';
import 'design_system.dart';
import 'mascot.dart';
import 'profile_models.dart';

// ============================================================================
// 1. Parent Information Screen
// ============================================================================

class ParentInfoScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenBabyProfile;
  final VoidCallback onEditBabyInfo;

  const ParentInfoScreen({
    super.key,
    required this.onBack,
    required this.onOpenBabyProfile,
    required this.onEditBabyInfo,
  });

  @override
  State<ParentInfoScreen> createState() => _ParentInfoScreenState();
}

class _ParentInfoScreenState extends State<ParentInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _language = 'English';
  bool _soundEnabled = true;
  bool _musicEnabled = true;

  final List<String> _languages = const [
    'English',
    'Spanish',
    'French',
    'German',
    'Hindi',
    'Mandarin',
  ];

  String? _diagVoiceStatus;
  String? _diagAudioStatus;
  bool _isTestingVoice = false;
  bool _isTestingAudio = false;

  Future<void> _testVoice() async {
    setState(() {
      _isTestingVoice = true;
      _diagVoiceStatus = null;
    });
    try {
      await AudioVoiceService()
          .speak('Hello! I am Teddy, your learning friend!');
      if (!mounted) return;
      setState(() {
        _isTestingVoice = false;
        _diagVoiceStatus = 'Success: Teaching voice spoken clearly! 🔊';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingVoice = false;
        _diagVoiceStatus = 'Voice Error: $e';
      });
    }
  }

  Future<void> _testAudio() async {
    setState(() {
      _isTestingAudio = true;
      _diagAudioStatus = null;
    });
    try {
      await AudioVoiceService().playInstrumentSfx('chime');
      if (!mounted) return;
      setState(() {
        _isTestingAudio = false;
        _diagAudioStatus = 'Success: AudioPlayer played chime asset! 🎵';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingAudio = false;
        _diagAudioStatus = 'Audio Error: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileRepository.loadParentProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _language = profile.language;
      _soundEnabled = profile.soundEnabled;
      _musicEnabled = profile.musicEnabled;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ParentProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      language: _language,
      soundEnabled: _soundEnabled,
      musicEnabled: _musicEnabled,
    );

    await ProfileRepository.saveParentProfile(profile);
    await AudioVoiceService().setSoundEnabled(_soundEnabled);
    await AudioVoiceService().setMusicEnabled(_musicEnabled);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF42C485),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Parent settings saved successfully! ✨'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Parent Information',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Top information banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Row(
                children: [
                  Text('🔒', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parent & Guardian Portal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage app settings, audio preferences, and your child’s learning profile safely.',
                          style: TextStyle(fontSize: 12, color: inkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Parent Name Field
            const Text(
              'Guardian Name',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter parent or guardian name',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_rounded, color: purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Address (Optional but validated if entered)
            const Text(
              'Email Address (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'parent@example.com',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email_rounded, color: purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Preferred Language Dropdown
            const Text(
              'Preferred Learning Language',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _language,
                  isExpanded: true,
                  icon: const Icon(Icons.language_rounded, color: purple),
                  items: _languages
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(
                              lang,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: ink),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _language = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Parental Sound and Voice Settings
            const Text(
              'Audio & Voice Settings',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EFF5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Voice Pronunciation & Guidance',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Speaks letters, numbers, and words clearly',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: purple,
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Background Music & Melodies',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Gentle rhymes and music in activities',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeThumbColor: purple,
                    value: _musicEnabled,
                    onChanged: (v) => setState(() => _musicEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Parental Audio Diagnostics Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2EAF2), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Audio & Voice Diagnostics',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: mintLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Dev / Parent Tool',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: mintDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Verify that the teaching voice and sound player are working properly on this device.',
                    style: TextStyle(fontSize: 11, color: inkSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: BouncyButton(
                          onTap: _isTestingVoice ? () {} : _testVoice,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: purple, width: 1.5),
                            ),
                            child: _isTestingVoice
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(purple),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.record_voice_over_rounded,
                                          color: purple, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Test Voice',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: purple,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BouncyButton(
                          onTap: _isTestingAudio ? () {} : _testAudio,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: orange, width: 1.5),
                            ),
                            child: _isTestingAudio
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(orange),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.music_note_rounded,
                                          color: orange, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Test Music / SFX',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: orange,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_diagVoiceStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _diagVoiceStatus!.startsWith('Success')
                            ? mintLight
                            : coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _diagVoiceStatus!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _diagVoiceStatus!.startsWith('Success')
                              ? mintDeep
                              : coral,
                        ),
                      ),
                    ),
                  ],
                  if (_diagAudioStatus != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _diagAudioStatus!.startsWith('Success')
                            ? mintLight
                            : coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _diagAudioStatus!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _diagAudioStatus!.startsWith('Success')
                              ? mintDeep
                              : coral,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Action Button
            BouncyButton(
              onTap: _save,
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Nav to Baby Profile and Edit Baby Info
            Row(
              children: [
                Expanded(
                  child: BouncyButton(
                    onTap: widget.onOpenBabyProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: mintLight,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: mintDeep.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👶', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 6),
                          Text(
                            'Child Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: mintDeep,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BouncyButton(
                    onTap: widget.onEditBabyInfo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: goldLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: gold.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: orange, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Edit Child Info',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: orange,
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
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. Baby Information Screen (Editable Form)
// ============================================================================

class BabyInfoScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaveSuccess;

  const BabyInfoScreen({
    super.key,
    required this.onBack,
    required this.onSaveSuccess,
  });

  @override
  State<BabyInfoScreen> createState() => _BabyInfoScreenState();
}

class _BabyInfoScreenState extends State<BabyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();

  int _selectedAge = 4;
  String _selectedAvatar = 'Teddy';
  String _language = 'English';
  final List<String> _preferences = [];

  final List<String> _availablePreferences = const [
    'Phonics & Letters',
    'Numbers & Math',
    'Colors & Art',
    'Bedtime Stories',
    'Puzzles & Games',
    'Music & Songs',
  ];

  final List<(String, String)> _avatars = const [
    ('Teddy', '🧸'),
    ('Duckling', '🐥'),
    ('Kitten', '🐱'),
    ('Bunny', '🐰'),
    ('Puppy', '🐶'),
    ('Lion', '🦁'),
    ('Dolphin', '🐬'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baby = await ProfileRepository.loadBabyProfile();
    if (!mounted) return;
    setState(() {
      _nicknameController.text = baby.nickname;
      _selectedAge = baby.age;
      _selectedAvatar = baby.avatarName;
      _language = baby.language;
      _preferences.clear();
      _preferences.addAll(baby.preferences);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final baby = BabyProfile(
      nickname: _nicknameController.text.trim(),
      age: _selectedAge,
      avatarName: _selectedAvatar,
      language: _language,
      preferences: _preferences,
    );

    await ProfileRepository.saveBabyProfile(baby);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF42C485),
        content: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text("${baby.nickname}'s profile updated! ⭐"),
          ],
        ),
      ),
    );

    widget.onSaveSuccess();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Baby Information',
      onBack: widget.onBack,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Nickname Input
            const Text(
              "Child's First Name or Nickname",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: 'e.g. Emma, Leo, Maya',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.face_rounded, color: purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Please enter child's name";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Age selector (1 to 7)
            const Text(
              'Select Age (Years)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (i) {
                  final age = i + 1;
                  final isSelected = _selectedAge == age;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncyButton(
                      onTap: () => setState(() => _selectedAge = age),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? purple : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected ? purple : const Color(0xFFE5EFF5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? purple.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$age',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),

            // Avatar selection
            const Text(
              'Favorite Mascot Avatar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _avatars.map((av) {
                final isSelected = _selectedAvatar == av.$1;
                return BouncyButton(
                  onTap: () => setState(() => _selectedAvatar = av.$1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? lavender : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? purple : const Color(0xFFE5EFF5),
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(av.$2, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        Text(
                          av.$1,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected ? purple : ink,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Learning Preferences Checkboxes
            const Text(
              'Learning Preferences',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EFF5)),
              ),
              child: Column(
                children: _availablePreferences.map((pref) {
                  final isChecked = _preferences.contains(pref);
                  return CheckboxListTile(
                    title: Text(
                      pref,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: ink,
                      ),
                    ),
                    value: isChecked,
                    activeColor: purple,
                    dense: true,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _preferences.add(pref);
                        } else {
                          _preferences.remove(pref);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Save and Cancel buttons
            Row(
              children: [
                Expanded(
                  child: BouncyButton(
                    onTap: widget.onBack,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: inkSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: BouncyButton(
                    onTap: _save,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [purple, lavenderDeep],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Save Profile ⭐',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. Baby Profile Section (Display screen)
// ============================================================================

class BabyProfileScreen extends StatefulWidget {
  final int completedActivities;
  final Set<String> badges;
  final AnimationController bob;
  final VoidCallback onBack;
  final VoidCallback onEditProfile;

  const BabyProfileScreen({
    super.key,
    required this.completedActivities,
    required this.badges,
    required this.bob,
    required this.onBack,
    required this.onEditProfile,
  });

  @override
  State<BabyProfileScreen> createState() => _BabyProfileScreenState();
}

class _BabyProfileScreenState extends State<BabyProfileScreen> {
  BabyProfile _baby = BabyProfile();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await ProfileRepository.loadBabyProfile();
    if (mounted) setState(() => _baby = b);
  }

  String _getAvatarEmoji(String name) {
    switch (name) {
      case 'Duckling':
        return '🐥';
      case 'Kitten':
        return '🐱';
      case 'Bunny':
        return '🐰';
      case 'Puppy':
        return '🐶';
      case 'Lion':
        return '🦁';
      case 'Dolphin':
        return '🐬';
      default:
        return '🧸';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: "${_baby.nickname}'s Profile",
      onBack: widget.onBack,
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded, color: purple),
        onPressed: widget.onEditProfile,
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Mascot Avatar Card with Breathing Animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF9EE), Color(0xFFF3EDFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: purple.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_baby.avatarName == 'Teddy')
                  TeddyMascot(bob: widget.bob, size: 120)
                else
                  Text(
                    _getAvatarEmoji(_baby.avatarName),
                    style: const TextStyle(fontSize: 88),
                  ),
                const SizedBox(height: 12),
                Text(
                  _baby.nickname,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lavender, width: 1.5),
                  ),
                  child: Text(
                    '${_baby.age} Years Old • ${_baby.language}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: purple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Learning Statistics Overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🌟',
                  '${widget.completedActivities}',
                  'Completed Activities',
                  goldLight,
                  orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '🏅',
                  '${widget.badges.length}',
                  'Earned Badges',
                  lavender,
                  purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Learning Preferences Tags
          const Text(
            'Learning Interests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _baby.preferences.map((p) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
                ),
                child: Text(
                  '✨ $p',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Badges Unlocked Preview
          const Text(
            'Trophy Case',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5EFF5)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.badges.map((b) {
                return Chip(
                  backgroundColor: goldLight,
                  avatar: const Text('🏅', style: TextStyle(fontSize: 16)),
                  label: Text(
                    b,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                      fontSize: 12,
                    ),
                  ),
                  side: BorderSide(color: gold.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Edit Profile Action
          BouncyButton(
            onTap: widget.onEditProfile,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [purple, lavenderDeep],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Edit Child Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    String count,
    String label,
    Color bg,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

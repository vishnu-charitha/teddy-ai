import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'audio_voice_service.dart';
import 'design_system.dart';
import 'mascot.dart';
import 'profile_models.dart';

// ============================================================================
// 1. Parent Profile Screen (Dedicated, complete, detailed)
// ============================================================================

class ParentProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSwitchToBabyProfile;
  final VoidCallback? onSaveSuccess;
  final String? headerSubtitle;

  const ParentProfileScreen({
    super.key,
    required this.onBack,
    required this.onSwitchToBabyProfile,
    this.onSaveSuccess,
    this.headerSubtitle,
  });

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String _relationship = 'Mother';
  String _language = 'English';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _welcomeGreetingEnabled = true;
  bool _screenTimeLimitEnabled = true;
  int _screenTimeLimitMinutes = 30;
  bool _contentLockEnabled = true;

  ParentProfile? _initialProfile;

  final List<String> _relationships = const [
    'Mother',
    'Father',
    'Guardian',
    'Grandparent',
    'Caregiver',
    'Other',
  ];

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileRepository.loadParentProfile();
    if (!mounted) return;
    _initialProfile = profile;
    setState(() {
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _relationship = _relationships.contains(profile.relationship)
          ? profile.relationship
          : _relationships.first;
      _language = _languages.contains(profile.language)
          ? profile.language
          : _languages.first;
      _notificationsEnabled = profile.notificationsEnabled;
      _soundEnabled = profile.soundEnabled;
      _musicEnabled = profile.musicEnabled;
      _welcomeGreetingEnabled = profile.welcomeGreetingEnabled;
      _screenTimeLimitEnabled = profile.screenTimeLimitEnabled;
      _screenTimeLimitMinutes = profile.screenTimeLimitMinutes;
      _contentLockEnabled = profile.contentLockEnabled;
    });
  }

  bool _hasUnsavedChanges() {
    if (_initialProfile == null) return false;
    if (_nameController.text.trim() != _initialProfile!.name) return true;
    if (_emailController.text.trim() != _initialProfile!.email) return true;
    if (_phoneController.text.trim() != _initialProfile!.phone) return true;
    if (_relationship != _initialProfile!.relationship) return true;
    if (_language != _initialProfile!.language) return true;
    return false;
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedChanges()) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Discard Unsaved Changes? ⚠️',
              style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
          content: const Text(
              'You have modified parent contact details. Do you want to discard your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Editing',
                  style: TextStyle(fontWeight: FontWeight.w800, color: purple)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard',
                  style: TextStyle(fontWeight: FontWeight.w800, color: coral)),
            ),
          ],
        ),
      );
      if (discard == true) {
        widget.onBack();
      }
    } else {
      widget.onBack();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ParentProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      relationship: _relationship,
      language: _language,
      notificationsEnabled: _notificationsEnabled,
      soundEnabled: _soundEnabled,
      musicEnabled: _musicEnabled,
      welcomeGreetingEnabled: _welcomeGreetingEnabled,
      screenTimeLimitEnabled: _screenTimeLimitEnabled,
      screenTimeLimitMinutes: _screenTimeLimitMinutes,
      contentLockEnabled: _contentLockEnabled,
    );

    final success = await ProfileRepository.saveParentProfile(profile);
    await AudioVoiceService().setSoundEnabled(_soundEnabled);
    await AudioVoiceService().setMusicEnabled(_musicEnabled);
    await AudioVoiceService()
        .setWelcomeGreetingEnabled(_welcomeGreetingEnabled);

    if (!mounted) return;
    if (success) {
      _initialProfile = profile;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF42C485),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Parent profile saved successfully! ✨'),
            ],
          ),
        ),
      );
      if (widget.onSaveSuccess != null) {
        widget.onSaveSuccess!();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: coral,
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Failed to save parent profile. Please try again.'),
            ],
          ),
        ),
      );
    }
  }

  void _cancelEdit() {
    _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: lavenderDeep,
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Parent settings reset to saved profile.'),
          ],
        ),
      ),
    );
  }

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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: PageFrame(
        title: 'Parent Profile',
        onBack: _handleBack,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Switcher Tab Pill between Parent & Baby
                if (widget.headerSubtitle != null) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: lavender.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: purple.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.headerSubtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: purple,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _buildProfileSwitcher(isParentActive: true),
                  const SizedBox(height: 18),
                ],

                // Parent Avatar Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF2FF), Color(0xFFF7F0FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: purple.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _relationship == 'Father'
                              ? '👨‍💼'
                              : _relationship == 'Grandparent'
                                  ? '👵'
                                  : _relationship == 'Caregiver'
                                      ? '🧑‍⚕️'
                                      : '👩‍💼',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'Parent / Guardian',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_relationship • $_language',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailController.text.isNotEmpty
                                  ? _emailController.text
                                  : 'No email added',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: inkSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Information Section
                _buildSectionHeader(
                    'Contact & Relationship', Icons.person_rounded),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFF5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Full Name *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        enabled: true,
                        decoration: _inputDecoration(
                          hint: 'Enter your name',
                          icon: Icons.badge_rounded,
                          isEditing: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Email Address *'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        enabled: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hint: 'parent@example.com',
                          icon: Icons.email_rounded,
                          isEditing: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          final emailReg =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailReg.hasMatch(v.trim())) {
                            return 'Please enter a valid email (e.g. name@domain.com)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Phone Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        enabled: true,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: '+1 (555) 000-0000',
                          icon: Icons.phone_rounded,
                          isEditing: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Relationship'),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE5EFF5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value:
                                          _relationships.contains(_relationship)
                                              ? _relationship
                                              : _relationships.first,
                                      isExpanded: true,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: purple),
                                      borderRadius: BorderRadius.circular(16),
                                      dropdownColor: Colors.white,
                                      items: _relationships
                                          .map((r) => DropdownMenuItem<String>(
                                                value: r,
                                                child: Text(
                                                  r,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: ink,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _relationship = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Preferred Language'),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE5EFF5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _languages.contains(_language)
                                          ? _language
                                          : _languages.first,
                                      isExpanded: true,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: purple),
                                      borderRadius: BorderRadius.circular(16),
                                      dropdownColor: Colors.white,
                                      items: _languages
                                          .map((l) => DropdownMenuItem<String>(
                                                value: l,
                                                child: Text(
                                                  l,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: ink,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _language = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Audio & Voice Preferences
                _buildSectionHeader(
                    'Audio & Welcome Settings', Icons.volume_up_rounded),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFF5)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Voice Pronunciation & Guidance',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Speaks alphabet letters, numbers, and colors',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _soundEnabled,
                        onChanged: (v) async {
                          setState(() => _soundEnabled = v);
                          await AudioVoiceService().setSoundEnabled(v);
                          final p = await ProfileRepository.loadParentProfile();
                          p.soundEnabled = v;
                          await ProfileRepository.saveParentProfile(p);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Background Music & Rhymes',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Calm musical melodies during games and music player',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _musicEnabled,
                        onChanged: (v) async {
                          setState(() => _musicEnabled = v);
                          await AudioVoiceService().setMusicEnabled(v);
                          final p = await ProfileRepository.loadParentProfile();
                          p.musicEnabled = v;
                          await ProfileRepository.saveParentProfile(p);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Teddy Welcome Voice & Sound',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Teddy greets baby automatically when app opens',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _welcomeGreetingEnabled,
                        onChanged: (v) async {
                          setState(() => _welcomeGreetingEnabled = v);
                          await AudioVoiceService()
                              .setWelcomeGreetingEnabled(v);
                          final p = await ProfileRepository.loadParentProfile();
                          p.welcomeGreetingEnabled = v;
                          await ProfileRepository.saveParentProfile(p);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notifications & Parental Privacy Controls
                _buildSectionHeader(
                    'Privacy & Parental Controls', Icons.shield_rounded),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5EFF5)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Parent Activity Notifications',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Receive milestone summaries and badge alerts',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Daily Screen Time Limit',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$_screenTimeLimitMinutes minutes daily play limit',
                          style: const TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _screenTimeLimitEnabled,
                        onChanged: (v) =>
                            setState(() => _screenTimeLimitEnabled = v),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Parental Gate for Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Require parent confirmation to modify settings',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: purple,
                        value: _contentLockEnabled,
                        onChanged: (v) =>
                            setState(() => _contentLockEnabled = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Audio & Voice Diagnostics Tools
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFE2EAF2), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            '🔊 Audio & Speech Diagnostic Test',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Test whether the teaching voice and chime sound player are functioning on your device.',
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
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: purple, width: 1.5),
                                ),
                                child: _isTestingVoice
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  purple),
                                        ),
                                      )
                                    : const Text(
                                        'Test Voice 🗣️',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: purple,
                                        ),
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
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: mintDeep, width: 1.5),
                                ),
                                child: _isTestingAudio
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  mintDeep),
                                        ),
                                      )
                                    : const Text(
                                        'Test Sound 🔔',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: mintDeep,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_diagVoiceStatus != null ||
                          _diagAudioStatus != null) ...[
                        const SizedBox(height: 8),
                        if (_diagVoiceStatus != null)
                          Text(
                            _diagVoiceStatus!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _diagVoiceStatus!.startsWith('Success')
                                  ? mintDeep
                                  : coral,
                            ),
                          ),
                        if (_diagAudioStatus != null)
                          Text(
                            _diagAudioStatus!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _diagAudioStatus!.startsWith('Success')
                                  ? mintDeep
                                  : coral,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Profile Action Button (Full width, clearly visible)
                BouncyButton(
                  onTap: _save,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [purple, lavenderDeep],
                      ),
                      borderRadius: BorderRadius.circular(27),
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
                        Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Profile ⭐',
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
                const SizedBox(height: 10),
                BouncyButton(
                  onTap: _cancelEdit,
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel Changes',
                      style: TextStyle(
                        color: inkSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSwitcher({required bool isParentActive}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E9FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onSwitchToBabyProfile(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isParentActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isParentActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👶 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Baby Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isParentActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isParentActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👨‍👩‍👧 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Parent Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: purple, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: ink,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: ink,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isEditing,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isEditing ? Colors.white : const Color(0xFFF7FAFD),
      prefixIcon: Icon(icon, color: purple, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EFF5)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8EEF3)),
      ),
    );
  }
}

// ============================================================================
// 2. Baby Profile Screen (Dedicated, complete, detailed)
// ============================================================================

class BabyProfileScreen extends StatefulWidget {
  final int completedActivities;
  final Set<String> badges;
  final AnimationController bob;
  final VoidCallback onBack;
  final VoidCallback onEditProfile;
  final VoidCallback onSwitchToParentProfile;

  const BabyProfileScreen({
    super.key,
    required this.completedActivities,
    required this.badges,
    required this.bob,
    required this.onBack,
    required this.onEditProfile,
    required this.onSwitchToParentProfile,
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

  @override
  void didUpdateWidget(covariant BabyProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      case 'Koala':
        return '🐨';
      case 'Panda':
        return '🐼';
      default:
        return '🧸';
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
          // Switcher Tab Pill between Baby & Parent
          _buildProfileSwitcher(isParentActive: false),
          const SizedBox(height: 18),

          // Baby Hero Avatar Card with Breathing Mascot
          Container(
            padding: const EdgeInsets.all(22),
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
                  _baby.fullName.isNotEmpty ? _baby.fullName : _baby.nickname,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                if (_baby.fullName.isNotEmpty &&
                    _baby.fullName != _baby.nickname) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Nickname: "${_baby.nickname}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: inkSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPill('🎂 ${_baby.age} Years Old', lavender, purple),
                    const SizedBox(width: 8),
                    _buildPill(
                        '⚧ ${_baby.gender}', const Color(0xFFFFEEF2), coral),
                    const SizedBox(width: 8),
                    _buildPill('🌐 ${_baby.language}', mintLight, mintDeep),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Born: ${_formatDate(_baby.dateOfBirth)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Learning Progress & Milestones
          const Text(
            'Learning Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '🔤',
                  '26/26',
                  'Alphabet Phonics',
                  mintLight,
                  mintDeep,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '🔢',
                  '10/10',
                  'Numbers & Math',
                  goldLight,
                  orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '🎮',
                  '${widget.completedActivities}',
                  'Games Won',
                  lavender,
                  purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Favorites Section
          const Text(
            "Baby's Favorites",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5EFF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFavoriteGroup(
                    '🐾 Favorite Animals:', _baby.favoriteAnimals),
                const Divider(height: 20),
                _buildFavoriteGroup(
                    '🎨 Favorite Colors:', _baby.favoriteColors),
                const Divider(height: 20),
                _buildFavoriteGroup(
                    '🎈 Favorite Activities:', _baby.favoriteActivities),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Learning Interests Tags
          const Text(
            'Curiosity Topics',
            style: TextStyle(
              fontSize: 18,
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

          // Badges Unlocked Section
          const Text(
            'Trophy Case & Badges',
            style: TextStyle(
              fontSize: 18,
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
                    'Edit Baby Profile',
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

  Widget _buildProfileSwitcher({required bool isParentActive}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFE4E9FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isParentActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !isParentActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👶 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Baby Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onSwitchToParentProfile(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isParentActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isParentActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('👨‍👩‍👧 ', style: TextStyle(fontSize: 14)),
                    Text(
                      'Parent Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildFavoriteGroup(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: inkSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((it) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EFF5)),
              ),
              child: Text(
                it,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. Baby Information Screen (Complete Editable Form)
// ============================================================================

class BabyInfoScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaveSuccess;
  final String? headerSubtitle;

  const BabyInfoScreen({
    super.key,
    required this.onBack,
    required this.onSaveSuccess,
    this.headerSubtitle,
  });

  @override
  State<BabyInfoScreen> createState() => _BabyInfoScreenState();
}

class _BabyInfoScreenState extends State<BabyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _nicknameController;

  DateTime _selectedDob = DateTime(2022, 4, 15);
  int _selectedAge = 4;
  String _gender = 'Girl';
  String _selectedAvatar = 'Teddy';
  String _language = 'English';

  final List<String> _favoriteAnimals = [];
  final List<String> _favoriteColors = [];
  final List<String> _favoriteActivities = [];
  final List<String> _preferences = [];

  BabyProfile? _initialBaby;

  final List<String> _genders = const ['Girl', 'Boy', 'Prefer not to say'];

  final List<String> _availableAnimals = const [
    'Teddy Bear',
    'Bunny',
    'Kitten',
    'Puppy',
    'Duckling',
    'Dolphin',
    'Panda',
    'Elephant',
  ];

  final List<String> _availableColors = const [
    'Pastel Pink',
    'Sky Blue',
    'Mint Green',
    'Sunshine Yellow',
    'Lavender Purple',
    'Peach Orange',
  ];

  final List<String> _availableActivities = const [
    'Alphabet Rhymes',
    'Coloring Butterfly',
    'Music & Dance',
    'Counting Numbers',
    'Matching Games',
    'Bedtime Stories',
  ];

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
    ('Koala', '🐨'),
    ('Panda', '🐼'),
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _nicknameController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final baby = await ProfileRepository.loadBabyProfile();
    if (!mounted) return;
    _initialBaby = baby;
    setState(() {
      _fullNameController.text = baby.fullName;
      _nicknameController.text = baby.nickname;
      _selectedDob = baby.dateOfBirth;
      _selectedAge = baby.age;
      _gender = baby.gender;
      _selectedAvatar = baby.avatarName;
      _language = baby.language;

      _favoriteAnimals.clear();
      _favoriteAnimals.addAll(baby.favoriteAnimals);

      _favoriteColors.clear();
      _favoriteColors.addAll(baby.favoriteColors);

      _favoriteActivities.clear();
      _favoriteActivities.addAll(baby.favoriteActivities);

      _preferences.clear();
      _preferences.addAll(baby.preferences);
    });
  }

  bool _hasUnsavedChanges() {
    if (_initialBaby == null) return false;
    if (_fullNameController.text.trim() != _initialBaby!.fullName) return true;
    if (_nicknameController.text.trim() != _initialBaby!.nickname) return true;
    if (_selectedDob != _initialBaby!.dateOfBirth) return true;
    if (_selectedAge != _initialBaby!.age) return true;
    if (_gender != _initialBaby!.gender) return true;
    if (_selectedAvatar != _initialBaby!.avatarName) return true;
    if (_language != _initialBaby!.language) return true;
    if (!listEquals(_favoriteAnimals, _initialBaby!.favoriteAnimals)) {
      return true;
    }
    if (!listEquals(_favoriteColors, _initialBaby!.favoriteColors)) {
      return true;
    }
    if (!listEquals(_favoriteActivities, _initialBaby!.favoriteActivities)) {
      return true;
    }
    if (!listEquals(_preferences, _initialBaby!.preferences)) {
      return true;
    }
    return false;
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedChanges()) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Discard Unsaved Changes? ⚠️',
              style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
          content: const Text(
              "You have modified baby profile details. Do you want to discard your changes?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Editing',
                  style: TextStyle(fontWeight: FontWeight.w800, color: purple)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard',
                  style: TextStyle(fontWeight: FontWeight.w800, color: coral)),
            ),
          ],
        ),
      );
      if (discard == true) {
        widget.onBack();
      }
    } else {
      widget.onBack();
    }
  }

  Future<void> _selectDob(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _selectedAge = BabyProfile.calculateAge(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final baby = BabyProfile(
        fullName: _fullNameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        dateOfBirth: _selectedDob,
        age: _selectedAge,
        gender: _gender,
        avatarName: _selectedAvatar,
        language: _language,
        favoriteAnimals: List.from(_favoriteAnimals),
        favoriteColors: List.from(_favoriteColors),
        favoriteActivities: List.from(_favoriteActivities),
        preferences: List.from(_preferences),
      );

      final success = await ProfileRepository.saveBabyProfile(baby);
      if (!success) {
        throw Exception('Failed to save baby profile');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: coral,
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Failed to save profile. Please try again.'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: PageFrame(
        title: 'Edit Baby Profile',
        onBack: _handleBack,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.headerSubtitle != null) ...[
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: lavender.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: purple.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      widget.headerSubtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: purple,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Full Name Input
                const Text(
                  "Full Name",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Emma Rose Johnson',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.badge_rounded, color: purple),
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
                      return "Please enter child's full name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nickname Input
                const Text(
                  "Nickname (Used by Teddy) *",
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
                      return "Please enter a nickname";
                    }
                    if (v.trim().length < 2) {
                      return "Nickname must be at least 2 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth & Computed Age
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          BouncyButton(
                            onTap: () => _selectDob(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFE5EFF5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      color: purple, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(_selectedDob),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Age (Years)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: lavender,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: purple.withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$_selectedAge y/o',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: purple,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Selection
                const Text(
                  'Gender (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _genders.map((g) {
                    final isSelected = _gender == g;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BouncyButton(
                          onTap: () => setState(() => _gender = g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? purple : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? purple
                                    : const Color(0xFFE5EFF5),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              g,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Avatar Mascot Selection
                const Text(
                  'Select Mascot Avatar',
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? lavender : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                isSelected ? purple : const Color(0xFFE5EFF5),
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

                // Favorite Animals
                _buildMultiSelectSection(
                  title: 'Favorite Animals',
                  items: _availableAnimals,
                  selected: _favoriteAnimals,
                  onToggle: (item) {
                    setState(() {
                      if (_favoriteAnimals.contains(item)) {
                        _favoriteAnimals.remove(item);
                      } else {
                        _favoriteAnimals.add(item);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Favorite Colors
                _buildMultiSelectSection(
                  title: 'Favorite Colors',
                  items: _availableColors,
                  selected: _favoriteColors,
                  onToggle: (item) {
                    setState(() {
                      if (_favoriteColors.contains(item)) {
                        _favoriteColors.remove(item);
                      } else {
                        _favoriteColors.add(item);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Favorite Activities
                _buildMultiSelectSection(
                  title: 'Favorite Activities',
                  items: _availableActivities,
                  selected: _favoriteActivities,
                  onToggle: (item) {
                    setState(() {
                      if (_favoriteActivities.contains(item)) {
                        _favoriteActivities.remove(item);
                      } else {
                        _favoriteActivities.add(item);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Learning Topics
                _buildMultiSelectSection(
                  title: 'Learning Interests',
                  items: _availablePreferences,
                  selected: _preferences,
                  onToggle: (item) {
                    setState(() {
                      if (_preferences.contains(item)) {
                        _preferences.remove(item);
                      } else {
                        _preferences.add(item);
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Save Profile Action Button (Full width, clearly visible)
                BouncyButton(
                  onTap: _save,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [purple, lavenderDeep],
                      ),
                      borderRadius: BorderRadius.circular(27),
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
                        Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Save Profile ⭐',
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
                const SizedBox(height: 10),
                BouncyButton(
                  onTap: _handleBack,
                  child: Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel Changes',
                      style: TextStyle(
                        color: inkSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required List<String> items,
    required List<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((it) {
            final isSelected = selected.contains(it);
            return BouncyButton(
              onTap: () => onToggle(it),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? mintLight : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? mintDeep : const Color(0xFFE5EFF5),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                ),
                child: Text(
                  isSelected ? '✓ $it' : '+ $it',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? mintDeep : ink,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// 4. Onboarding Review & Confirmation Screen (Step 3 of 3)
// ============================================================================

class OnboardingReviewScreen extends StatelessWidget {
  final ParentProfile parentProfile;
  final BabyProfile babyProfile;
  final VoidCallback onBack;
  final VoidCallback onConfirmAndEnter;
  final VoidCallback onEditParent;
  final VoidCallback onEditBaby;

  const OnboardingReviewScreen({
    super.key,
    required this.parentProfile,
    required this.babyProfile,
    required this.onBack,
    required this.onConfirmAndEnter,
    required this.onEditParent,
    required this.onEditBaby,
  });

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Review Profiles',
      onBack: onBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress tracker badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: lavender.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: purple.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Step 3 of 3: Confirmation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: purple,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Almost ready! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please review your profiles below before entering Teddy AI learning adventure.',
              style: TextStyle(
                fontSize: 14,
                color: inkSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Parent Profile Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4EDF5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('👨‍👩‍👧 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'Parent Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: onEditParent,
                        icon: const Icon(Icons.edit_rounded,
                            size: 16, color: purple),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: purple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF0F4F8)),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                      'Name',
                      parentProfile.name.isNotEmpty
                          ? parentProfile.name
                          : 'Sarah Johnson'),
                  _buildSummaryRow('Email', parentProfile.email),
                  _buildSummaryRow('Relationship', parentProfile.relationship),
                  _buildSummaryRow('Language', parentProfile.language),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Baby Profile Summary Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4EDF5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D2850).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('👶 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'Child Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: onEditBaby,
                        icon: const Icon(Icons.edit_rounded,
                            size: 16, color: purple),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: purple,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF0F4F8)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Nickname', babyProfile.nickname),
                  if (babyProfile.fullName.isNotEmpty)
                    _buildSummaryRow('Full Name', babyProfile.fullName),
                  _buildSummaryRow('Age', '${babyProfile.age} Years Old'),
                  _buildSummaryRow(
                      'Date of Birth', _formatDate(babyProfile.dateOfBirth)),
                  _buildSummaryRow('Mascot Avatar', babyProfile.avatarName),
                  _buildSummaryRow('Gender', babyProfile.gender),
                  if (babyProfile.favoriteAnimals.isNotEmpty)
                    _buildSummaryRow('Favorite Animals',
                        babyProfile.favoriteAnimals.take(3).join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notice about local profile storage vs remote backend
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD3E4FF)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined,
                      color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Privacy Notice: Profiles are saved locally on this device. Future updates can link to secure cloud authentication.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm & Enter Button
            BouncyButton(
              onTap: onConfirmAndEnter,
              child: Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9E2C), Color(0xFFFF6F59)],
                  ),
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6F59).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Enter Teddy AI Dashboard ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            BouncyButton(
              onTap: onBack,
              child: Container(
                height: 44,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Back to Baby Profile',
                  style: TextStyle(
                    color: inkSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: inkSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Backward compatibility alias for ParentInfoScreen
typedef ParentInfoScreen = ParentProfileScreen;

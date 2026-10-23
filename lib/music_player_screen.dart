import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'audio_voice_service.dart';
import 'design_system.dart';

/// Full-featured, child-friendly Music Player screen with vinyl record animation,
/// transport controls, progress tracking, volume slider, and animal accompaniment.
class MusicPlayerScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MusicPlayerScreen({super.key, required this.onBack});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioVoiceService _audio = AudioVoiceService();
  late final AnimationController _recordRotator;

  @override
  void initState() {
    super.initState();
    _recordRotator = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _audio.addListener(_handleAudioState);
  }

  void _handleAudioState() {
    if (mounted) {
      if (_audio.isPlayingMusic) {
        if (!_recordRotator.isAnimating) _recordRotator.repeat();
      } else {
        if (_recordRotator.isAnimating) _recordRotator.stop();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audio.removeListener(_handleAudioState);
    _recordRotator.dispose();
    // Stop playback on exit as requested:
    // "Ensure navigation away from the music screen does not leave unwanted audio playing."
    _audio.pauseMusic();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final track = _audio.currentTrack;
    final pos = _audio.currentPosition;
    final dur = _audio.totalDuration;
    final progress =
        dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;

    return PageFrame(
      title: "Teddy's Music Room",
      onBack: widget.onBack,
      trailing: IconButton(
        icon: Icon(
          _audio.musicEnabled
              ? Icons.music_note_rounded
              : Icons.music_off_rounded,
          color: purple,
          size: 26,
        ),
        onPressed: () => _audio.setMusicEnabled(!_audio.musicEnabled),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Vinyl Record with Teddy Mascot Center
            Center(
              child: AnimatedBuilder(
                animation: _recordRotator,
                builder: (context, child) => Transform.rotate(
                  angle: _recordRotator.value * 2 * math.pi,
                  child: child,
                ),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF1E2433),
                        Color(0xFF2C3549),
                        Color(0xFF151922),
                      ],
                      stops: [0.35, 0.75, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF151922).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: goldLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(track.emoji,
                          style: const TextStyle(fontSize: 42)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Track title and artist
            Text(
              track.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: inkSecondary,
              ),
            ),

            if (_audio.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: mintLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _audio.errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: mintDeep,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Progress Bar and Timers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: purple,
                      inactiveTrackColor: lavender,
                      thumbColor: purple,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (v) {
                        final targetMs = (v * dur.inMilliseconds).round();
                        _audio.seek(Duration(milliseconds: targetMs));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(pos),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: inkSecondary,
                          ),
                        ),
                        Text(
                          _formatDuration(dur),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transport controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous track
                BouncyButton(
                  onTap: () => _audio.previousTrack(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.skip_previous_rounded,
                        color: ink, size: 28),
                  ),
                ),
                const SizedBox(width: 14),

                // Replay / Rewind
                BouncyButton(
                  onTap: () => _audio.replayTrack(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.replay_rounded,
                        color: inkSecondary, size: 24),
                  ),
                ),
                const SizedBox(width: 14),

                // Big Play / Pause
                BouncyButton(
                  onTap: () => _audio.togglePlayPause(),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [purple, lavenderDeep],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: purple.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _audio.isLoadingMusic
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _audio.isPlayingMusic
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Next track
                BouncyButton(
                  onTap: () => _audio.nextTrack(),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.skip_next_rounded,
                        color: ink, size: 28),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Volume Control
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_down_rounded,
                      color: inkSecondary, size: 22),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: orange,
                        inactiveTrackColor: cream,
                        thumbColor: orange,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _audio.musicVolume,
                        onChanged: (v) => _audio.setMusicVolume(v),
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: orange, size: 22),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Playful Animal Instruments
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Play along with instruments!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInstrumentButton('🎹', 'Piano', () {
                  _audio.playInstrumentSfx('piano');
                }),
                _buildInstrumentButton('🥁', 'Drum', () {
                  _audio.playInstrumentSfx('drum');
                }),
                _buildInstrumentButton('🔔', 'Chime', () {
                  _audio.playInstrumentSfx('chime');
                }),
                _buildInstrumentButton('🎸', 'Guitar', () {
                  _audio.playInstrumentSfx('guitar');
                }),
              ],
            ),

            const SizedBox(height: 20),

            // Song Playlist selection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nursery Rhymes Playlist',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_audio.tracks.length, (i) {
              final t = _audio.tracks[i];
              final isCurrent = i == _audio.currentTrackIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: BouncyButton(
                  onTap: () => _audio.playTrack(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? lavender : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? purple : const Color(0xFFE5EFF5),
                        width: isCurrent ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isCurrent ? FontWeight.w900 : FontWeight.w700,
                              color: isCurrent ? purple : ink,
                            ),
                          ),
                        ),
                        if (isCurrent && _audio.isPlayingMusic)
                          const Icon(Icons.equalizer_rounded,
                              color: purple, size: 22)
                        else
                          const Icon(Icons.play_circle_outline_rounded,
                              color: inkSecondary, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentButton(String emoji, String name, VoidCallback onTap) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

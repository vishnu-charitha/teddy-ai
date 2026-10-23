import os
import math
import struct
import wave

SAMPLE_RATE = 44100

def get_freq(note_name):
    notes = {'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4,
             'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8, 'A': 9,
             'A#': 10, 'Bb': 10, 'B': 11}
    # e.g., 'C4', 'G3', 'A4', 'R' (rest)
    if note_name == 'R' or note_name == ' ' or not note_name:
        return 0.0
    name = note_name[:-1]
    octave = int(note_name[-1])
    semitones = notes[name] + (octave - 4) * 12
    # A4 is 440 Hz -> 9 semitones above C4 (so C4 is semitones=0)
    return 440.0 * (2.0 ** ((semitones - 9) / 12.0))

def synthesize_melody(notes_with_durations, bpm=120, instrument='music_box'):
    """
    notes_with_durations: list of (note_str, duration_in_beats)
    instrument: 'music_box', 'chime', 'piano', 'guitar'
    """
    beat_sec = 60.0 / bpm
    total_samples = []

    for note, beats in notes_with_durations:
        freq = get_freq(note)
        duration_sec = beats * beat_sec
        num_samples = int(duration_sec * SAMPLE_RATE)

        if freq == 0:
            total_samples.extend([0.0] * num_samples)
            continue

        for i in range(num_samples):
            t = i / SAMPLE_RATE
            # Envelope: fast attack, exponential decay for bell/music box
            decay = math.exp(-3.0 * t / duration_sec)
            attack = min(1.0, t / 0.015)
            env = attack * decay

            # Timbre harmonics
            if instrument == 'music_box':
                val = 0.6 * math.sin(2 * math.pi * freq * t)
                val += 0.25 * math.sin(2 * math.pi * (freq * 2) * t)
                val += 0.12 * math.sin(2 * math.pi * (freq * 3) * t)
                val += 0.05 * math.sin(2 * math.pi * (freq * 4) * t)
            elif instrument == 'piano':
                val = 0.7 * math.sin(2 * math.pi * freq * t)
                val += 0.2 * math.sin(2 * math.pi * (freq * 2) * t)
                val += 0.1 * math.sin(2 * math.pi * (freq * 3) * t)
            else:
                val = 0.5 * math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(2 * math.pi * freq * 2 * t)

            total_samples.append(val * env * 0.7)

    return total_samples

def save_wav(samples, file_path):
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    with wave.open(file_path, 'wb') as wav:
        wav.setnchannels(1) # mono
        wav.setsampwidth(2) # 16-bit
        wav.setframerate(SAMPLE_RATE)
        
        frames = bytearray()
        for s in samples:
            # clamp
            s_clamped = max(-1.0, min(1.0, s))
            int_val = int(s_clamped * 32767.0)
            frames.extend(struct.pack('<h', int_val))
        wav.writeframes(frames)
    print(f"Generated: {file_path} ({len(samples)/SAMPLE_RATE:.1f}s)")

def main():
    target_dir = r"C:\Users\VISHNUCHARITHA\teddy_ai\assets\audio"
    os.makedirs(target_dir, exist_ok=True)

    # 1. Twinkle Twinkle Little Star
    twinkle = [
        ('C4', 1), ('C4', 1), ('G4', 1), ('G4', 1), ('A4', 1), ('A4', 1), ('G4', 2),
        ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 1), ('D4', 1), ('C4', 2),
        ('G4', 1), ('G4', 1), ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('G4', 1), ('G4', 1), ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('C4', 1), ('C4', 1), ('G4', 1), ('G4', 1), ('A4', 1), ('A4', 1), ('G4', 2),
        ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 1), ('D4', 1), ('C4', 2),
        ('R', 1),
    ]
    save_wav(synthesize_melody(twinkle, bpm=100, instrument='music_box'), os.path.join(target_dir, 'twinkle_twinkle.wav'))

    # 2. Old MacDonald Had a Farm
    old_macdonald = [
        ('G4', 1), ('G4', 1), ('G4', 1), ('D4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('B4', 1), ('B4', 1), ('A4', 1), ('A4', 1), ('G4', 2), ('R', 1),
        ('D4', 1), ('G4', 1), ('G4', 1), ('G4', 1), ('D4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('B4', 1), ('B4', 1), ('A4', 1), ('A4', 1), ('G4', 2), ('R', 1),
        ('D4', 0.5), ('D4', 0.5), ('G4', 1), ('G4', 1), ('G4', 1), ('D4', 0.5), ('D4', 0.5), ('G4', 1), ('G4', 1), ('G4', 1),
        ('G4', 0.5), ('G4', 0.5), ('G4', 1), ('G4', 0.5), ('G4', 0.5), ('G4', 1), ('G4', 0.5), ('G4', 0.5), ('G4', 0.5), ('G4', 0.5), ('G4', 1), ('G4', 1),
        ('G4', 1), ('G4', 1), ('G4', 1), ('D4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('B4', 1), ('B4', 1), ('A4', 1), ('A4', 1), ('G4', 2), ('R', 1),
    ]
    save_wav(synthesize_melody(old_macdonald, bpm=115, instrument='music_box'), os.path.join(target_dir, 'old_macdonald.wav'))

    # 3. The Wheels on the Bus
    wheels = [
        ('D4', 1), ('G4', 1), ('G4', 0.5), ('G4', 0.5), ('G4', 1), ('B4', 1), ('D5', 1), ('B4', 1), ('G4', 2),
        ('A4', 1), ('D4', 1), ('D4', 2), ('B4', 1), ('G4', 1), ('G4', 2),
        ('D4', 1), ('G4', 1), ('G4', 0.5), ('G4', 0.5), ('G4', 1), ('B4', 1), ('D5', 1), ('B4', 1), ('G4', 2),
        ('A4', 1), ('D4', 1), ('G4', 2), ('R', 1),
    ]
    save_wav(synthesize_melody(wheels, bpm=120, instrument='music_box'), os.path.join(target_dir, 'wheels_on_bus.wav'))

    # 4. Row Row Row Your Boat
    row_boat = [
        ('C4', 1.5), ('C4', 1.5), ('C4', 1), ('D4', 0.5), ('E4', 1.5),
        ('E4', 1), ('D4', 0.5), ('E4', 1), ('F4', 0.5), ('G4', 3),
        ('C5', 0.5), ('C5', 0.5), ('C5', 0.5), ('G4', 0.5), ('G4', 0.5), ('G4', 0.5),
        ('E4', 0.5), ('E4', 0.5), ('E4', 0.5), ('C4', 0.5), ('C4', 0.5), ('C4', 0.5),
        ('G4', 1), ('F4', 0.5), ('E4', 1), ('D4', 0.5), ('C4', 3), ('R', 1),
    ]
    save_wav(synthesize_melody(row_boat, bpm=105, instrument='music_box'), os.path.join(target_dir, 'row_row_boat.wav'))

    # 5. Alphabet Song
    abc = [
        ('C4', 1), ('C4', 1), ('G4', 1), ('G4', 1), ('A4', 1), ('A4', 1), ('G4', 2),
        ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 1), ('D4', 1), ('C4', 2),
        ('G4', 1), ('G4', 0.5), ('G4', 0.5), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('G4', 1), ('G4', 1), ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 2),
        ('C4', 1), ('C4', 1), ('G4', 1), ('G4', 1), ('A4', 1), ('A4', 1), ('G4', 2),
        ('F4', 1), ('F4', 1), ('E4', 1), ('E4', 1), ('D4', 1), ('D4', 1), ('C4', 2),
        ('R', 1),
    ]
    save_wav(synthesize_melody(abc, bpm=95, instrument='music_box'), os.path.join(target_dir, 'alphabet_song.wav'))

    # 6. Instrument Sound Effects
    # Piano chord arpeggio
    piano = [('C4', 0.2), ('E4', 0.2), ('G4', 0.2), ('C5', 0.8)]
    save_wav(synthesize_melody(piano, bpm=120, instrument='piano'), os.path.join(target_dir, 'piano_note.wav'))

    # Drum beat (synthesized punchy click/thump)
    drum_samples = []
    for i in range(int(0.35 * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        freq = 150.0 * math.exp(-25.0 * t) + 45.0
        val = math.sin(2 * math.pi * freq * t) * math.exp(-12.0 * t)
        drum_samples.append(val * 0.85)
    save_wav(drum_samples, os.path.join(target_dir, 'drum_beat.wav'))

    # Chime sparkle
    chime = [('C5', 0.15), ('E5', 0.15), ('G5', 0.15), ('B5', 0.15), ('C6', 0.6)]
    save_wav(synthesize_melody(chime, bpm=140, instrument='music_box'), os.path.join(target_dir, 'chime_sparkle.wav'))

    # Guitar strum (G major arpeggio)
    guitar = [('G3', 0.08), ('B3', 0.08), ('D4', 0.08), ('G4', 0.08), ('B4', 0.08), ('G4', 0.5)]
    save_wav(synthesize_melody(guitar, bpm=120, instrument='music_box'), os.path.join(target_dir, 'guitar_chord.wav'))

    # Test beep / chime for diagnostic test
    test_chime = [('A4', 0.2), ('E5', 0.2), ('A5', 0.5)]
    save_wav(synthesize_melody(test_chime, bpm=130, instrument='music_box'), os.path.join(target_dir, 'test_beep.wav'))

    print("All audio assets generated successfully!")

if __name__ == '__main__':
    main()

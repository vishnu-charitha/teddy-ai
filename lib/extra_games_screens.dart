import 'dart:async';
import 'package:flutter/material.dart';
import 'audio_voice_service.dart';
import 'design_system.dart';

// ============================================================================
// 1. Puzzle Time Game Screen (Animal / Shape Matching Puzzle)
// ============================================================================

class PuzzleGameScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const PuzzleGameScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzlePiece {
  final int id;
  final String emoji;
  final String name;
  final Color color;

  const _PuzzlePiece({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
  });
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  final List<_PuzzlePiece> _pieces = const [
    _PuzzlePiece(id: 0, emoji: '🦁', name: 'Lion', color: Color(0xFFFFD447)),
    _PuzzlePiece(id: 1, emoji: '🐰', name: 'Bunny', color: Color(0xFFD4E6FF)),
    _PuzzlePiece(
        id: 2, emoji: '🐥', name: 'Duckling', color: Color(0xFFFFE0D9)),
    _PuzzlePiece(id: 3, emoji: '🐱', name: 'Kitten', color: Color(0xFFD7FFED)),
  ];

  final Set<int> _placed = {};
  int? _selectedPieceId;
  String _feedbackMessage =
      'Tap a friendly animal, then tap its matching spot!';
  bool _finished = false;

  void _onTapPiece(int id) {
    if (_placed.contains(id)) return;
    setState(() {
      _selectedPieceId = id;
      _feedbackMessage = 'Now tap where ${_pieces[id].name} belongs!';
    });
    AudioVoiceService().speak('Find the spot for ${_pieces[id].name}!');
  }

  void _onTapTarget(int targetId) {
    if (_placed.contains(targetId)) return;
    if (_selectedPieceId == null) {
      setState(() {
        _feedbackMessage = 'Pick an animal first!';
      });
      return;
    }

    if (_selectedPieceId == targetId) {
      // Correct match!
      setState(() {
        _placed.add(targetId);
        _selectedPieceId = null;
        _feedbackMessage = 'Great job! ${_pieces[targetId].name} is home! ⭐';
      });
      AudioVoiceService().speakEncouragement(
          'Super! You matched the ${_pieces[targetId].name}!');

      if (_placed.length == _pieces.length && !_finished) {
        _finished = true;
        setState(() {
          _feedbackMessage = '🎉 Puzzle Complete! You are a Puzzle Master!';
        });
        AudioVoiceService().speak('Hooray! You completed the puzzle!');
        widget.onComplete();
      }
    } else {
      // Incorrect match
      setState(() {
        _feedbackMessage =
            'Oops, that’s not ${_pieces[_selectedPieceId!].name}’s spot! Try again!';
      });
      AudioVoiceService().speak('Try another spot!');
    }
  }

  void _reset() {
    setState(() {
      _placed.clear();
      _selectedPieceId = null;
      _finished = false;
      _feedbackMessage = 'Tap an animal, then tap its matching spot!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Puzzle Time',
      onBack: widget.onBack,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: purple, size: 26),
        onPressed: _reset,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('Pieces: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, color: ink)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _placed.length / _pieces.length,
                        minHeight: 12,
                        backgroundColor: sky.withValues(alpha: 0.3),
                        color: const Color(0xFF42C485),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_placed.length}/${_pieces.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: ink,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Friendly Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: goldLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target Slots Grid (2x2)
            const Text(
              'Target Puzzle Board',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: inkSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: List.generate(_pieces.length, (i) {
                  final p = _pieces[i];
                  final isPlaced = _placed.contains(i);
                  final isSelectedTarget = _selectedPieceId == i;

                  return GestureDetector(
                    onTap: () => _onTapTarget(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isPlaced ? p.color : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isPlaced
                              ? const Color(0xFF42C485)
                              : (isSelectedTarget
                                  ? purple
                                  : const Color(0xFFCBD6E2)),
                          width: isPlaced ? 3 : 2,
                          style:
                              isPlaced ? BorderStyle.solid : BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: isPlaced
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(p.emoji,
                                        style: const TextStyle(fontSize: 42)),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: ink,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.crop_free_rounded,
                                        color: Colors.grey.shade400, size: 32),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Slot ${p.name}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // Available Pieces Row
            const Text(
              'Animal Pieces',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: inkSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_pieces.length, (i) {
                final p = _pieces[i];
                final isPlaced = _placed.contains(i);
                final isSelected = _selectedPieceId == i;

                if (isPlaced) {
                  return Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFF42C485)),
                  );
                }

                return BouncyButton(
                  onTap: () => _onTapPiece(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isSelected ? lavender : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? purple : const Color(0xFFE5EFF5),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? purple.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(p.emoji, style: const TextStyle(fontSize: 34)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            if (_finished)
              BouncyButton(
                onTap: _reset,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [purple, lavenderDeep]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Play Again ⭐',
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

// ============================================================================
// 2. Sorting Fun Game Screen (Fruits vs Animals Basket Sorting)
// ============================================================================

class SortingGameScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const SortingGameScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  @override
  State<SortingGameScreen> createState() => _SortingGameScreenState();
}

class _SortItem {
  final String emoji;
  final String name;
  final bool isFruit; // true = Fruit, false = Animal

  const _SortItem({
    required this.emoji,
    required this.name,
    required this.isFruit,
  });
}

class _SortingGameScreenState extends State<SortingGameScreen> {
  final List<_SortItem> _items = const [
    _SortItem(emoji: '🍎', name: 'Apple', isFruit: true),
    _SortItem(emoji: '🐶', name: 'Puppy', isFruit: false),
    _SortItem(emoji: '🍌', name: 'Banana', isFruit: true),
    _SortItem(emoji: '🦁', name: 'Lion', isFruit: false),
    _SortItem(emoji: '🍓', name: 'Strawberry', isFruit: true),
    _SortItem(emoji: '🐱', name: 'Kitten', isFruit: false),
    _SortItem(emoji: '🍇', name: 'Grapes', isFruit: true),
    _SortItem(emoji: '🐼', name: 'Panda', isFruit: false),
  ];

  int _currentIndex = 0;
  int _score = 0;
  String _hint = 'Tap the correct basket!';
  bool _finished = false;
  bool _locked = false;

  void _chooseBasket(bool choseFruit) {
    if (_finished || _locked) return;
    final current = _items[_currentIndex];

    if (current.isFruit == choseFruit) {
      // Correct!
      _locked = true;
      setState(() {
        _score++;
        _hint = 'Correct! ${current.name} belongs there! 🌟';
      });
      AudioVoiceService().speakEncouragement('Yum! Correct basket!');

      Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (_currentIndex + 1 < _items.length) {
          setState(() {
            _currentIndex++;
            _hint = 'Where does this one belong?';
            _locked = false;
          });
        } else {
          setState(() {
            _finished = true;
            _locked = false;
            _hint = '🎉 Fantastic! You sorted everything!';
          });
          AudioVoiceService().speak('Hooray! You are a Sorting Star!');
          widget.onComplete();
        }
      });
    } else {
      // Wrong choice
      final target = current.isFruit ? 'Fruit' : 'Animal';
      setState(() {
        _hint = 'Oops! ${current.name} is a $target! Try again!';
      });
      AudioVoiceService().speak('Oops! Try the other basket!');
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _finished = false;
      _locked = false;
      _hint = 'Tap the correct basket!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _items[_currentIndex];

    return PageFrame(
      title: 'Sorting Fun',
      onBack: widget.onBack,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: purple, size: 26),
        onPressed: _restart,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score and Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
              ),
              child: Row(
                children: [
                  Text('Score: $_score  •  Items: ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: ink)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _currentIndex / _items.length,
                        minHeight: 10,
                        backgroundColor: sky.withValues(alpha: 0.3),
                        color: orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_currentIndex/${_items.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Hint Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _hint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: purple,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Center Item Card
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _finished
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🏆⭐🎉', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text(
                                'All Sorted!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: ink,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  current.emoji,
                                  key: ValueKey(current.emoji),
                                  style: const TextStyle(fontSize: 72),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                current.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Two Destination Baskets (Fruits Basket vs Animals Basket)
            Row(
              children: [
                Expanded(
                  child: BouncyButton(
                    onTap: () => _chooseBasket(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0D9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Text('🍎🧺', style: TextStyle(fontSize: 38)),
                          SizedBox(height: 6),
                          Text(
                            'Fruits Basket',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFC7362E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: BouncyButton(
                    onTap: () => _chooseBasket(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: mintLight,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Text('🐾🧺', style: TextStyle(fontSize: 38)),
                          SizedBox(height: 6),
                          Text(
                            'Animals Basket',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: mintDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_finished)
              BouncyButton(
                onTap: _restart,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [purple, lavenderDeep]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Play Again ⭐',
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

// ============================================================================
// 3. Memory Sequence Game Screen
// ============================================================================

class MemoryGameScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const MemoryGameScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<(String, String)> _characters = const [
    ('🐶', 'Puppy'),
    ('🐱', 'Kitty'),
    ('🐥', 'Duckling'),
    ('🐰', 'Bunny'),
  ];

  final List<int> _sequence = [];
  final List<int> _playerInput = [];
  int _round = 1;
  bool _isPlayingPattern = false;
  int? _highlightedIndex;
  String _message = "Watch Teddy's pattern!";
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _startRound(1);
  }

  void _startRound(int round) {
    setState(() {
      _round = round;
      _playerInput.clear();
      _sequence.clear();
      _isPlayingPattern = true;
      _message = "Watch Teddy's pattern!";
    });

    // Generate sequence for this round (round 1 = 2 items, round 2 = 3 items, round 3 = 4 items)
    final count = round + 1;
    for (int i = 0; i < count; i++) {
      _sequence.add(i % _characters.length);
    }

    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      final charIndex = _sequence[i];
      setState(() => _highlightedIndex = charIndex);
      AudioVoiceService().speak(_characters[charIndex].$2);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _highlightedIndex = null);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    setState(() {
      _isPlayingPattern = false;
      _message = "Now your turn! Tap the animals in order!";
    });
  }

  void _onTapCharacter(int idx) {
    if (_isPlayingPattern || _completed) return;

    _playerInput.add(idx);
    AudioVoiceService().speak(_characters[idx].$2);

    final currentIndex = _playerInput.length - 1;
    if (_playerInput[currentIndex] != _sequence[currentIndex]) {
      // Mistake!
      setState(() {
        _message = "Oops! Let's watch Teddy try again!";
        _playerInput.clear();
        _isPlayingPattern = true;
      });
      AudioVoiceService().speak("Let's try again!");
      Timer(const Duration(milliseconds: 900), _playSequence);
      return;
    }

    if (_playerInput.length == _sequence.length) {
      // Completed current round!
      if (_round < 3) {
        setState(() {
          _message = 'Round $_round Clear! Next round coming up! ⭐';
        });
        AudioVoiceService().speakEncouragement('Super memory!');
        Timer(
            const Duration(milliseconds: 1000), () => _startRound(_round + 1));
      } else {
        setState(() {
          _completed = true;
          _message = '🎉 Wow! You have super memory powers!';
        });
        AudioVoiceService()
            .speak('Incredible job! You mastered the memory game!');
        widget.onComplete();
      }
    }
  }

  void _restart() {
    _completed = false;
    _startRound(1);
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Memory Game',
      onBack: widget.onBack,
      trailing: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: purple, size: 26),
        onPressed: _restart,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Round indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5EFF5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Round: $_round / 3',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: ink)),
                  Text('Level: ${_sequence.length} Steps',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: orange)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Message banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: goldLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4 Animal Cards Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: List.generate(_characters.length, (i) {
                  final ch = _characters[i];
                  final isGlowing = _highlightedIndex == i;

                  return BouncyButton(
                    onTap: () => _onTapCharacter(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isGlowing ? gold : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isGlowing ? orange : const Color(0xFFE5EFF5),
                          width: isGlowing ? 4 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isGlowing
                                ? orange.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: isGlowing ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(ch.$1, style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 4),
                              Text(
                                ch.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isGlowing ? Colors.white : ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),

            if (_completed)
              BouncyButton(
                onTap: _restart,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [purple, lavenderDeep]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'Play Again ⭐',
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

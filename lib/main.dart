import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'board_definition.dart';
import 'game_logic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PegSolitaireApp());
}

class PegSolitaireApp extends StatelessWidget {
  const PegSolitaireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peg Solitaire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B6F47)),
        scaffoldBackgroundColor: const Color(0xFFE8D5B7),
      ),
      home: const HourglassGameScreen(),
    );
  }
}

class HourglassGameScreen extends StatefulWidget {
  const HourglassGameScreen({super.key});

  @override
  State<HourglassGameScreen> createState() => _HourglassGameScreenState();
}

class _HourglassGameScreenState extends State<HourglassGameScreen> {
  static const _animationDuration = Duration(milliseconds: 280);
  final BoardDefinition _board = BoardDefinition.hourglass();
  late final HourglassGame _game = HourglassGame(_board);
  final math.Random _random = math.Random();

  Team? _currentTurn;
  String? _selectedNode;
  String? _forcedNode;
  Set<String> _validTargets = <String>{};
  bool _animating = false;
  bool _hasGameStarted = false;
  Team? _winnerToastShownFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tossForFirstTurn());
  }

  Future<void> _tossForFirstTurn() async {
    if (!mounted || _hasGameStarted) {
      return;
    }

    final result = await showDialog<Team>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE8D5B7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 2,
            ),
          ),
          title: const Text(
            'Toss for First Turn',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Tap Toss to randomly choose which player starts.',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 16,
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B6F47), Color(0xFF6B5344)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(_random.nextBool() ? Team.green : Team.red);
                },
                child: const Text(
                  'Toss',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentTurn = result ?? Team.green;
      _selectedNode = null;
      _forcedNode = null;
      _validTargets = <String>{};
    });
  }

  void _onNodeTap(String nodeId) {
    if (_animating || _currentTurn == null || _game.hasWinner()) {
      return;
    }

    final turn = _currentTurn!;
    final pieceByNode = _pieceByNode();

    if (_selectedNode != null && _validTargets.contains(nodeId)) {
      final move = _game.findMove(
        from: _selectedNode!,
        to: nodeId,
        team: turn,
        restrictedNodeId: _forcedNode,
      );
      if (move != null) {
        _performMove(move);
      }
      return;
    }

    final tappedPiece = pieceByNode[nodeId];
    final canSelect =
        tappedPiece != null &&
        tappedPiece.team == turn &&
        (_forcedNode == null || _forcedNode == nodeId);

    if (canSelect) {
      final moves = _game.validMovesForNode(nodeId, turn);
      setState(() {
        _selectedNode = nodeId;
        _validTargets = moves.map((move) => move.to).toSet();
      });
      return;
    }

    setState(() {
      _selectedNode = _forcedNode;
      _validTargets = _forcedNode == null
          ? <String>{}
          : _game
                .validMovesForNode(_forcedNode!, turn)
                .map((move) => move.to)
                .toSet();
    });
  }

  Future<void> _performMove(GameMove move) async {
    final turn = _currentTurn;
    if (turn == null) {
      return;
    }

    setState(() {
      _animating = true;
      _hasGameStarted = true;
      _selectedNode = null;
      _validTargets = <String>{};
      final outcome = _game.applyMove(
        move,
        turn,
        restrictedNodeId: _forcedNode,
      );
      _game.recordMove(move, turn);

      if (outcome.keepTurn) {
        final movedNode = _game.pieces
            .firstWhere((piece) => piece.id == outcome.movedPegId)
            .nodeId;
        _forcedNode = movedNode;
      } else {
        _forcedNode = null;
        _currentTurn = turn.opponent;
      }
    });

    await Future<void>.delayed(_animationDuration);

    if (!mounted) {
      return;
    }

    setState(() {
      _animating = false;
      if (_forcedNode != null && _currentTurn != null) {
        _selectedNode = _forcedNode;
        _validTargets = _game
            .validMovesForNode(_forcedNode!, _currentTurn!)
            .map((move) => move.to)
            .toSet();
      }
    });

    final winner = _game.winner();
    if (winner != null && _winnerToastShownFor != winner && mounted) {
      _showWinnerToast(winner);
      _winnerToastShownFor = winner;
    } else if (_game.isDraw() && mounted) {
      _showDrawDialog();
    }
  }

  void _resetGame() {
    if (_animating) {
      return;
    }
    setState(() {
      _game.reset();
      _selectedNode = null;
      _forcedNode = null;
      _validTargets = <String>{};
      _currentTurn = null;
      _hasGameStarted = false;
      _winnerToastShownFor = null;
    });
    _tossForFirstTurn();
  }

  void _showWinnerToast(Team winner) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: winner.color.withValues(alpha: 0.93),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${winner.label} wins! Great capture streak.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('🏆', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDrawDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE8D5B7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 2,
            ),
          ),
          title: const Text(
            'Game Draw!',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Players have repeated the same 3 moves.\nNo winner can be determined.',
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B6F47), Color(0xFF6B5344)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop('newGame'),
                child: const Text(
                  'New Game',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == 'newGame' && mounted) {
      _resetGame();
    }
  }

  Map<String, PegPiece> _pieceByNode() {
    return {for (final piece in _game.pieces) piece.nodeId: piece};
  }

  @override
  Widget build(BuildContext context) {
    final winner = _game.winner();
    final turnLabel = _currentTurn == null ? '-' : _currentTurn!.label;
    final turnColor = _currentTurn == Team.green
        ? Team.green.color
        : _currentTurn == Team.red
        ? Team.red.color
        : const Color(0xFF344054);

    final statusText = winner != null
        ? '${winner.label} wins by capturing all opponent pegs.'
        : _forcedNode != null
        ? '${_currentTurn!.label} must continue capture with the same peg.'
        : 'Turn: $turnLabel';

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2E4A6F), Color(0xFF1E3A5F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 2.5,
              ),
            ),
            child: const Center(
              child: Text(
                'Peg Solitaire',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 3,
                      offset: Offset(2, 2),
                    ),
                    Shadow(
                      color: Color(0xFFD4AF37),
                      blurRadius: 1,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF5E6D3),
              const Color(0xFFE8D5B7),
              const Color(0xFFD4C4A8),
              const Color(0xFFC9B896),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScorePill(
                    label: 'Green',
                    color: Team.green.color,
                    score: _game.scoreFor(Team.green),
                    remaining: _game.greenCount,
                  ),
                  _ScorePill(
                    label: 'Red',
                    color: Team.red.color,
                    score: _game.scoreFor(Team.red),
                    remaining: _game.redCount,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: turnColor,
                ),
              ),
              if (winner == null && _currentTurn == null) ...[
                const SizedBox(height: 4),
                Text(
                  'Use Toss to start',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _BoardView(
                  board: _board,
                  pieces: _game.pieces,
                  selectedNode: _selectedNode,
                  validTargets: _validTargets,
                  onNodeTap: _onNodeTap,
                  currentTurn: _currentTurn,
                  game: _game,
                  forcedNode: _forcedNode,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B6F47), Color(0xFF6B5344)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: (_animating || _hasGameStarted)
                            ? null
                            : _tossForFirstTurn,
                        icon: const Icon(Icons.casino_outlined, color: Colors.white),
                        label: const Text(
                          'Toss',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF81C784),
                          width: 1.5,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _resetGame,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Reset Board',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.color,
    required this.score,
    required this.remaining,
  });

  final String label;
  final Color color;
  final int score;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B6F47).withValues(alpha: 0.9),
            const Color(0xFF6B5344).withValues(alpha: 0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$label  Score: $score  Left: $remaining',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.board,
    required this.pieces,
    required this.selectedNode,
    required this.validTargets,
    required this.onNodeTap,
    required this.currentTurn,
    required this.game,
    required this.forcedNode,
  });

  final BoardDefinition board;
  final List<PegPiece> pieces;
  final String? selectedNode;
  final Set<String> validTargets;
  final ValueChanged<String> onNodeTap;
  final Team? currentTurn;
  final HourglassGame game;
  final String? forcedNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final projector = _BoardProjector(
          board: board,
          size: constraints.biggest,
          padding: 20,
        );

        return Stack(
          children: [
            CustomPaint(
              size: constraints.biggest,
              painter: _BoardPainter(board: board, projector: projector),
            ),
            ...board.nodes.map((node) {
              final center = projector.toCanvas(node.position);
              final isSelected = selectedNode == node.id;
              final isValidTarget = validTargets.contains(node.id);
              final radius = isSelected ? 20.0 : 16.0;

              return Positioned(
                left: center.dx - radius,
                top: center.dy - radius,
                child: GestureDetector(
                  onTap: () => onNodeTap(node.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: isValidTarget
                            ? [
                                const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                const Color(0xFFD4AF37).withValues(alpha: 0.3),
                              ]
                            : [
                                const Color(0xFF8B6F47).withValues(alpha: 0.7),
                                const Color(0xFF6B5344).withValues(alpha: 0.7),
                              ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFD4AF37),
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            ...pieces.map((piece) {
              final center = projector.toCanvas(
                board.nodesById[piece.nodeId]!.position,
              );
              // _PegToken widget size is 56x56 (includes glow effect padding)
              const widgetSize = 56.0;
              
              // Check if this piece can move (only for current turn)
              final isCurrentTeam = currentTurn == piece.team;
              final canMove = isCurrentTeam && 
                  (forcedNode == null || forcedNode == piece.nodeId) &&
                  game.validMovesForNode(piece.nodeId, piece.team).isNotEmpty;
              final isSelected = selectedNode == piece.nodeId;

              return AnimatedPositioned(
                key: ValueKey(piece.id),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                left: center.dx - widgetSize / 2,
                top: center.dy - widgetSize / 2,
                child: IgnorePointer(
                  child: _PegToken(
                    color: piece.team.color,
                    canMove: canMove,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PegToken extends StatefulWidget {
  const _PegToken({
    required this.color,
    this.canMove = false,
    this.isSelected = false,
  });

  final Color color;
  final bool canMove;
  final bool isSelected;

  @override
  State<_PegToken> createState() => _PegTokenState();
}

class _PegTokenState extends State<_PegToken>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.canMove && !widget.isSelected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PegToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canMove && !widget.isSelected) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pegSize = 36.0;
    
    // Define marble colors based on team
    final isGreen = widget.color == Team.green.color;
    
    // Marble color schemes
    final topGradientColors = isGreen
        ? [const Color(0xFF86EFAC), const Color(0xFF22C55E), const Color(0xFF14532D)]
        : [const Color(0xFFFCA5A5), const Color(0xFFEF4444), const Color(0xFF7F1D1D)];
    
    final bodyGradientColors = isGreen
        ? [const Color(0xFF14532D), const Color(0xFF166534), const Color(0xFF22C55E)]
        : [const Color(0xFF7F1D1D), const Color(0xFF991B1B), const Color(0xFFEF4444)];
    
    final shadowColor = isGreen
        ? const Color(0xFF052E16).withValues(alpha: 0.4)
        : const Color(0xFF450A0A).withValues(alpha: 0.4);

    return SizedBox(
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          // Calculate glow properties
          final glowOpacity = widget.isSelected
              ? 0.8
              : (widget.canMove ? 0.3 + (_pulseAnimation.value * 0.3) : 0.0);
          final glowSize = widget.isSelected
              ? 52.0
              : (widget.canMove ? 44.0 + (_pulseAnimation.value * 12.0) : 0.0);
          final glowColor = widget.isSelected
              ? const Color(0xFFFFD700) // Gold for selected
              : widget.color.withValues(alpha: 0.6); // Team color for canMove

          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing glow effect
              if (widget.canMove || widget.isSelected)
                Container(
                  width: glowSize,
                  height: glowSize,
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: glowOpacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: glowOpacity * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              
              // Layer 1: Pronounced base shadow (elevation) - centered
              Container(
                width: pegSize,
                height: pegSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(3, 5),
                    ),
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
              ),
              
              // Layer 2: Cylinder body (vertical gradient)
              Container(
                width: pegSize,
                height: pegSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: bodyGradientColors,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              
              // Layer 3: Cylinder rim/edge (darker ring)
              Container(
                width: pegSize - 2,
                height: pegSize - 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGreen ? const Color(0xFF14532D) : const Color(0xFF7F1D1D),
                    width: 1.5,
                  ),
                ),
              ),
              
              // Layer 4: Marble top surface (radial gradient)
              Container(
                width: pegSize - 4,
                height: pegSize - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 0.8,
                    colors: topGradientColors,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: widget.isSelected
                        ? const Color(0xFFFFD700)
                        : (isGreen ? const Color(0xFF166534) : const Color(0xFF991B1B)),
                    width: widget.isSelected ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              
              // Layer 5: Glossy highlight (marble shine) - centered on peg
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 14,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Secondary smaller highlight - centered on peg
              Positioned(
                top: 16,
                left: 15,
                child: Container(
                  width: 6,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.board, required this.projector});

  final BoardDefinition board;
  final _BoardProjector projector;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final line in board.lines) {
      for (var i = 0; i < line.length - 1; i++) {
        final a = projector.toCanvas(board.nodesById[line[i]]!.position);
        final b = projector.toCanvas(board.nodesById[line[i + 1]]!.position);
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return false;
  }
}

class _BoardProjector {
  _BoardProjector({
    required this.board,
    required this.size,
    required this.padding,
  }) {
    final xs = board.nodes
        .map((node) => node.position.dx)
        .toList(growable: false);
    final ys = board.nodes
        .map((node) => node.position.dy)
        .toList(growable: false);

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    final boardWidth = maxX - minX;
    final boardHeight = maxY - minY;

    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    _scale = math.min(usableWidth / boardWidth, usableHeight / boardHeight);

    final drawnWidth = boardWidth * _scale;
    final drawnHeight = boardHeight * _scale;

    _origin = Offset(
      (size.width - drawnWidth) / 2 - minX * _scale,
      (size.height - drawnHeight) / 2 - minY * _scale,
    );
  }

  final BoardDefinition board;
  final Size size;
  final double padding;

  late final Offset _origin;
  late final double _scale;

  Offset toCanvas(Offset point) {
    return Offset(
      _origin.dx + point.dx * _scale,
      _origin.dy + point.dy * _scale,
    );
  }
}

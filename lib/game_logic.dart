import 'package:flutter/material.dart';

import 'board_definition.dart';

enum Team { green, red }

extension TeamX on Team {
  Team get opponent => this == Team.green ? Team.red : Team.green;

  Color get color =>
      this == Team.green ? const Color(0xFF2DB83D) : const Color(0xFFFF4A58);

  String get label => this == Team.green ? 'Green' : 'Red';
}

class PegPiece {
  const PegPiece({required this.id, required this.nodeId, required this.team});

  final String id;
  final String nodeId;
  final Team team;

  PegPiece copyWith({String? nodeId}) {
    return PegPiece(id: id, nodeId: nodeId ?? this.nodeId, team: team);
  }
}

class GameMove {
  const GameMove({required this.from, required this.to, this.over});

  final String from;
  final String to;
  final String? over;

  bool get isCapture => over != null;
}

class MoveRecord {
  const MoveRecord({
    required this.from,
    required this.to,
    required this.over,
    required this.team,
  });

  final String from;
  final String to;
  final String? over;
  final Team team;

  @override
  String toString() => '${team.label}: $from→$to${over != null ? '(capture:$over)' : ''}';

  bool matchesSequence(List<MoveRecord> sequence) {
    if (sequence.length != 3) return false;
    return from == sequence[0].from &&
        to == sequence[0].to &&
        over == sequence[0].over &&
        team == sequence[0].team &&
        from == sequence[1].from &&
        to == sequence[1].to &&
        over == sequence[1].over &&
        team == sequence[1].team &&
        from == sequence[2].from &&
        to == sequence[2].to &&
        over == sequence[2].over &&
        team == sequence[2].team;
  }
}

class MoveResolution {
  const MoveResolution({
    required this.movedPegId,
    required this.capturedPegId,
    required this.keepTurn,
  });

  final String movedPegId;
  final String? capturedPegId;
  final bool keepTurn;
}

class HourglassGame {
  HourglassGame(this.board)
    : _pieces = _buildStartingPieces(board),
      _adjacentByFrom = _buildAdjacency(board.lines),
      _jumpByFrom = _groupJumpsByFrom(board.jumps);

  final BoardDefinition board;
  final Map<String, List<String>> _adjacentByFrom;
  final Map<String, List<JumpConnection>> _jumpByFrom;
  List<PegPiece> _pieces;
  final List<MoveRecord> _moveHistory = [];

  List<PegPiece> get pieces => List.unmodifiable(_pieces);
  List<MoveRecord> get moveHistory => List.unmodifiable(_moveHistory);

  int get greenCount =>
      _pieces.where((piece) => piece.team == Team.green).length;

  int get redCount => _pieces.where((piece) => piece.team == Team.red).length;

  int scoreFor(Team team) {
    final opponentStart = board.nodes.length ~/ 2;
    final opponentRemaining = team == Team.green ? redCount : greenCount;
    return opponentStart - opponentRemaining;
  }

  bool hasWinner() => greenCount == 0 || redCount == 0;

  Team? winner() {
    if (redCount == 0) {
      return Team.green;
    }
    if (greenCount == 0) {
      return Team.red;
    }
    return null;
  }

  bool hasAnyValidMoves(Team team) {
    return validMovesForTurn(team).isNotEmpty;
  }

  bool checkMoveRepetitionDraw() {
    if (_moveHistory.length < 6) return false;
    
    final lastThree = <MoveRecord>[];
    lastThree.add(_moveHistory[_moveHistory.length - 3]);
    lastThree.add(_moveHistory[_moveHistory.length - 2]);
    lastThree.add(_moveHistory[_moveHistory.length - 1]);
    
    for (int i = 0; i <= _moveHistory.length - 6; i++) {
      final sequence = <MoveRecord>[];
      sequence.add(_moveHistory[i]);
      sequence.add(_moveHistory[i + 1]);
      sequence.add(_moveHistory[i + 2]);
      
      if (lastThree[0].from == sequence[0].from &&
          lastThree[0].to == sequence[0].to &&
          lastThree[0].over == sequence[0].over &&
          lastThree[0].team == sequence[0].team &&
          lastThree[1].from == sequence[1].from &&
          lastThree[1].to == sequence[1].to &&
          lastThree[1].over == sequence[1].over &&
          lastThree[1].team == sequence[1].team &&
          lastThree[2].from == sequence[2].from &&
          lastThree[2].to == sequence[2].to &&
          lastThree[2].over == sequence[2].over &&
          lastThree[2].team == sequence[2].team) {
        return true;
      }
    }
    return false;
  }

  bool isDraw() {
    if (hasWinner()) return false;
    if (!hasAnyValidMoves(Team.green) || !hasAnyValidMoves(Team.red)) {
      return true;
    }
    return checkMoveRepetitionDraw();
  }

  void recordMove(GameMove move, Team team) {
    _moveHistory.add(MoveRecord(
      from: move.from,
      to: move.to,
      over: move.over,
      team: team,
    ));
  }

  List<GameMove> validMovesForNode(String nodeId, Team team) {
    final nodeToPiece = _nodeToPiece();
    final piece = nodeToPiece[nodeId];
    if (piece == null || piece.team != team) {
      return const [];
    }

    final captures = _captureMoves(nodeId, team, nodeToPiece);
    final adjacent = _adjacentMoves(nodeId, nodeToPiece);
    return [...adjacent, ...captures];
  }

  List<GameMove> validMovesForTurn(Team team, {String? restrictedNodeId}) {
    final nodeToPiece = _nodeToPiece();

    if (restrictedNodeId != null) {
      return _captureMoves(restrictedNodeId, team, nodeToPiece);
    }

    final moves = <GameMove>[];
    for (final piece in _pieces) {
      if (piece.team != team) {
        continue;
      }
      moves.addAll(_adjacentMoves(piece.nodeId, nodeToPiece));
      moves.addAll(_captureMoves(piece.nodeId, team, nodeToPiece));
    }
    return moves;
  }

  GameMove? findMove({
    required String from,
    required String to,
    required Team team,
    String? restrictedNodeId,
  }) {
    final allowed = validMovesForTurn(team, restrictedNodeId: restrictedNodeId)
        .where((move) => move.from == from && move.to == to)
        .toList(growable: false);
    return allowed.isEmpty ? null : allowed.first;
  }

  MoveResolution applyMove(
    GameMove move,
    Team team, {
    String? restrictedNodeId,
  }) {
    final legalMove = findMove(
      from: move.from,
      to: move.to,
      team: team,
      restrictedNodeId: restrictedNodeId,
    );
    if (legalMove == null) {
      throw StateError(
        'Invalid move for ${team.label}: ${move.from} -> ${move.to}',
      );
    }

    final nodeToPiece = _nodeToPiece();
    final moving = nodeToPiece[legalMove.from]!;

    String? capturedId;
    if (legalMove.over != null) {
      final middlePiece = nodeToPiece[legalMove.over!];
      if (middlePiece == null || middlePiece.team == team) {
        throw StateError('Invalid capture at ${legalMove.over}');
      }
      capturedId = middlePiece.id;
    }

    _pieces = _pieces
        .where((piece) => piece.id != capturedId)
        .map((piece) {
          if (piece.id == moving.id) {
            return piece.copyWith(nodeId: legalMove.to);
          }
          return piece;
        })
        .toList(growable: false);

    final keepTurn =
        legalMove.isCapture &&
        _captureMoves(legalMove.to, team, _nodeToPiece()).isNotEmpty;

    return MoveResolution(
      movedPegId: moving.id,
      capturedPegId: capturedId,
      keepTurn: keepTurn,
    );
  }

  void reset() {
    _pieces = _buildStartingPieces(board);
    _moveHistory.clear();
  }

  Map<String, PegPiece> _nodeToPiece() {
    final map = <String, PegPiece>{};
    for (final piece in _pieces) {
      map[piece.nodeId] = piece;
    }
    return map;
  }

  List<GameMove> _adjacentMoves(
    String from,
    Map<String, PegPiece> nodeToPiece,
  ) {
    final adjacent = _adjacentByFrom[from] ?? const <String>[];
    final moves = <GameMove>[];
    for (final to in adjacent) {
      if (!nodeToPiece.containsKey(to)) {
        moves.add(GameMove(from: from, to: to));
      }
    }
    return moves;
  }

  List<GameMove> _captureMoves(
    String from,
    Team team,
    Map<String, PegPiece> nodeToPiece,
  ) {
    final jumps = _jumpByFrom[from] ?? const <JumpConnection>[];
    final moves = <GameMove>[];
    for (final jump in jumps) {
      final overPiece = nodeToPiece[jump.over];
      if (overPiece == null || overPiece.team == team) {
        continue;
      }
      if (nodeToPiece.containsKey(jump.to)) {
        continue;
      }
      moves.add(GameMove(from: jump.from, to: jump.to, over: jump.over));
    }
    return moves;
  }

  static List<PegPiece> _buildStartingPieces(BoardDefinition board) {
    final pieces = <PegPiece>[];
    var id = 0;

    for (final node in board.nodes) {
      if (node.id == board.emptyStartNode) {
        continue;
      }
      final team = node.id.startsWith('t') ? Team.green : Team.red;
      pieces.add(PegPiece(id: 'peg_$id', nodeId: node.id, team: team));
      id++;
    }

    return pieces;
  }

  static Map<String, List<String>> _buildAdjacency(List<List<String>> lines) {
    final map = <String, List<String>>{};
    for (final line in lines) {
      for (var i = 0; i < line.length - 1; i++) {
        final a = line[i];
        final b = line[i + 1];
        map.putIfAbsent(a, () => <String>[]).add(b);
        map.putIfAbsent(b, () => <String>[]).add(a);
      }
    }
    return map;
  }

  static Map<String, List<JumpConnection>> _groupJumpsByFrom(
    List<JumpConnection> jumps,
  ) {
    final map = <String, List<JumpConnection>>{};
    for (final jump in jumps) {
      map.putIfAbsent(jump.from, () => <JumpConnection>[]).add(jump);
    }
    return map;
  }
}

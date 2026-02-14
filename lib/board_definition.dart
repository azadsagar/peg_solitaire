import 'dart:collection';
import 'dart:ui';

class BoardNode {
  const BoardNode({required this.id, required this.position});

  final String id;
  final Offset position;
}

class JumpConnection {
  const JumpConnection({
    required this.from,
    required this.over,
    required this.to,
  });

  final String from;
  final String over;
  final String to;
}

class BoardDefinition {
  BoardDefinition({
    required this.nodes,
    required this.lines,
    required this.jumps,
    required this.emptyStartNode,
  }) : nodesById = {for (final node in nodes) node.id: node};

  final List<BoardNode> nodes;
  final Map<String, BoardNode> nodesById;
  final List<List<String>> lines;
  final List<JumpConnection> jumps;
  final String emptyStartNode;

  static BoardDefinition hourglass() {
    const nodes = [
      BoardNode(id: 't0l', position: Offset(-2.0, 0.0)),
      BoardNode(id: 't0m', position: Offset(0.0, 0.0)),
      BoardNode(id: 't0r', position: Offset(2.0, 0.0)),
      BoardNode(id: 't1l', position: Offset(-1.5, 1.3)),
      BoardNode(id: 't1m', position: Offset(0.0, 1.3)),
      BoardNode(id: 't1r', position: Offset(1.5, 1.3)),
      BoardNode(id: 't2l', position: Offset(-1.0, 2.6)),
      BoardNode(id: 't2m', position: Offset(0.0, 2.6)),
      BoardNode(id: 't2r', position: Offset(1.0, 2.6)),
      BoardNode(id: 'center', position: Offset(0.0, 4.1)),
      BoardNode(id: 'b2l', position: Offset(-1.0, 5.6)),
      BoardNode(id: 'b2m', position: Offset(0.0, 5.6)),
      BoardNode(id: 'b2r', position: Offset(1.0, 5.6)),
      BoardNode(id: 'b1l', position: Offset(-1.5, 6.9)),
      BoardNode(id: 'b1m', position: Offset(0.0, 6.9)),
      BoardNode(id: 'b1r', position: Offset(1.5, 6.9)),
      BoardNode(id: 'b0l', position: Offset(-2.0, 8.2)),
      BoardNode(id: 'b0m', position: Offset(0.0, 8.2)),
      BoardNode(id: 'b0r', position: Offset(2.0, 8.2)),
    ];

    const lines = [
      ['t0l', 't0m', 't0r'],
      ['t1l', 't1m', 't1r'],
      ['t2l', 't2m', 't2r'],
      ['b2l', 'b2m', 'b2r'],
      ['b1l', 'b1m', 'b1r'],
      ['b0l', 'b0m', 'b0r'],
      ['t0m', 't1m', 't2m', 'center', 'b2m', 'b1m', 'b0m'],
      ['t0l', 't1l', 't2l', 'center', 'b2r', 'b1r', 'b0r'],
      ['t0r', 't1r', 't2r', 'center', 'b2l', 'b1l', 'b0l'],
    ];

    final jumps = _buildJumps(lines);

    return BoardDefinition(
      nodes: nodes,
      lines: lines,
      jumps: jumps,
      emptyStartNode: 'center',
    );
  }

  static List<JumpConnection> _buildJumps(List<List<String>> lines) {
    final jumps = <JumpConnection>[];
    final seen = HashSet<String>();

    for (final line in lines) {
      for (var i = 0; i <= line.length - 3; i++) {
        final forward = JumpConnection(
          from: line[i],
          over: line[i + 1],
          to: line[i + 2],
        );
        final backward = JumpConnection(
          from: line[i + 2],
          over: line[i + 1],
          to: line[i],
        );

        final forwardKey = '${forward.from}-${forward.over}-${forward.to}';
        final backwardKey = '${backward.from}-${backward.over}-${backward.to}';

        if (seen.add(forwardKey)) {
          jumps.add(forward);
        }
        if (seen.add(backwardKey)) {
          jumps.add(backward);
        }
      }
    }

    return jumps;
  }
}

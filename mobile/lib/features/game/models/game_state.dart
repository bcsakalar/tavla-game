import 'package:equatable/equatable.dart';

/// Represents a single point on the board.
class BoardPoint extends Equatable {
  final int count;
  final String? player; // 'W' or 'B'

  const BoardPoint({required this.count, this.player});

  factory BoardPoint.fromJson(Map<String, dynamic> json) {
    return BoardPoint(
      count: json['count'] ?? 0,
      player: json['player'],
    );
  }

  @override
  List<Object?> get props => [count, player];
}

/// Full game board state.
class BoardState extends Equatable {
  final List<BoardPoint> points;
  final Map<String, int> bar;
  final Map<String, int> borneOff;

  const BoardState({
    required this.points,
    required this.bar,
    required this.borneOff,
  });

  factory BoardState.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List)
        .map((p) => p != null ? BoardPoint.fromJson(p) : const BoardPoint(count: 0))
        .toList();

    return BoardState(
      points: points,
      bar: Map<String, int>.from(json['bar']),
      borneOff: Map<String, int>.from(json['borneOff']),
    );
  }

  @override
  List<Object?> get props => [points, bar, borneOff];
}

/// Complete game snapshot received from the server.
class GameSnapshot extends Equatable {
  final String state;
  final BoardState board;
  final String? currentTurn;
  final String? turnPhase;
  final List<int>? dice;
  final List<int>? remainingDice;
  final int moveNumber;
  final String? winner;
  final String? resultType;
  final String whitePlayerId;
  final String blackPlayerId;

  const GameSnapshot({
    required this.state,
    required this.board,
    this.currentTurn,
    this.turnPhase,
    this.dice,
    this.remainingDice,
    this.moveNumber = 0,
    this.winner,
    this.resultType,
    required this.whitePlayerId,
    required this.blackPlayerId,
  });

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      state: json['state'] ?? 'waiting',
      board: BoardState.fromJson(json['board']),
      currentTurn: json['currentTurn'],
      turnPhase: json['turnPhase'],
      dice: json['dice'] != null ? List<int>.from(json['dice']) : null,
      remainingDice: json['remainingDice'] != null ? List<int>.from(json['remainingDice']) : null,
      moveNumber: json['moveNumber'] ?? 0,
      winner: json['winner'],
      resultType: json['resultType'],
      whitePlayerId: json['whitePlayerId']?.toString() ?? '',
      blackPlayerId: json['blackPlayerId']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [state, board, currentTurn, moveNumber, winner];
}

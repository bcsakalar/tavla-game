import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavla_online/features/game/models/game_state.dart';
import 'package:tavla_online/features/game/widgets/board_widget.dart';
import 'package:tavla_online/features/game/widgets/bearing_off_tray_widget.dart';
import 'package:tavla_online/features/game/widgets/piece_widget.dart';

void main() {
  testWidgets('should render premium board layout with trays bar and pieces', (tester) async {
    final board = BoardState(
      points: List.generate(
        24,
        (index) {
          if (index == 0) {
            return const BoardPoint(count: 2, player: 'W');
          }
          if (index == 23) {
            return const BoardPoint(count: 2, player: 'B');
          }
          if (index == 5) {
            return const BoardPoint(count: 5, player: 'W');
          }
          return const BoardPoint(count: 0);
        },
      ),
      bar: const {'W': 1, 'B': 0},
      borneOff: const {'W': 3, 'B': 2},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              height: 640,
              child: BoardWidget(
                board: board,
                myColor: 'W',
                selectedPoint: 5,
                isMyTurn: true,
                validMoveTargets: const {-1, 2},
                dice: const [6, 3],
                remainingDice: const [3],
                turnPhase: 'moving',
                canBearOff: true,
                onPointTap: (_) {},
                onBearOffTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BearingOffTrayWidget), findsNWidgets(2));
    expect(find.byType(PieceWidget), findsWidgets);
    expect(find.byType(BoardWidget), findsOneWidget);
  });
}
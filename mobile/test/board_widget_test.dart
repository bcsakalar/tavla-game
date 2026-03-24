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

    expect(
      find.byWidgetPredicate((widget) => widget is BearingOffTrayWidget),
      findsNWidgets(2),
    );
    expect(find.byType(PieceWidget), findsWidgets);
    expect(find.byType(BoardWidget), findsOneWidget);
  });

  testWidgets('should call point drop when dragging a checker onto a valid target', (tester) async {
    int? dragStartPoint;
    int? droppedFrom;
    int? droppedTo;

    final board = BoardState(
      points: List.generate(
        24,
        (index) {
          if (index == 5) {
            return const BoardPoint(count: 1, player: 'W');
          }
          return const BoardPoint(count: 0);
        },
      ),
      bar: const {'W': 0, 'B': 0},
      borneOff: const {'W': 0, 'B': 0},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 640,
            child: BoardWidget(
              board: board,
              myColor: 'W',
              isMyTurn: true,
              validMoveTargets: const {2},
              onPointTap: (_) {},
              onPointDragStart: (fromPoint) {
                dragStartPoint = fromPoint;
              },
              onPointDrop: (fromPoint, toPoint) {
                droppedFrom = fromPoint;
                droppedTo = toPoint;
              },
            ),
          ),
        ),
      ),
    );

    final pieceFinder = find.byKey(const ValueKey('point-stack-5'));
    final targetFinder = find.byKey(const ValueKey('board-point-2'));

    final pieceCenter = tester.getCenter(pieceFinder);
    final targetCenter = tester.getCenter(targetFinder);
    final gesture = await tester.startGesture(pieceCenter);
    await tester.pump();
    await gesture.moveTo(targetCenter);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(dragStartPoint, 5);
    expect(droppedFrom, 5);
    expect(droppedTo, 2);
  });

  testWidgets('should call bear off drop when dragging a checker to active tray', (tester) async {
    int? draggedFrom;

    final board = BoardState(
      points: List.generate(
        24,
        (index) {
          if (index == 2) {
            return const BoardPoint(count: 1, player: 'W');
          }
          return const BoardPoint(count: 0);
        },
      ),
      bar: const {'W': 0, 'B': 0},
      borneOff: const {'W': 2, 'B': 0},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: 640,
            child: BoardWidget(
              board: board,
              myColor: 'W',
              isMyTurn: true,
              canBearOff: true,
              validMoveTargets: const {-1},
              onPointTap: (_) {},
              onPointDragStart: (_) {},
              onPointDrop: (_, __) {},
              onBearOffDrop: (fromPoint) {
                draggedFrom = fromPoint;
              },
            ),
          ),
        ),
      ),
    );

    final pieceFinder = find.byKey(const ValueKey('point-stack-2'));
    final trayFinder = find.byKey(const ValueKey('bearing-off-tray-W'));

    final gesture = await tester.startGesture(tester.getCenter(pieceFinder));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(trayFinder));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(draggedFrom, 2);
  });
}
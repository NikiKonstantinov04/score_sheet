import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score_sheet/app.dart';

void main() {
  // Помощна функция за добавяне на игра в каре режим.
  Future<void> addSingleGame(WidgetTester tester, {int boardNumber = 1, int tricks = 7}) async {
    // Отваряме формата за нова игра
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Задаваме номер на борд
    await tester.enterText(find.widgetWithText(TextFormField, 'Номер на борд'), '$boardNumber');
    // Задаваме взети взятки
    await tester.enterText(find.widgetWithText(TextFormField, 'Взети взятки (0-13)'), '$tricks');

    // Натискаме Запази
    await tester.tap(find.text('Запази'));
    await tester.pumpAndSettle();
  }

  testWidgets('HomeScreen показва избор на режим и навигация', (WidgetTester tester) async {
    await tester.pumpWidget(const BridgeScoreApp());

    expect(find.text('Bridge Scorer'), findsOneWidget);
    expect(find.text('Изберете режим на игра'), findsOneWidget);
    expect(find.text('Каре'), findsOneWidget);
    expect(find.text('Отборно'), findsOneWidget);
    expect(find.text('Започни нов мач'), findsOneWidget);

    await tester.tap(find.text('Започни нов мач'));
    await tester.pumpAndSettle();

    expect(find.text('Каре'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отборно'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Започни нов мач'));
    await tester.pumpAndSettle();

    expect(find.text('Отборен мач'), findsOneWidget);
    expect(find.text('Маса 1'), findsOneWidget);
    expect(find.text('Маса 2'), findsOneWidget);
  });

  testWidgets('Каре: добавяне на игра и показване на резултат', (WidgetTester tester) async {
    await tester.pumpWidget(const BridgeScoreApp());

    await tester.tap(find.text('Започни нов мач'));
    await tester.pumpAndSettle();

    await addSingleGame(tester);

    expect(find.text('Борд 1'), findsOneWidget);
    expect(find.textContaining('NS: 3 IMP'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();

    expect(find.text('Резултати'), findsOneWidget);
    expect(find.text('NS: 3  |  EW: -3'), findsOneWidget);
    expect(find.text('Борд 1'), findsOneWidget);
    expect(find.text('NS: 3 IMP'), findsOneWidget);
  });

  testWidgets('Отборен мач: добавяне на игри на двете маси и проверка на резултати', (WidgetTester tester) async {
    await tester.pumpWidget(const BridgeScoreApp());

    await tester.tap(find.text('Отборно'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Започни нов мач'));
    await tester.pumpAndSettle();

    // Добавяме игра на маса 1
    await addSingleGame(tester, boardNumber: 1, tricks: 7);
    expect(find.text('Борд 1'), findsOneWidget);

    // Превключваме на маса 2
    await tester.tap(find.text('Маса 2'));
    await tester.pumpAndSettle();

    // Добавяме игра на маса 2
    await addSingleGame(tester, boardNumber: 1, tricks: 6);
    expect(find.text('Борд 1'), findsOneWidget);

    // Отваряме резултати
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle();

    // Очакваме: Отбор A: 4  |  Отбор B: -4 (без "IMP")
    expect(find.text('Отбор A: 4  |  Отбор B: -4'), findsOneWidget);
  });

  testWidgets('Валидация: неуспешно добавяне на игра с невалидни данни', (WidgetTester tester) async {
    await tester.pumpWidget(const BridgeScoreApp());

    await tester.tap(find.text('Започни нов мач'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Опит за запис без взети взятки
    await tester.tap(find.text('Запази'));
    await tester.pumpAndSettle();

    expect(find.text('Въведете число от 0 до 13'), findsOneWidget);

    // Затваряме формата
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });
}
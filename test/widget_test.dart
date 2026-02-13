import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_salon/main.dart' as app;

void main() {
  testWidgets('Главный экран загружается', (WidgetTester tester) async {
    // Запускаем приложение
    app.main();
    await tester.pumpAndSettle();

    // Проверяем что приложение запустилось (ищем любой текст или виджет)
    expect(find.byType(MaterialApp), findsOneWidget);

    // Ищем текст, который есть в вашем приложении
    // Например, если у вас есть заголовок "Beauty Salon"
    // expect(find.text('Beauty Salon'), findsOneWidget);

    // Или просто проверяем что есть Scaffold
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
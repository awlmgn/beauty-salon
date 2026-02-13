import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:beauty_salon/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Тесты для приложения салона красоты', () {

    testWidgets('Сценарий 1: Экран входа загружается корректно',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();

          // Проверяем наличие всех элементов на экране входа
          expect(find.text('Добро пожаловать'), findsOneWidget);
          expect(find.text('Войдите в свой аккаунт'), findsOneWidget);
          expect(find.text('Email'), findsOneWidget);
          expect(find.text('Пароль'), findsOneWidget);
          expect(find.text('Войти'), findsOneWidget);
          expect(find.text('Нет аккаунта?'), findsOneWidget);
          expect(find.text('Зарегистрируйтесь'), findsOneWidget);
        });

    testWidgets('Сценарий 2: Валидация полей входа',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();

          // Находим поля ввода
          final emailField = find.byType(TextField).first;
          final passwordField = find.byType(TextField).last;
          final loginButton = find.text('Войти');

          // Проверяем, что поля найдены
          expect(emailField, findsOneWidget);
          expect(passwordField, findsOneWidget);
          expect(loginButton, findsOneWidget);

          // Вводим некорректные данные
          await tester.enterText(emailField, 'invalid-email');
          await tester.enterText(passwordField, '123');

          // Нажимаем кнопку входа
          await tester.tap(loginButton);
          await tester.pump();

          // Проверяем появление сообщения об ошибке
          // (замените на реальный текст ошибки из вашего приложения)
          // expect(find.text('Неверный email или пароль'), findsOneWidget);
        });

    testWidgets('Сценарий 3: Переход на экран регистрации',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();

          // Нажимаем на ссылку регистрации
          await tester.tap(find.text('Зарегистрируйтесь'));
          await tester.pumpAndSettle();

          // Проверяем, что открылся экран регистрации
          // (замените на текст с экрана регистрации)
          // expect(find.text('Регистрация'), findsOneWidget);
        });

    testWidgets('Сценарий 4: Ввод данных в поля',
            (WidgetTester tester) async {
          app.main();
          await tester.pumpAndSettle();

          // Вводим тестовые данные
          await tester.enterText(
              find.byType(TextField).first,
              'test@example.com'
          );
          await tester.enterText(
              find.byType(TextField).last,
              'password123'
          );
          await tester.pump();

          // Проверяем, что текст введен
          final emailField = find.byType(TextField).first;
          final TextField emailTextField = tester.widget(emailField);
          expect(emailTextField.controller?.text, 'test@example.com');
        });
  });
}
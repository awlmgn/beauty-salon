import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Импортируем mocktail вместо mockito
import 'package:beauty_salon/repositories/note_repository.dart';
import 'package:beauty_salon/services/note_service.dart';
import 'package:beauty_salon/services/api_service.dart';
import 'package:beauty_salon/models/user.dart';

// Создаем мок-классы с mocktail
class MockNoteService extends Mock implements NoteService {}
class MockApiService extends Mock implements ApiService {}

void main() {
  group('NoteRepository Integration', () {
    late MockNoteService mockNoteService;
    late MockApiService mockApiService;
    late NoteRepository repository;

    setUp(() {
      mockNoteService = MockNoteService();
      mockApiService = MockApiService();
      repository = NoteRepository(
        localService: mockNoteService,
        apiService: mockApiService,
      );

      // Регистрируем fallback значения для Note
      registerFallbackValue(Note(
        id: 1,
        title: '',
        content: '',
        createdAt: DateTime.now(),
      ));
    });

    test('should fetch from local service', () async {
      // Используем () => синтаксис mocktail
      when(() => mockNoteService.getNotes()).thenAnswer((_) async => []);

      final notes = await repository.getNotes();

      expect(notes, isEmpty);
      verify(() => mockNoteService.getNotes()).called(1);
    });

    test('should sync remote notes when forceRemote is true', () async {
      final remoteNotes = [
        {'title': 'Remote 1', 'content': 'Content 1'},
        {'title': 'Remote 2', 'content': 'Content 2'},
      ];

      when(() => mockApiService.fetchNotes()).thenAnswer((_) async => remoteNotes);

      // В mocktail any() работает правильно
      when(() => mockNoteService.createNote(any(), any())).thenAnswer((invocation) async {
        // Получаем аргументы
        final title = invocation.positionalArguments[0] as String;
        final content = invocation.positionalArguments[1] as String;

        return Note(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          content: content,
          createdAt: DateTime.now(),
        );
      });

      when(() => mockNoteService.getNotes()).thenAnswer((_) async => []);

      await repository.getNotes(forceRemote: true);

      verify(() => mockApiService.fetchNotes()).called(1);
      verify(() => mockNoteService.createNote('Remote 1', 'Content 1')).called(1);
      verify(() => mockNoteService.createNote('Remote 2', 'Content 2')).called(1);
    });

    test('should handle error when fetching remote notes', () async {
      when(() => mockApiService.fetchNotes()).thenThrow(Exception('Network error'));
      when(() => mockNoteService.getNotes()).thenAnswer((_) async => []);

      final notes = await repository.getNotes(forceRemote: true);

      expect(notes, isEmpty);
      verify(() => mockApiService.fetchNotes()).called(1);
      verify(() => mockNoteService.getNotes()).called(1);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beauty_salon/services/note_service.dart';
import 'package:beauty_salon/models/user.dart';

void main() {
  group('NoteService Integration Tests', () {
    late SharedPreferences prefs;
    late NoteService noteService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      noteService = NoteService(prefs: prefs);
    });

    test('should create and retrieve notes', () async {
      final note = await noteService.createNote('Test Title', 'Test Content');

      expect(note.title, 'Test Title');
      expect(note.content, 'Test Content');

      final notes = await noteService.getNotes();
      expect(notes.length, 1);
      expect(notes.first.title, 'Test Title');
    });

    test('should delete note', () async {
      final note = await noteService.createNote('To Delete', 'Content');

      var notes = await noteService.getNotes();
      expect(notes.length, 1);

      await noteService.deleteNote(note.id);

      notes = await noteService.getNotes();
      expect(notes.length, 0);
    });

    test('should handle empty notes', () async {
      final notes = await noteService.getNotes();
      expect(notes, isEmpty);
    });
  });
}
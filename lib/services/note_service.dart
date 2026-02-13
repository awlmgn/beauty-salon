import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class NoteService {
  final SharedPreferences prefs;
  static const String _notesKey = 'notes';

  NoteService({required this.prefs});

  Future<List<Note>> getNotes() async {
    final notesJson = prefs.getString(_notesKey);
    if (notesJson == null) return [];

    final List<dynamic> decoded = json.decode(notesJson);
    return decoded.map((note) => Note(
      id: note['id'],
      title: note['title'],
      content: note['content'],
      createdAt: DateTime.parse(note['createdAt']),
    )).toList();
  }

  Future<Note> createNote(String title, String content) async {
    final notes = await getNotes();
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );

    notes.add(newNote);
    await _saveNotes(notes);
    return newNote;
  }

  Future<void> deleteNote(int id) async {
    final notes = await getNotes();
    notes.removeWhere((note) => note.id == id);
    await _saveNotes(notes);
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final notesJson = json.encode(notes.map((note) => {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toIso8601String(),
    }).toList());

    await prefs.setString(_notesKey, notesJson);
  }
}
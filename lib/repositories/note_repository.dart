import '../services/note_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class NoteRepository {
  final NoteService localService;
  final ApiService apiService;

  NoteRepository({
    required this.localService,
    required this.apiService,
  });

  Future<List<Note>> getNotes({bool forceRemote = false}) async {
    if (forceRemote) {
      try {
        final remoteNotes = await apiService.fetchNotes();
        // Convert remote notes to local model and save
        for (var note in remoteNotes) {
          await localService.createNote(
              note['title'],
              note['content']
          );
        }
      } catch (e) {
        // Fallback to local
      }
    }

    return await localService.getNotes();
  }
}
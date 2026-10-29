import '../../data/local/note.dart';

/// Pure domain function to filter notes by title or content query.
/// Case-insensitive, trims leading/trailing whitespace, and handles edge cases.
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return notes;
  return notes
      .where(
        (note) =>
            note.title.toLowerCase().contains(trimmed) ||
            note.body.toLowerCase().contains(trimmed),
      )
      .toList();
}

/// Clean Architecture Use Case for searching notes.
/// Pure Dart class independent of Flutter UI and persistence storage layers.
class SearchNotesUseCase {
  const SearchNotesUseCase();

  List<Note> execute(List<Note> notes, String query) {
    return filterNotes(notes, query);
  }
}

// lib/models/note.dart
import 'package:flutter/foundation.dart';

/// Заметка смены — короткое текстовое сообщение от сотрудника.
@immutable
class Note {
  final String id;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  Note copyWith({String? text}) {
    return Note(
      id: id,
      authorName: authorName,
      text: text ?? this.text,
      createdAt: createdAt,
    );
  }
}

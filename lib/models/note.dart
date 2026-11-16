// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

class Note {
  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Note copyWith({
    String? content,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Note(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'content': content,
      'created_at_ms': createdAt.millisecondsSinceEpoch,
      'updated_at_ms': updatedAt.millisecondsSinceEpoch,
      'deleted_at_ms': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at_ms'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at_ms'] as int,
      ),
      deletedAt: map['deleted_at_ms'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['deleted_at_ms'] as int),
    );
  }
}

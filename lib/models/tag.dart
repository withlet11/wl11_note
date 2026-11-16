// Copyright 2026 WITHLET11 <withlet11@gmail.com>
// SPDX-License-Identifier: MIT

class Tag {
  const Tag({required this.id, required this.name});

  final int id;
  final String name;

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name};
  }

  factory Tag.fromMap(Map<String, Object?> map) {
    return Tag(id: map['id'] as int, name: map['name'] as String);
  }
}

class Note {
  int? id;
  String title;
  String content;
  String createdAt;
  String updatedAt;
  bool isPinned;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    String? updatedAt,
    this.isPinned = false,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] as String? ?? map['createdAt'] as String,
      isPinned: (map['isPinned'] as int? ?? 0) == 1,
    );
  }
}

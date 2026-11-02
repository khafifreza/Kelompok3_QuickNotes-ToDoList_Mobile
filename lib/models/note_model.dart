class Note {
  int? id;
  String title;
  String content;
  String createdAt;

  Note({this.id, required this.title, required this.content, required this.createdAt});


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['createdAt'],
    );
  }
}

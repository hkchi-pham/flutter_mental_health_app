class JournalEntry {
  final String id;
  final String content;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Journal {
  final String id;
  final String title;
  final String emoji;
  final DateTime createdAt;
  final List<JournalEntry> entries;

  Journal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createdAt,
    List<JournalEntry>? entries,
  }) : entries = entries ?? [];

  Journal copyWith({
    String? id,
    String? title,
    String? emoji,
    DateTime? createdAt,
    List<JournalEntry>? entries,
  }) {
    return Journal(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      id: json['id'] as String? ?? '',
      title: (json['title'] ?? json['name'] ?? 'Untitled') as String,
      emoji: (json['emoji'] ?? '📔') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

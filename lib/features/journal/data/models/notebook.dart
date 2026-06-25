/// Allowed palette tokens for a notebook cover color. Default is `green`.
const List<String> kNotebookColors = [
  'green',
  'brown',
  'blue',
  'pink',
  'yellow',
];

/// Default notebook color token.
const String kDefaultNotebookColor = 'green';

/// Notebook visibility — serializes to the backend wire values
/// `'private'` / `'public'`. Enum names carry a trailing underscore to avoid
/// clashing with the Dart reserved-ish identifiers and keep them distinct.
enum NotebookVisibility {
  private_,
  public_;

  /// Backend wire string for this visibility.
  String get wire => this == NotebookVisibility.public_ ? 'public' : 'private';

  /// Parse a backend wire string into a [NotebookVisibility].
  /// Anything other than `'public'` falls back to private (safer default).
  static NotebookVisibility fromWire(String? value) =>
      value == 'public' ? NotebookVisibility.public_ : NotebookVisibility.private_;
}

/// A single dated page entry inside a [Notebook].
///
/// Mirrors one value of the backend `page` object: `{id, content, created_at}`.
class NotebookEntry {
  const NotebookEntry({
    required this.id,
    required this.content,
    required this.date,
  });

  final String id;
  final String content;
  final DateTime date;

  NotebookEntry copyWith({
    String? id,
    String? content,
    DateTime? date,
  }) =>
      NotebookEntry(
        id: id ?? this.id,
        content: content ?? this.content,
        date: date ?? this.date,
      );

  /// JSON round-trip used by the local cache (NOT the backend wire shape —
  /// see [JournalDto.entriesToPage] for the index-keyed wire form).
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'date': date.toIso8601String(),
      };

  factory NotebookEntry.fromJson(Map<String, dynamic> json) => NotebookEntry(
        id: '${json['id'] ?? ''}',
        content: '${json['content'] ?? ''}',
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotebookEntry &&
          other.id == id &&
          other.content == content &&
          other.date == date;

  @override
  int get hashCode => Object.hash(id, content, date);
}

/// A journal notebook with a list of dated entries.
///
/// `entries` is derived from the backend `page` object (an index-keyed map),
/// always sorted ascending by [NotebookEntry.date]. `color` is one of
/// [kNotebookColors] (default [kDefaultNotebookColor]).
class Notebook {
  const Notebook({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.color,
    required this.visibility,
    required this.entries,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String emoji;

  /// Palette token — one of [kNotebookColors].
  final String color;
  final NotebookVisibility visibility;

  /// Dated entries, sorted ascending by date.
  final List<NotebookEntry> entries;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// The timestamp the notebook was last meaningfully written to — the newest
  /// entry date, falling back to [updatedAt], then [createdAt]. Used for
  /// newest-first sorting in the notebook list UI.
  DateTime get lastWritten => entries.isNotEmpty
      ? entries
          .map((e) => e.date)
          .reduce((a, b) => a.isAfter(b) ? a : b)
      : (updatedAt ?? createdAt);

  Notebook copyWith({
    String? id,
    String? userId,
    String? title,
    String? emoji,
    String? color,
    NotebookVisibility? visibility,
    List<NotebookEntry>? entries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Notebook(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        visibility: visibility ?? this.visibility,
        entries: entries ?? this.entries,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// JSON round-trip used by the local cache (full snapshot — distinct from the
  /// backend create/update wire shapes which live on [JournalDto]).
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'emoji': emoji,
        'color': color,
        'visibility': visibility.wire,
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Notebook.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List?) ?? const [];
    final entries = rawEntries
        .map((e) => NotebookEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final color = '${json['color'] ?? kDefaultNotebookColor}';
    return Notebook(
      id: '${json['id'] ?? ''}',
      userId: '${json['userId'] ?? ''}',
      title: '${json['title'] ?? ''}',
      emoji: '${json['emoji'] ?? ''}',
      color: kNotebookColors.contains(color) ? color : kDefaultNotebookColor,
      visibility: NotebookVisibility.fromWire(json['visibility'] as String?),
      entries: entries,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse('${json['updatedAt']}')
          : null,
    );
  }

  @override
  String toString() =>
      'Notebook(id: $id, title: $title, entries: ${entries.length})';
}

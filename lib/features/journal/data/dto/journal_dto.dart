import '../models/notebook.dart';

/// Snake_case DTO mirroring the Phase 11-01 backend `journals` table.
///
/// Maps between the backend wire shape (snake_case fields; `page` as an
/// index-keyed object `{"1": {id, content, created_at}, ...}`) and the local
/// [Notebook] / [NotebookEntry] domain models.
///
/// PINNED DECISIONS:
/// - `page` arrives as a Map keyed by string indices ("1", "2", ...). Each
///   value `{id?, content, created_at}` becomes a [NotebookEntry]; entries are
///   sorted ascending by date in [toLocal].
/// - `content` is a required backend string but unused by this client — we send
///   an empty string on create.
/// - `color` defaults to [kDefaultNotebookColor] ('green') when absent/invalid.
class JournalDto {
  JournalDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.emoji,
    required this.color,
    required this.visibility,
    required this.page,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String emoji;

  /// Palette token — one of [kNotebookColors].
  final String color;

  /// Backend wire string: 'private' | 'public'.
  final String visibility;

  /// Raw index-keyed page object as received from / sent to the backend.
  final Map<String, dynamic> page;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ---------------------------------------------------------------------------
  // Wire parsing
  // ---------------------------------------------------------------------------

  factory JournalDto.fromJson(Map<String, dynamic> json) {
    final rawPage = json['page'];
    final page = rawPage is Map
        ? rawPage.cast<String, dynamic>()
        : <String, dynamic>{};
    final rawColor = '${json['color'] ?? kDefaultNotebookColor}';
    return JournalDto(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      emoji: '${json['emoji'] ?? ''}',
      color: kNotebookColors.contains(rawColor)
          ? rawColor
          : kDefaultNotebookColor,
      visibility: '${json['visibility'] ?? 'private'}',
      page: page,
      createdAt:
          DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse('${json['updated_at']}')
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // page <-> entry-list mapping
  // ---------------------------------------------------------------------------

  /// Converts the index-keyed [page] object into a list of [NotebookEntry],
  /// sorted ascending by date.
  ///
  /// Each page value is `{id?, content, created_at}`. A fallback id is
  /// generated from the page key when `id` is absent; `created_at` falls back
  /// to [DateTime.now] when unparseable.
  static List<NotebookEntry> pageToEntries(Map<String, dynamic> page) {
    final entries = <NotebookEntry>[];
    page.forEach((key, value) {
      if (value is! Map) return;
      final map = value.cast<String, dynamic>();
      final id = (map['id'] != null && '${map['id']}'.isNotEmpty)
          ? '${map['id']}'
          : 'entry_$key';
      final content = '${map['content'] ?? ''}';
      final date =
          DateTime.tryParse('${map['created_at']}') ?? DateTime.now();
      entries.add(NotebookEntry(id: id, content: content, date: date));
    });
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  /// Rebuilds the index-keyed page object from a list of [NotebookEntry] for
  /// the `PUT /journals/{id}/page` replace call.
  ///
  /// Keys are 1-based string indices in list order:
  /// `{"1": {id, content, created_at}, "2": {...}}`.
  static Map<String, dynamic> entriesToPage(List<NotebookEntry> entries) {
    final page = <String, dynamic>{};
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      page['${i + 1}'] = {
        'id': e.id,
        'content': e.content,
        'created_at': e.date.toIso8601String(),
      };
    }
    return page;
  }

  // ---------------------------------------------------------------------------
  // Domain mapping
  // ---------------------------------------------------------------------------

  /// Backend journal → local [Notebook].
  Notebook toLocal() => Notebook(
        id: id,
        userId: userId,
        title: title,
        emoji: emoji,
        color: color,
        visibility: NotebookVisibility.fromWire(visibility),
        entries: pageToEntries(page),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Local [Notebook] → DTO (used to build create/update payloads & cache sync).
  factory JournalDto.fromLocal(Notebook nb, {required String userId}) =>
      JournalDto(
        id: nb.id,
        userId: userId,
        title: nb.title,
        emoji: nb.emoji,
        color: nb.color,
        visibility: nb.visibility.wire,
        page: entriesToPage(nb.entries),
        createdAt: nb.createdAt,
        updatedAt: nb.updatedAt,
      );

  // ---------------------------------------------------------------------------
  // Wire payloads
  // ---------------------------------------------------------------------------

  /// Full create payload. `content` is a required backend string — we send an
  /// empty string. `page` starts empty (entries are added via the entry
  /// endpoint after creation).
  Map<String, dynamic> toCreateJson() => {
        'user_id': userId,
        'title': title,
        'emoji': emoji,
        'color': color,
        'visibility': visibility,
        'page': <String, dynamic>{},
        'content': '',
      };

  /// Partial update payload for `PUT /journals/{id}` (metadata only).
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'emoji': emoji,
        'visibility': visibility,
        'color': color,
      };
}

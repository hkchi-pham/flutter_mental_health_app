/// Immutable model mirroring the extended MeRead contract from GET /users/me.
///
/// All snake_case JSON keys are mapped to camelCase fields.
/// Numeric fields default to 0 when missing or null (defensive for pre-Plan-01
/// rows or partial /me/currency responses).
/// String fields (email, avatar) default to '' so the UI never null-crashes.
///
/// Stat → field mapping (PINNED):
///   Trees planted        → tree_grown         → treeGrown
///   Journal entries      → journal_count      → journalCount
///   Conversations        → conversation_count → conversationCount
///   Badges earned        → badge_count        → badgeCount
///   Water                → water_units        → waterUnits
///   Seeds                → points             → points
class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.userName,
    required this.fullname,
    required this.email,
    required this.avatar,
    required this.points,
    required this.waterUnits,
    required this.treeGrown,
    required this.journalCount,
    required this.conversationCount,
    required this.badgeCount,
  });

  final String id;
  final String userName;
  final String fullname;
  final String email;
  final String avatar;
  final int points;
  final int waterUnits;
  final int treeGrown;
  final int journalCount;
  final int conversationCount;
  final int badgeCount;

  /// Constructs a [ProfileUser] from a snake_case JSON map as returned by
  /// `GET /api/v1/users/me` (the `data` envelope already unwrapped by the
  /// data source).
  factory ProfileUser.fromJson(Map<String, dynamic> m) {
    return ProfileUser(
      id: (m['id'] as String?) ?? '',
      userName: (m['user_name'] as String?) ?? '',
      fullname: (m['fullname'] as String?) ?? '',
      email: (m['email'] as String?) ?? '',
      avatar: (m['avatar'] as String?) ?? '',
      points: (m['points'] as num?)?.toInt() ?? 0,
      waterUnits: (m['water_units'] as num?)?.toInt() ?? 0,
      treeGrown: (m['tree_grown'] as num?)?.toInt() ?? 0,
      journalCount: (m['journal_count'] as num?)?.toInt() ?? 0,
      conversationCount: (m['conversation_count'] as num?)?.toInt() ?? 0,
      badgeCount: (m['badge_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns a copy with only the supplied fields replaced.
  ///
  /// Used for optimistic updates — e.g. after a successful name edit,
  /// the provider calls `state.copyWith(fullname: newName)` and notifies
  /// listeners immediately before the next full refresh.
  ProfileUser copyWith({
    String? fullname,
    String? avatar,
  }) {
    return ProfileUser(
      id: id,
      userName: userName,
      fullname: fullname ?? this.fullname,
      email: email,
      avatar: avatar ?? this.avatar,
      points: points,
      waterUnits: waterUnits,
      treeGrown: treeGrown,
      journalCount: journalCount,
      conversationCount: conversationCount,
      badgeCount: badgeCount,
    );
  }
}

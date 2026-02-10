class GardenState {
  final int points;
  final int maxPoints;
  final int treeLevel; // 0-5: seedling to full tree
  final DateTime? lastWatered;
  final int totalWatered;
  final bool isSeedPlanted;

  GardenState({
    this.points = 0,
    this.maxPoints = 1500,
    this.treeLevel = 0,
    this.lastWatered,
    this.totalWatered = 0,
    this.isSeedPlanted = false,
  });

  GardenState copyWith({
    int? points,
    int? maxPoints,
    int? treeLevel,
    DateTime? lastWatered,
    int? totalWatered,
    bool? isSeedPlanted,
  }) {
    return GardenState(
      points: points ?? this.points,
      maxPoints: maxPoints ?? this.maxPoints,
      treeLevel: treeLevel ?? this.treeLevel,
      lastWatered: lastWatered ?? this.lastWatered,
      totalWatered: totalWatered ?? this.totalWatered,
      isSeedPlanted: isSeedPlanted ?? this.isSeedPlanted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'maxPoints': maxPoints,
      'treeLevel': treeLevel,
      'lastWatered': lastWatered?.toIso8601String(),
      'totalWatered': totalWatered,
      'isSeedPlanted': isSeedPlanted,
    };
  }

  factory GardenState.fromJson(Map<String, dynamic> json) {
    return GardenState(
      points: json['points'] as int? ?? 0,
      maxPoints: json['maxPoints'] as int? ?? 1500,
      treeLevel: json['treeLevel'] as int? ?? 0,
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'] as String)
          : null,
      totalWatered: json['totalWatered'] as int? ?? 0,
      // Default to false if not present, or maybe true for backward compat?
      // User asked "seed is only there after user place them", so strictly false.
      // However, existing users might lose their tree.
      // Im assuming new app or reset is fine, or defaulting to true for existing json would be safer usually.
      // But let's stick to the plan: default false in constructor.
      // For fromJson, let's look at the implementation plan again:
      // "Default to false for new installs but need to consider how to handle existing state."
      // I'll default to true if treeLevel > 0, otherwise false. That makes sense.
      isSeedPlanted:
          json['isSeedPlanted'] as bool? ??
          (json['treeLevel'] != null && (json['treeLevel'] as int) > 0),
    );
  }

  // Calculate tree level based on total watered
  static int calculateLevel(int totalWatered) {
    if (totalWatered >= 50) return 5;
    if (totalWatered >= 30) return 4;
    if (totalWatered >= 15) return 3;
    if (totalWatered >= 5) return 2;
    if (totalWatered >= 1) return 1;
    return 0;
  }
}

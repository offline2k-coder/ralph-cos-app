class StreakData {
  final int currentStreak;
  final int passesAvailable;
  final DateTime lastCheckIn;
  final int totalDays;
  final int longestStreak;

  StreakData({
    required this.currentStreak,
    required this.passesAvailable,
    required this.lastCheckIn,
    required this.totalDays,
    required this.longestStreak,
  });

  factory StreakData.fromMap(Map<String, dynamic> map) {
    return StreakData(
      currentStreak: map['currentStreak'] as int,
      passesAvailable: map['passesAvailable'] as int,
      lastCheckIn: DateTime.parse(map['lastCheckIn'] as String),
      totalDays: map['totalDays'] as int,
      longestStreak: map['longestStreak'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'passesAvailable': passesAvailable,
      'lastCheckIn': lastCheckIn.toIso8601String(),
      'totalDays': totalDays,
      'longestStreak': longestStreak,
    };
  }

  StreakData copyWith({
    int? currentStreak,
    int? passesAvailable,
    DateTime? lastCheckIn,
    int? totalDays,
    int? longestStreak,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      passesAvailable: passesAvailable ?? this.passesAvailable,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      totalDays: totalDays ?? this.totalDays,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }
}

class WorkoutRecord {
  static const String boxName = 'workout_records';

  final String id;
  final DateTime date;
  final int totalRounds;
  final List<String> activities;
  final String memo;

  const WorkoutRecord({
    required this.id,
    required this.date,
    required this.totalRounds,
    required this.activities,
    required this.memo,
  });

  factory WorkoutRecord.create({
    required int totalRounds,
    required List<String> activities,
    required String memo,
  }) {
    final now = DateTime.now();
    return WorkoutRecord(
      id: now.toIso8601String(),
      date: now,
      totalRounds: totalRounds,
      activities: activities,
      memo: memo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalRounds': totalRounds,
        'activities': List<String>.from(activities),
        'memo': memo,
      };

  factory WorkoutRecord.fromMap(Map map) => WorkoutRecord(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        totalRounds: map['totalRounds'] as int,
        activities: List<String>.from(map['activities'] as List),
        memo: map['memo'] as String? ?? '',
      );
}

class Preset {
  static const String defaultName = 'Default';
  static const String boxName = 'presets';

  final String name;
  final int totalRounds;
  final int waitMinutes;
  final int waitSeconds;
  final int exerciseMinutes;
  final int exerciseSeconds;
  final int restMinutes;
  final int restSeconds;

  const Preset({
    required this.name,
    required this.totalRounds,
    required this.waitMinutes,
    required this.waitSeconds,
    required this.exerciseMinutes,
    required this.exerciseSeconds,
    required this.restMinutes,
    required this.restSeconds,
  });

  bool get isDefault => name == defaultName;

  static Preset get defaultPreset => const Preset(
        name: defaultName,
        totalRounds: 12,
        waitMinutes: 0,
        waitSeconds: 30,
        exerciseMinutes: 3,
        exerciseSeconds: 0,
        restMinutes: 0,
        restSeconds: 30,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'totalRounds': totalRounds,
        'waitMinutes': waitMinutes,
        'waitSeconds': waitSeconds,
        'exerciseMinutes': exerciseMinutes,
        'exerciseSeconds': exerciseSeconds,
        'restMinutes': restMinutes,
        'restSeconds': restSeconds,
      };

  factory Preset.fromMap(Map<dynamic, dynamic> map) => Preset(
        name: map['name'] as String,
        totalRounds: map['totalRounds'] as int,
        waitMinutes: map['waitMinutes'] as int,
        waitSeconds: map['waitSeconds'] as int,
        exerciseMinutes: map['exerciseMinutes'] as int,
        exerciseSeconds: map['exerciseSeconds'] as int,
        restMinutes: map['restMinutes'] as int,
        restSeconds: map['restSeconds'] as int,
      );

  Preset copyWith({String? name}) => Preset(
        name: name ?? this.name,
        totalRounds: totalRounds,
        waitMinutes: waitMinutes,
        waitSeconds: waitSeconds,
        exerciseMinutes: exerciseMinutes,
        exerciseSeconds: exerciseSeconds,
        restMinutes: restMinutes,
        restSeconds: restSeconds,
      );
}

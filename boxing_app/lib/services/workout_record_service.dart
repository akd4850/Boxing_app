import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_record.dart';

class WorkoutRecordService {
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(WorkoutRecord.boxName);
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> saveToday(WorkoutRecord record) async {
    await _box!.put(_todayKey(), record.toMap());
  }

  static WorkoutRecord? loadToday() {
    final data = _box!.get(_todayKey());
    if (data == null) return null;
    return WorkoutRecord.fromMap(data as Map);
  }

  static Future<void> save(WorkoutRecord record) async {
    await _box!.put(record.id, record.toMap());
  }

  static List<WorkoutRecord> getAll() {
    return _box!.keys
        .map((key) => WorkoutRecord.fromMap(_box!.get(key) as Map))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> delete(String id) async {
    await _box!.delete(id);
  }
}

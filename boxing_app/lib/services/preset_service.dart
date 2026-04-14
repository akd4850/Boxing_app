import 'package:hive_flutter/hive_flutter.dart';
import '../models/preset.dart';

class PresetService {
  static Box? _box;
  static Box? _settingsBox;

  static const String _settingsBoxName = 'settings';
  static const String _lastPresetKey = 'lastPresetName';

  static Future<void> init() async {
    _box = await Hive.openBox(Preset.boxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    await _ensureDefaultPreset();
  }

  static Future<void> _ensureDefaultPreset() async {
    if (!_box!.containsKey(Preset.defaultName)) {
      await _box!.put(Preset.defaultName, Preset.defaultPreset.toMap());
    }
  }

  static List<Preset> getAll() {
    return _box!.keys
        .map((key) => Preset.fromMap(_box!.get(key) as Map))
        .toList();
  }

  static Future<void> save(Preset preset) async {
    await _box!.put(preset.name, preset.toMap());
  }

  static Future<void> delete(String name) async {
    if (name == Preset.defaultName) return;
    await _box!.delete(name);
  }

  static Future<void> saveLastPresetName(String name) async {
    await _settingsBox!.put(_lastPresetKey, name);
  }

  static Preset loadLastPreset() {
    final name = _settingsBox!.get(_lastPresetKey, defaultValue: Preset.defaultName) as String;
    final data = _box!.get(name);
    if (data == null) return Preset.defaultPreset;
    return Preset.fromMap(data as Map);
  }
}

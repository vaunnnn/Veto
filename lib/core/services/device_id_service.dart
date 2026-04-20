import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _storageKey = 'device_id';
  String? _cachedId;

  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_storageKey);

    if (storedId != null) {
      _cachedId = storedId;
      return storedId;
    }

    final newId = const Uuid().v4();
    await prefs.setString(_storageKey, newId);
    _cachedId = newId;
    return newId;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _cachedId = null;
  }
}

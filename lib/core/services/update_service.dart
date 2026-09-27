import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String _lastSeenVersionKey = 'last_seen_version';

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<String?> getLastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenVersionKey);
  }

  Future<void> setLastSeenVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, version);
  }

  Future<void> clearLastSeenVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSeenVersionKey);
  }

  Future<bool> shouldShowUpdateScreen() async {
    final currentVersion = await getCurrentVersion();
    final lastSeenVersion = await getLastSeenVersion();
    
    // Always show update screen for current version
    return lastSeenVersion != currentVersion;
  }
}
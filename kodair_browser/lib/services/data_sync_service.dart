import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trail_node.dart';

class DataSyncService {
  
  /// Gathers all Auth, Preferences, and Trails, and dumps them into a local JSON file unconditionally
  static Future<String?> exportBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Dump Key Preferences
      final prefsMap = <String, dynamic>{
        'iisu_auth_payload': prefs.getString('iisu_auth_payload'),
        'saved_tabs': prefs.getString('saved_tabs'),
        'active_tab_index': prefs.getInt('active_tab_index'),
        'isTorEnabled': prefs.getBool('isTorEnabled'),
        'isAutoplayBlocked': prefs.getBool('isAutoplayBlocked'),
      };

      // Extract raw Trails filesystem cache
      final appDocDir = await getApplicationDocumentsDirectory();
      String trailsJson = '[]';
      final trailsFile = File('\${appDocDir.path}/kodair_trails_v1.json');
      if (await trailsFile.exists()) {
        trailsJson = await trailsFile.readAsString();
      }

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'prefs': prefsMap,
        'trails': trailsJson,
      };

      final backupJson = jsonEncode(backupData);
      
      // Dump to physical Downloads array
      Directory? targetDir = await getDownloadsDirectory();
      if (targetDir == null || !await targetDir.exists()) {
        targetDir = await getApplicationDocumentsDirectory();
      }
      
      final backupFile = File('\${targetDir.path}/kodair_backup.kdir');
      await backupFile.writeAsString(backupJson);
      
      return backupFile.path;
    } catch (e) {
      debugPrint("Export Sequence Failed: \$e");
      return null;
    }
  }

  /// Ingests a payload from the designated `.kdir` file and brutally overwrites all native context
  static Future<bool> importBackup() async {
    try {
      Directory? targetDir = await getDownloadsDirectory();
      if (targetDir == null || !await targetDir.exists()) {
        targetDir = await getApplicationDocumentsDirectory();
      }
      
      final backupFile = File('\${targetDir.path}/kodair_backup.kdir');
      if (!await backupFile.exists()) return false;

      final backupJson = await backupFile.readAsString();
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Restore Prefs
      final prefsMap = backupData['prefs'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      
      if (prefsMap['iisu_auth_payload'] != null) await prefs.setString('iisu_auth_payload', prefsMap['iisu_auth_payload']);
      if (prefsMap['saved_tabs'] != null) await prefs.setString('saved_tabs', prefsMap['saved_tabs']);
      if (prefsMap['active_tab_index'] != null) await prefs.setInt('active_tab_index', prefsMap['active_tab_index'] as int);
      if (prefsMap['isTorEnabled'] != null) await prefs.setBool('isTorEnabled', prefsMap['isTorEnabled'] as bool);
      if (prefsMap['isAutoplayBlocked'] != null) await prefs.setBool('isAutoplayBlocked', prefsMap['isAutoplayBlocked'] as bool);

      // Restore Trails unconditionally
      final trailsJson = backupData['trails'] as String?;
      if (trailsJson != null && trailsJson != '[]') {
        final appDocDir = await getApplicationDocumentsDirectory();
        final trailsFile = File('\${appDocDir.path}/kodair_trails_v1.json');
        await trailsFile.writeAsString(trailsJson);
      }

      return true;
    } catch (e) {
      debugPrint("Import Sequence Failed: \$e");
      return false;
    }
  }
}

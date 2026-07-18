import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/alarm_ringing_screen.dart';

class AlarmPoller {
  static Timer? _timer;
  static final Set<String> _notifiedIds = {};

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _checkOnce());
    _checkOnce();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> checkOnceStandalone() async {
    await _checkOnce();
  }

  static Future<void> _checkOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    await _checkAlarms(token);
    await _checkMedicines(token);
    await _checkWater(token);
    await _checkHealthLogReminder(token);
    await _checkStreakWarning(token);
  }

  static Future<void> _checkAlarms(String token) async {
    try {
      final triggersRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alarm/triggers/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (triggersRes.statusCode != 200) return;
      final data = jsonDecode(triggersRes.body);
      final List<dynamic> triggers = data is List ? data : (data['triggers'] ?? []);
      final pendingNew = triggers.where((t) {
        final id = t['id']?.toString();
        final status = t['status']?.toString();
        return id != null && status == 'pending' && !_notifiedIds.contains('alarm:$id');
      }).toList();
      if (pendingNew.isEmpty) return;
      final alarmsRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alarm/list'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final alarmsData = jsonDecode(alarmsRes.body);
      final List<dynamic> alarms = alarmsData is List ? alarmsData : (alarmsData['alarms'] ?? []);
      for (final t in pendingNew) {
        final id = t['id'].toString();
        final alarmId = t['alarm_id']?.toString();
        final alarm = alarms.firstWhere((a) => a['id']?.toString() == alarmId, orElse: () => null);
        final title = alarm != null ? (alarm['title'] ?? 'WAYK Alarm') : 'WAYK Alarm';
        _notifiedIds.add('alarm:$id');
        await NotificationService.show(title, 'You have a mission to complete!');
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => AlarmRingingScreen(
            triggerId: id,
            title: title,
            missionType: alarm != null ? (alarm['mission_type'] ?? 'make_bed') : 'make_bed',
          ),
        ));
      }
    } catch (_) {}
  }

  static Future<void> _checkMedicines(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/medicine/logs/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final List<dynamic> logs = data is List ? data : (data['logs'] ?? data['medicine_logs'] ?? []);
      for (final log in logs) {
        final id = log['id']?.toString();
        final status = log['status']?.toString();
        if (id == null || status != 'pending') continue;
        if (_notifiedIds.contains('med:$id')) continue;
        _notifiedIds.add('med:$id');
        final name = log['medicine_name'] ?? log['name'] ?? 'your medicine';
        await NotificationService.show('Medicine reminder', 'Time to take $name');
      }
    } catch (_) {}
  }

  static Future<void> _checkWater(String token) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/water/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final totalMl = (data['total_ml'] ?? 0) as num;
      final goalMl = (data['goal_ml'] ?? 2500) as num;
      final prefs = await SharedPreferences.getInstance();
      final lastReminderStr = prefs.getString('last_water_reminder_at');
      final now = DateTime.now();
      if (lastReminderStr == null) {
        await prefs.setString('last_water_reminder_at', now.toIso8601String());
        return;
      }
      final lastReminder = DateTime.tryParse(lastReminderStr);
      final dueForReminder = lastReminder == null || now.difference(lastReminder).inMinutes >= 120;
      final hourOk = now.hour >= 7 && now.hour < 22;
      if (dueForReminder && hourOk && totalMl < goalMl) {
        await prefs.setString('last_water_reminder_at', now.toIso8601String());
        await NotificationService.show('WAYK', 'Time to drink some water!');
      }
    } catch (_) {}
  }

  /// Around 6 PM, reminds the user to log BP/Sugar if they haven't
  /// logged either one today yet.
  static Future<void> _checkHealthLogReminder(String token) async {
    try {
      final now = DateTime.now();
      if (now.hour != 18) return;

      final prefs = await SharedPreferences.getInstance();
      final todayKey = 'health_reminder_${now.year}-${now.month}-${now.day}';
      if (prefs.getBool(todayKey) == true) return;

      final today = now.toIso8601String().substring(0, 10);

      final bpRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health/bp/logs'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final bpData = jsonDecode(bpRes.body);
      final List<dynamic> bpLogs = bpData['bp_logs'] ?? [];
      final loggedBpToday = bpLogs.any((l) => (l['created_at'] ?? '').toString().startsWith(today));

      final sugarRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/health/sugar/logs'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final sugarData = jsonDecode(sugarRes.body);
      final List<dynamic> sugarLogs = sugarData['sugar_logs'] ?? [];
      final loggedSugarToday = sugarLogs.any((l) => (l['created_at'] ?? '').toString().startsWith(today));

      if (!loggedBpToday || !loggedSugarToday) {
        await prefs.setBool(todayKey, true);
        await NotificationService.show('WAYK', "Don't forget to log your health readings today!");
      }
    } catch (_) {}
  }

  /// Around 9 PM, warns the user if they haven't completed any mission
  /// today, so they don't lose their streak.
  static Future<void> _checkStreakWarning(String token) async {
    try {
      final now = DateTime.now();
      if (now.hour != 21) return;

      final prefs = await SharedPreferences.getInstance();
      final todayKey = 'streak_warning_${now.year}-${now.month}-${now.day}';
      if (prefs.getBool(todayKey) == true) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/alarm/triggers/today'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(res.body);
      final List<dynamic> triggers = data is List ? data : (data['triggers'] ?? []);
      final anyCompletedToday = triggers.any((t) => t['status'] == 'completed');

      if (!anyCompletedToday && triggers.isNotEmpty) {
        await prefs.setBool(todayKey, true);
        await NotificationService.show('WAYK', "Complete a mission before midnight to keep your streak alive!");
      }
    } catch (_) {}
  }
}
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thin wrapper around the OneX backend's REST API. Every method that
/// needs auth takes the JWT token explicitly (read from AuthProvider by
/// the calling screen) rather than this service holding its own state.
class ApiService {
  static Future<Map<String, dynamic>> _authorizedGet(String path, String token) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> _authorizedPost(
    String path,
    String token, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    throw Exception(data['error']?.toString() ?? 'Request failed (${res.statusCode})');
  }

  // ---- Dashboard ----

  static Future<Map<String, dynamic>> getRewardsStatus(String token) =>
      _authorizedGet('/rewards/status', token);

  static Future<Map<String, dynamic>> getWaterToday(String token) =>
      _authorizedGet('/water/today', token);

  static Future<Map<String, dynamic>> getDashboard(String token) =>
      _authorizedGet('/health/dashboard', token);

  // ---- Alarms ----

  static Future<List<dynamic>> getAlarms(String token) async {
    final data = await _authorizedGet('/alarm/list', token);
    return (data['alarms'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createAlarm(
    String token, {
    required String title,
    required String time,
    required String repeat,
    required String missionType,
    int missionCount = 0,
    bool snoozeBlocked = false,
  }) {
    return _authorizedPost('/alarm/create', token, {
      'title': title,
      'time': time,
      'repeat': repeat,
      'mission_type': missionType,
      'mission_count': missionCount,
      'snooze_blocked': snoozeBlocked,
    });
  }

  static Future<List<dynamic>> getTodayTriggers(String token) async {
    final data = await _authorizedGet('/alarm/triggers/today', token);
    return (data['triggers'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> completeMission(
    String token,
    String triggerId, {
    String proof = '',
  }) {
    return _authorizedPost('/alarm/triggers/$triggerId/complete', token, {'proof': proof});
  }

  static Future<Map<String, dynamic>> snoozeAlarm(String token, String triggerId) {
    return _authorizedPost('/alarm/triggers/$triggerId/snooze', token);
  }

  // ---- Water ----

  static Future<Map<String, dynamic>> logWater(String token, int amountMl) {
    return _authorizedPost('/water/log', token, {'amount_ml': amountMl});
  }

  // ---- BP ----

  static Future<List<dynamic>> getBPLogs(String token) async {
    final data = await _authorizedGet('/health/bp/logs', token);
    return (data['bp_logs'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createBPLog(
    String token, {
    required int systolic,
    required int diastolic,
    required String timeOfDay,
  }) {
    return _authorizedPost('/health/bp/logs', token, {
      'systolic': systolic,
      'diastolic': diastolic,
      'time_of_day': timeOfDay,
    });
  }

  // ---- Sugar ----

  static Future<List<dynamic>> getSugarLogs(String token) async {
    final data = await _authorizedGet('/health/sugar/logs', token);
    return (data['sugar_logs'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createSugarLog(
    String token, {
    required double value,
    required String readingType,
  }) {
    return _authorizedPost('/health/sugar/logs', token, {
      'value': value,
      'reading_type': readingType,
    });
  }

  // ---- Medicine ----

  static Future<List<dynamic>> getMedicines(String token) async {
    final data = await _authorizedGet('/medicine/list', token);
    return (data['medicines'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createMedicine(
    String token, {
    required String name,
    required String dosage,
    required String times,
  }) {
    return _authorizedPost('/medicine/create', token, {
      'name': name,
      'dosage': dosage,
      'times': times,
    });
  }

  static Future<List<dynamic>> getTodayMedicineLogs(String token) async {
    final data = await _authorizedGet('/medicine/logs/today', token);
    return (data['medicine_logs'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> markMedicineTaken(String token, String logId) {
    return _authorizedPost('/medicine/logs/$logId/taken', token);
  }

  // ---- Meal plan ----

  static Future<List<dynamic>> getMealPlan(String token) async {
    final data = await _authorizedGet('/meal/plan', token);
    return (data['meal_plan'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createMealPlan(
    String token, {
    required String mealType,
    required String items,
    int calories = 0,
    String dietType = '',
    String mealTime = '',
    String notes = '',
  }) {
    return _authorizedPost('/meal/plan', token, {
      'meal_type': mealType,
      'items': items,
      'calories': calories,
      'diet_type': dietType,
      'meal_time': mealTime,
      'notes': notes,
    });
  }

  // ---- Exercise plan ----

  static Future<List<dynamic>> getExercisePlan(String token) async {
    final data = await _authorizedGet('/exercise/plan', token);
    return (data['exercise_plan'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createExercisePlan(
    String token, {
    required String category,
    required String name,
    int sets = 0,
    int reps = 0,
    int durationMin = 0,
    String level = '',
  }) {
    return _authorizedPost('/exercise/plan', token, {
      'category': category,
      'name': name,
      'sets': sets,
      'reps': reps,
      'duration_min': durationMin,
      'level': level,
    });
  }

  // ---- Grocery list ----

  static Future<List<dynamic>> getGroceryList(String token) async {
    final data = await _authorizedGet('/grocery/list', token);
    return (data['grocery_list'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> createGroceryItem(
    String token, {
    required String name,
    String quantity = '',
  }) {
    return _authorizedPost('/grocery/create', token, {'name': name, 'quantity': quantity});
  }

  static Future<Map<String, dynamic>> toggleGroceryItem(String token, String itemId) {
    return _authorizedPost('/grocery/$itemId/toggle', token);
  }

  static Future<void> deleteAlarm(String token, String alarmId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/alarm/$alarmId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _decode(res);
  }

  static Future<void> deleteGroceryItem(String token, String itemId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/grocery/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _decode(res);
  }

  // ---- Calculators ----

  static Future<Map<String, dynamic>> calculateBMI(
    String token, {
    required double heightCm,
    required double weightKg,
  }) {
    return _authorizedPost('/calc/bmi', token, {'height_cm': heightCm, 'weight_kg': weightKg});
  }

  static Future<Map<String, dynamic>> calculateCalories(
    String token, {
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
  }) {
    return _authorizedPost('/calc/calories', token, {
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
    });
  }

  // ---- Recipes ----

  static Future<List<dynamic>> suggestRecipes(
    String token, {
    String dietType = '',
    String mealType = '',
    String maxCalories = '',
  }) async {
    final params = <String, String>{};
    if (dietType.isNotEmpty) params['diet_type'] = dietType;
    if (mealType.isNotEmpty) params['meal_type'] = mealType;
    if (maxCalories.isNotEmpty) params['max_calories'] = maxCalories;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = query.isEmpty ? '/recipes/suggest' : '/recipes/suggest?$query';
    final data = await _authorizedGet(path, token);
    return (data['recipes'] as List?) ?? [];
  }

  // ---- File upload (used for photo-mission proof) ----

  static Future<String> uploadFile(String token, File file) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res);
    return data['url']?.toString() ?? '';
  }

  // ---- Analytics & rewards ----

  static Future<Map<String, dynamic>> getSummary(String token, {int days = 7}) =>
      _authorizedGet('/analytics/summary?days=$days', token);

  static Future<List<dynamic>> getBPTrend(String token, {int days = 30}) async {
    final data = await _authorizedGet('/analytics/bp/trend?days=$days', token);
    return (data['bp_trend'] as List?) ?? [];
  }

  static Future<List<dynamic>> getSugarTrend(String token, {int days = 30}) async {
    final data = await _authorizedGet('/analytics/sugar/trend?days=$days', token);
    return (data['sugar_trend'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> getRewardsStatusFull(String token) =>
      _authorizedGet('/rewards/status', token);

  // ---- AI ----

  static Future<String> chatWithAI(String token, String message) async {
    final data = await _authorizedPost('/ai/chat', token, {'message': message});
    return data['reply']?.toString() ?? '';
  }

  static Future<String> analyzeFoodPhoto(String token, File file) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/food-photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res);
    return data['analysis']?.toString() ?? '';
  }

  // ---- Community ----

  static Future<List<dynamic>> getLeaderboard(String token, {int limit = 20}) async {
    final data = await _authorizedGet('/community/leaderboard?limit=$limit', token);
    return (data['leaderboard'] as List?) ?? [];
  }

  // ---- Emergency SOS ----

  static Future<List<dynamic>> getSOSContacts(String token) async {
    final data = await _authorizedGet('/sos/contacts', token);
    return (data['contacts'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> addSOSContact(
    String token, {
    required String name,
    required String phone,
    String relationship = '',
  }) {
    return _authorizedPost('/sos/contacts', token, {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    });
  }

  static Future<void> deleteSOSContact(String token, String contactId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/sos/contacts/$contactId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _decode(res);
  }

  static Future<Map<String, dynamic>> triggerSOS(String token) {
    return _authorizedPost('/sos/trigger', token);
  }

  // ---- Export ----

  static Future<String> exportCSV(String token, String type, {int days = 30}) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/export/csv?type=$type&days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Could not export CSV');
    }
    return res.body;
  }

  static Future<List<int>> exportPDF(String token, {int days = 30}) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/export/pdf?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception('Could not export PDF');
    }
    return res.bodyBytes;
  }
}

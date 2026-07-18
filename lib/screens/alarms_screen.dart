import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/mission_types.dart';
import '../widgets/mission_complete_sheet.dart';
import 'create_alarm_screen.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  bool _loading = true;
  List<dynamic> _alarms = [];
  List<dynamic> _todayTriggers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final alarms = await ApiService.getAlarms(token);
      final triggers = await ApiService.getTodayTriggers(token);
      if (!mounted) return;
      setState(() {
        _alarms = alarms;
        _todayTriggers = triggers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreateAlarm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateAlarmScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _openMissionSheet(Map<String, dynamic> trigger) async {
    final alarmId = trigger['alarm_id'];
    final alarm = _alarms.firstWhere(
      (a) => a['id'] == alarmId,
      orElse: () => {'mission_type': 'make_bed'},
    );
    final completed = await showMissionCompleteSheet(
      context,
      triggerId: trigger['id'],
      missionType: alarm['mission_type'] ?? 'make_bed',
    );
    if (completed) _load();
  }

  Future<void> _deleteAlarm(String alarmId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await ApiService.deleteAlarm(token, alarmId);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete alarm')),
      );
    }
  }

  Future<void> _snooze(String triggerId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await ApiService.snoozeAlarm(token, triggerId);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This alarm doesn't allow snoozing!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sunrise));
    }

    final pendingToday = _todayTriggers.where((t) => t['status'] == 'pending').toList();

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          color: AppColors.sunrise,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              const Text('Alarms', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              if (pendingToday.isNotEmpty) ...[
                const Text('Today', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                ...pendingToday.map((t) => _TodayMissionCard(
                      trigger: t,
                      onComplete: () => _openMissionSheet(t),
                      onSnooze: () => _snooze(t['id']),
                    )),
                const SizedBox(height: 24),
              ],
              const Text('All alarms', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              if (_alarms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No alarms yet -- tap + to create one', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ..._alarms.map((a) {
                    final completedToday = _todayTriggers.any((t) =>
                        t['alarm_id'] == a['id'] && t['status'] == 'completed');
                    return _AlarmCard(
                      alarm: a,
                      completedToday: completedToday,
                      onDelete: () => _deleteAlarm(a['id']),
                    );
                  }),
            ],
          ),
        ),
        Positioned(
          right: 8,
          bottom: 96,
          child: FloatingActionButton(
            onPressed: _openCreateAlarm,
            backgroundColor: AppColors.sunrise,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _TodayMissionCard extends StatelessWidget {
  final Map<String, dynamic> trigger;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;

  const _TodayMissionCard({required this.trigger, required this.onComplete, required this.onSnooze});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sunrise.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sunrise.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppColors.sunrise),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Mission pending', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          TextButton(onPressed: onSnooze, child: const Text('Snooze')),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final dynamic alarm;
  final bool completedToday;
  final VoidCallback onDelete;
  const _AlarmCard({required this.alarm, required this.completedToday, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final mission = missionById(alarm['mission_type'] ?? '');
    final repeat = (alarm['repeat'] as String?) ?? 'daily';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: completedToday ? AppColors.vitality.withValues(alpha: 0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: completedToday ? AppColors.vitality.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          if (completedToday)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.check_circle_rounded, color: AppColors.vitality, size: 20),
            ),
          Text(
            alarm['time'] ?? '--:--',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alarm['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(mission.icon, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${mission.label} · $repeat',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (alarm['snooze_blocked'] == true)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.block_rounded, color: AppColors.danger, size: 18),
            ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

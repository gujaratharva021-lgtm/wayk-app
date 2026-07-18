import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_ring.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  int _streak = 0;
  int _longestStreak = 0;
  int _waterTotal = 0;
  int _waterGoal = 2500;
  int _alarmCount = 0;
  int _missionsToday = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final rewards = await ApiService.getRewardsStatus(token);
      final water = await ApiService.getWaterToday(token);
      final alarms = await ApiService.getAlarms(token);
      final triggers = await ApiService.getTodayTriggers(token);
      final completedToday = triggers.where((t) => t['status'] == 'completed').length;
      if (!mounted) return;
      setState(() {
        _streak = (rewards['current_streak'] ?? 0) as int;
        _longestStreak = (rewards['longest_streak'] ?? 0) as int;
        _waterTotal = (water['total_ml'] ?? 0) as int;
        _waterGoal = (water['goal_ml'] ?? 2500) as int;
        _alarmCount = alarms.length;
        _missionsToday = completedToday;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final waterProgress = _waterGoal > 0 ? (_waterTotal / _waterGoal).clamp(0.0, 1.0) : 0.0;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sunrise));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.sunrise,
      backgroundColor: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            children: [
              const Text('Good to see you,', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
              Text(
                auth.userName ?? 'there',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              isWide ? _buildWideBody(waterProgress) : _buildNarrowBody(waterProgress),
            ],
          );
        },
      ),
    );
  }

  // ---------- Wide / web layout: streak left, cards grid right ----------
  Widget _buildWideBody(double waterProgress) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Center(child: StreakRing(streak: _streak)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Longest streak: $_longestStreak days',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WaterCard(total: _waterTotal, goal: _waterGoal, progress: waterProgress),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickStat(icon: Icons.alarm_rounded, label: 'Alarms', value: '$_alarmCount'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickStat(icon: Icons.local_fire_department_rounded, label: 'Missions today', value: '$_missionsToday'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Narrow / mobile layout: original stacked design ----------
  Widget _buildNarrowBody(double waterProgress) {
    return Column(
      children: [
        Center(child: StreakRing(streak: _streak)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Longest streak: $_longestStreak days',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 28),
        _WaterCard(total: _waterTotal, goal: _waterGoal, progress: waterProgress),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickStat(icon: Icons.alarm_rounded, label: 'Alarms', value: '$_alarmCount'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStat(icon: Icons.local_fire_department_rounded, label: 'Missions today', value: '$_missionsToday'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  final int total;
  final int goal;
  final double progress;

  const _WaterCard({required this.total, required this.goal, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: AppColors.vitality, size: 20),
              const SizedBox(width: 8),
              const Text('Water intake', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(
                '${total}ml / ${goal}ml',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation(AppColors.vitality),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.sunrise, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
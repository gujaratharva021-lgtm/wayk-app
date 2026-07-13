import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'bp_screen.dart';
import 'medicine_screen.dart';
import 'sugar_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _loading = true;
  int _waterTotal = 0;
  int _waterGoal = 2500;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final water = await ApiService.getWaterToday(token);
      if (!mounted) return;
      setState(() {
        _waterTotal = (water['total_ml'] ?? 0) as int;
        _waterGoal = (water['goal_ml'] ?? 2500) as int;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addWater(int amount) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await ApiService.logWater(token, amount);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.sunrise));
    }

    final waterProgress = _waterGoal > 0 ? (_waterTotal / _waterGoal).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.sunrise,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          const Text('Health', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          Container(
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
                    Text('${_waterTotal}ml / ${_waterGoal}ml', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: waterProgress,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: const AlwaysStoppedAnimation(AppColors.vitality),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _waterButton('+250ml', 250),
                    const SizedBox(width: 10),
                    _waterButton('+500ml', 500),
                    const SizedBox(width: 10),
                    _waterButton('+1L', 1000),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Patient sections', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),

          _NavCard(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.danger,
            title: 'Blood Pressure',
            subtitle: 'Log & track your BP',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BPScreen())),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: Icons.bloodtype_rounded,
            iconColor: AppColors.vitality,
            title: 'Blood Sugar',
            subtitle: 'Log & track your sugar levels',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SugarScreen())),
          ),
          const SizedBox(height: 10),
          _NavCard(
            icon: Icons.medication_rounded,
            iconColor: AppColors.sunrise,
            title: 'Medicines',
            subtitle: 'Reminders & dose tracking',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MedicineScreen())),
          ),
        ],
      ),
    );
  }

  Widget _waterButton(String label, int amount) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _addWater(amount),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.vitality),
          foregroundColor: AppColors.vitality,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

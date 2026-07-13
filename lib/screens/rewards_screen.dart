import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/streak_ring.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _loading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  List<dynamic> _badges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final data = await ApiService.getRewardsStatusFull(token);
      if (!mounted) return;
      setState(() {
        _currentStreak = (data['current_streak'] ?? 0) as int;
        _longestStreak = (data['longest_streak'] ?? 0) as int;
        _badges = (data['badges'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunrise))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.sunrise,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Center(child: StreakRing(streak: _currentStreak, cap: 30)),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Longest streak: $_longestStreak days',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Badges', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: _badges.map((b) {
                      final unlocked = b['unlocked'] == true;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: unlocked ? AppColors.sunrise.withValues(alpha: 0.12) : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: unlocked ? AppColors.sunrise.withValues(alpha: 0.5) : AppColors.border,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                              color: unlocked ? AppColors.sunrise : AppColors.textMuted,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b['label'] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: unlocked ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }
}

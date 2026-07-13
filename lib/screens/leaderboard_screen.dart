import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = true;
  List<dynamic> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final entries = await ApiService.getLeaderboard(token);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static const _medalColors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunrise))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.sunrise,
              backgroundColor: AppColors.surface,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Text('No one on the leaderboard yet', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final entry = _entries[i];
                        final isTop3 = i < 3;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTop3 ? _medalColors[i].withValues(alpha: 0.5) : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: isTop3
                                    ? Icon(Icons.emoji_events_rounded, color: _medalColors[i], size: 26)
                                    : Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: AppColors.sunrise, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${entry['longest_streak'] ?? 0}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

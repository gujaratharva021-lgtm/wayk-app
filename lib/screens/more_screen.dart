import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'ai_chat_screen.dart';
import 'analytics_screen.dart';
import 'calculator_screen.dart';
import 'exercise_plan_screen.dart';
import 'food_scanner_screen.dart';
import 'grocery_screen.dart';
import 'leaderboard_screen.dart';
import 'meal_plan_screen.dart';
import 'recipes_screen.dart';
import 'rewards_screen.dart';
import 'sos_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.sunrise.withValues(alpha: 0.15),
                  child: Text(
                    (auth.userName?.isNotEmpty ?? false) ? auth.userName![0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, color: AppColors.sunrise, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.userName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Text('WAYK member', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const Text('AI & Insights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.smart_toy_rounded,
              iconColor: AppColors.vitality,
              title: 'AI Assistant',
              subtitle: 'Chat about your health & habits',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AIChatScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.camera_alt_rounded,
              iconColor: AppColors.sunrise,
              title: 'Food Scanner',
              subtitle: 'Photo-based calorie detection',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoodScannerScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.bar_chart_rounded,
              iconColor: AppColors.vitality,
              title: 'Analytics',
              subtitle: 'Trends, summary & data export',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.emoji_events_rounded,
              iconColor: AppColors.sunrise,
              title: 'Rewards',
              subtitle: 'Streak badges & milestones',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RewardsScreen())),
            ),

            const SizedBox(height: 24),
            const Text('Community & Safety', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.leaderboard_rounded,
              iconColor: AppColors.vitality,
              title: 'Leaderboard',
              subtitle: 'See how you rank on streaks',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.sos_rounded,
              iconColor: AppColors.danger,
              title: 'Emergency SOS',
              subtitle: 'Alert your emergency contacts',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SOSScreen())),
            ),

            const SizedBox(height: 24),
            const Text('Diet & Fitness', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.restaurant_menu_rounded,
              iconColor: AppColors.sunrise,
              title: 'Meal Plan',
              subtitle: 'Plan breakfast, lunch, dinner & snacks',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MealPlanScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.fitness_center_rounded,
              iconColor: AppColors.vitality,
              title: 'Exercise Plan',
              subtitle: 'Warm-up, cardio, strength & more',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExercisePlanScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.shopping_cart_rounded,
              iconColor: AppColors.sunrise,
              title: 'Grocery List',
              subtitle: 'Keep track of what to buy',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroceryScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.restaurant_rounded,
              iconColor: AppColors.vitality,
              title: 'Recipe Suggestions',
              subtitle: 'Browse recipes by diet & meal type',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecipesScreen())),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.calculate_rounded,
              iconColor: AppColors.sunrise,
              title: 'Calculators',
              subtitle: 'BMI & daily calorie needs',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalculatorScreen())),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              onTap: () => auth.logout(),
            ),
          ],
        );
      },
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

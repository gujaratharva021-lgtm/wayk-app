import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _loading = true;
  List<dynamic> _recipes = [];
  String _dietType = '';
  String _mealType = '';

  static const _dietTypes = ['', 'veg', 'non_veg', 'vegan'];
  static const _mealTypes = ['', 'breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final recipes = await ApiService.suggestRecipes(token, dietType: _dietType, mealType: _mealType);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
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
      appBar: AppBar(title: const Text('Recipes')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietTypes.map((d) {
                      final selected = _dietType == d;
                      return _filterChip(d.isEmpty ? 'All diets' : d.replaceAll('_', ' '), selected, () {
                        setState(() => _dietType = d);
                        _load();
                      });
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealTypes.map((m) {
                      final selected = _mealType == m;
                      return _filterChip(m.isEmpty ? 'All meals' : m, selected, () {
                        setState(() => _mealType = m);
                        _load();
                      });
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.sunrise))
                  : _recipes.isEmpty
                      ? const Center(
                          child: Text('No recipes match these filters', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          itemCount: _recipes.length,
                          itemBuilder: (context, i) {
                            final r = _recipes[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                      ),
                                      if ((r['calories'] ?? 0) > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.sunrise.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${r['calories']} kcal',
                                            style: const TextStyle(color: AppColors.sunrise, fontSize: 11, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    r['ingredients'] ?? '',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    r['instructions'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunrise : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.sunrise : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

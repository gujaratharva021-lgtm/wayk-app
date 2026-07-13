import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _loading = true;
  List<dynamic> _meals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final meals = await ApiService.getMealPlan(token);
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddMealSheet(),
    );
    if (added == true) _load();
  }

  static const _mealIcons = {
    'breakfast': Icons.free_breakfast_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'dinner': Icons.dinner_dining_rounded,
    'snack': Icons.cookie_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.sunrise,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunrise))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.sunrise,
              backgroundColor: AppColors.surface,
              child: _meals.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Text('No meals planned -- tap + to add one', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _meals.length,
                      itemBuilder: (context, i) {
                        final meal = _meals[i];
                        final icon = _mealIcons[meal['meal_type']] ?? Icons.restaurant_rounded;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: AppColors.sunrise),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (meal['meal_type'] ?? '').toString().toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                                    ),
                                    Text(meal['items'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if ((meal['calories'] ?? 0) > 0)
                                      Text(
                                        '${meal['calories']} kcal',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                  ],
                                ),
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

class _AddMealSheet extends StatefulWidget {
  const _AddMealSheet();

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _itemsController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _mealType = 'breakfast';
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_itemsController.text.trim().isEmpty) {
      setState(() => _error = 'Describe what you\'re eating');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.createMealPlan(
        token,
        mealType: _mealType,
        items: _itemsController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 0,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not save meal. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add meal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
              final selected = _mealType == type;
              return InkWell(
                onTap: () => setState(() => _mealType = type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.sunrise : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      color: selected ? Colors.black : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _itemsController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'What are you eating?'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Calories (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Save meal'),
            ),
          ),
        ],
      ),
    );
  }
}

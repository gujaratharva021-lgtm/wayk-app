import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool _showBMI = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculators')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(child: _tabButton('BMI', _showBMI, () => setState(() => _showBMI = true))),
                  const SizedBox(width: 10),
                  Expanded(child: _tabButton('Calories', !_showBMI, () => setState(() => _showBMI = false))),
                ],
              ),
            ),
            Expanded(child: _showBMI ? const _BMICalculator() : const _CalorieCalculator()),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunrise : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.sunrise : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BMICalculator extends StatefulWidget {
  const _BMICalculator();

  @override
  State<_BMICalculator> createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<_BMICalculator> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _calculate() async {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null) {
      setState(() => _error = 'Enter valid height and weight');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      final result = await ApiService.calculateBMI(token, heightCm: height, weightKg: weight);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not calculate. Try again.';
      });
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'normal':
        return AppColors.vitality;
      case 'underweight':
      case 'overweight':
        return AppColors.sunrise;
      case 'obese':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Height (cm)'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _calculate,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Calculate BMI'),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '${_result!['bmi']}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _categoryColor(_result!['category']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (_result!['category'] ?? '').toString().toUpperCase(),
                    style: TextStyle(
                      color: _categoryColor(_result!['category']),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CalorieCalculator extends StatefulWidget {
  const _CalorieCalculator();

  @override
  State<_CalorieCalculator> createState() => _CalorieCalculatorState();
}

class _CalorieCalculatorState extends State<_CalorieCalculator> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const _activityLevels = ['sedentary', 'light', 'moderate', 'active', 'very_active'];

  Future<void> _calculate() async {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (age == null || height == null || weight == null) {
      setState(() => _error = 'Enter valid age, height, and weight');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      final result = await ApiService.calculateCalories(
        token,
        age: age,
        gender: _gender,
        heightCm: height,
        weightKg: weight,
        activityLevel: _activityLevel,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not calculate. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            _genderChip('male', 'Male'),
            const SizedBox(width: 10),
            _genderChip('female', 'Female'),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Age'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Height (cm)'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        const SizedBox(height: 14),
        const Text('Activity level', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _activityLevels.map((level) {
            final selected = _activityLevel == level;
            return InkWell(
              onTap: () => setState(() => _activityLevel = level),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.sunrise : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level.replaceAll('_', ' '),
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _calculate,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Calculate calories'),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('${_result!['bmr']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const Text('BMR', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_result!['tdee']}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.vitality),
                      ),
                      const Text('TDEE (maintain)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _genderChip(String value, String label) {
    final selected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.sunrise : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.sunrise : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

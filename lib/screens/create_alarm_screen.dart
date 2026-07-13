import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/mission_types.dart';

class CreateAlarmScreen extends StatefulWidget {
  const CreateAlarmScreen({super.key});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  final _titleController = TextEditingController();
  final _pushupCountController = TextEditingController(text: '10');
  TimeOfDay _time = const TimeOfDay(hour: 6, minute: 30);
  final Set<String> _selectedDays = {}; // empty = daily
  String _missionType = missionTypes.first.id;
  bool _snoozeBlocked = false;
  bool _submitting = false;
  String? _error;

  static const _dayLabels = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.surface,
            dialBackgroundColor: AppColors.surfaceHigh,
            hourMinuteColor: AppColors.surfaceHigh,
            dayPeriodColor: AppColors.surfaceHigh,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Give your alarm a title');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    final repeatStr = _selectedDays.isEmpty ? 'daily' : _selectedDays.join(',');
    final count = _missionType == 'pushups' ? int.tryParse(_pushupCountController.text) ?? 10 : 0;

    try {
      await ApiService.createAlarm(
        token,
        title: _titleController.text.trim(),
        time: timeStr,
        repeat: repeatStr,
        missionType: _missionType,
        missionCount: count,
        snoozeBlocked: _snoozeBlocked,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create alarm. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pushupCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Alarm')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Alarm title',
                hintText: 'e.g. Morning workout',
              ),
            ),
            const SizedBox(height: 20),

            const Text('Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.sunrise),
                    const SizedBox(width: 12),
                    Text(_time.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final day = _dayLabels[i];
                final selected = _selectedDays.contains(day);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() {
                        selected ? _selectedDays.remove(day) : _selectedDays.add(day);
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.sunrise : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.sunrise : AppColors.border),
                        ),
                        child: Text(
                          _dayShort[i],
                          style: TextStyle(
                            color: selected ? Colors.black : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedDays.isEmpty ? 'Repeats every day' : 'Repeats on selected days',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),

            const Text('Mission to stop the alarm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: missionTypes.map((m) {
                final selected = m.id == _missionType;
                return InkWell(
                  onTap: () => setState(() => _missionType = m.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.sunrise.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.sunrise : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 18, color: selected ? AppColors.sunrise : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          m.label,
                          style: TextStyle(
                            color: selected ? AppColors.sunrise : AppColors.textPrimary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_missionType == 'pushups') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _pushupCountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Number of push-ups'),
              ),
            ],

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                value: _snoozeBlocked,
                onChanged: (v) => setState(() => _snoozeBlocked = v),
                activeThumbColor: AppColors.sunrise,
                contentPadding: EdgeInsets.zero,
                title: const Text('No snooze', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'You must complete the mission to stop the alarm',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],

            const SizedBox(height: 28),
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
                    : const Text('Create Alarm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

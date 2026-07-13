import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  bool _loading = true;
  List<dynamic> _medicines = [];
  List<dynamic> _todayLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final meds = await ApiService.getMedicines(token);
      final logs = await ApiService.getTodayMedicineLogs(token);
      if (!mounted) return;
      setState(() {
        _medicines = meds;
        _todayLogs = logs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markTaken(String logId) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await ApiService.markMedicineTaken(token, logId);
      _load();
    } catch (_) {}
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddMedicineSheet(),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  if (_todayLogs.isNotEmpty) ...[
                    const Text("Today's doses", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    ..._todayLogs.map((log) {
                      final medicine = _medicines.firstWhere(
                        (m) => m['id'] == log['medicine_id'],
                        orElse: () => {'name': 'Medicine'},
                      );
                      final taken = log['status'] == 'taken';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: taken ? AppColors.surface : AppColors.sunrise.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: taken ? AppColors.border : AppColors.sunrise.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              taken ? Icons.check_circle_rounded : Icons.medication_rounded,
                              color: taken ? AppColors.vitality : AppColors.sunrise,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(medicine['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    log['scheduled_time'] ?? '',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (!taken)
                              TextButton(
                                onPressed: () => _markTaken(log['id']),
                                child: const Text('Mark taken'),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  const Text('All medicines', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (_medicines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('No medicines added yet', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  else
                    ..._medicines.map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.medication_rounded, color: AppColors.textMuted),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      '${m['dosage'] ?? ''} · ${m['times'] ?? ''}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

class _AddMedicineSheet extends StatefulWidget {
  const _AddMedicineSheet();

  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _submitting = false;
  String? _error;

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
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
    if (picked != null) setState(() => _times[index] = picked);
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Give the medicine a name');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    final timesStr = _times
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .join(',');

    try {
      await ApiService.createMedicine(
        token,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        times: timesStr,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not add medicine. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
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
          const Text('Add medicine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Medicine name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _dosageController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)'),
          ),
          const SizedBox(height: 16),
          const Text('Reminder times', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _times.length; i++)
                InkWell(
                  onTap: () => _pickTime(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_times[i].format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              InkWell(
                onTap: () => setState(() => _times.add(const TimeOfDay(hour: 20, minute: 0))),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.sunrise, size: 18),
                ),
              ),
            ],
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
                  : const Text('Add medicine'),
            ),
          ),
        ],
      ),
    );
  }
}

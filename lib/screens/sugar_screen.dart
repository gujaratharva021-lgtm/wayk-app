import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SugarScreen extends StatefulWidget {
  const SugarScreen({super.key});

  @override
  State<SugarScreen> createState() => _SugarScreenState();
}

class _SugarScreenState extends State<SugarScreen> {
  bool _loading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final logs = await ApiService.getSugarLogs(token);
      if (!mounted) return;
      setState(() {
        _logs = logs;
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
      builder: (_) => const _AddSugarSheet(),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Sugar')),
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
              child: _logs.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Text('No readings yet -- tap + to log one', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: _logs.length,
                      itemBuilder: (context, i) {
                        final log = _logs[i];
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
                              const Icon(Icons.bloodtype_rounded, color: AppColors.vitality),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log['value']}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    Text(
                                      '${log['reading_type'] ?? ''} · ${_formatDate(log['recorded_at'])}',
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _AddSugarSheet extends StatefulWidget {
  const _AddSugarSheet();

  @override
  State<_AddSugarSheet> createState() => _AddSugarSheetState();
}

class _AddSugarSheetState extends State<_AddSugarSheet> {
  final _valueController = TextEditingController();
  String _readingType = 'fasting';
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final value = double.tryParse(_valueController.text);
    if (value == null) {
      setState(() => _error = 'Enter a valid number');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.createSugarLog(token, value: value, readingType: _readingType);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not save reading. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
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
          const Text('Log blood sugar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Reading (mg/dL)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _typeChip('fasting', 'Fasting'),
              const SizedBox(width: 10),
              _typeChip('post_prandial', 'Post-meal'),
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
                  : const Text('Save reading'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _readingType == value;
    return InkWell(
      onTap: () => setState(() => _readingType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.sunrise : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

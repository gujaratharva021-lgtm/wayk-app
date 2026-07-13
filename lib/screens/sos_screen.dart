import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _loading = true;
  bool _triggering = false;
  List<dynamic> _contacts = [];
  String? _triggerMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final contacts = await ApiService.getSOSContacts(token);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await ApiService.deleteSOSContact(token, id);
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
      builder: (_) => const _AddContactSheet(),
    );
    if (added == true) _load();
  }

  Future<void> _trigger() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Trigger SOS?'),
        content: const Text('This will alert your emergency contacts. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Trigger SOS', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _triggering = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final result = await ApiService.triggerSOS(token);
      if (!mounted) return;
      setState(() {
        _triggering = false;
        _triggerMessage = 'SOS sent! ${result['app_users_pushed'] ?? 0} contact(s) notified via push.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _triggering = false;
        _triggerMessage = 'Could not trigger SOS. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.sos_rounded, color: AppColors.danger, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          'In an emergency, tap below to alert your contacts',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_contacts.isEmpty || _triggering) ? null : _trigger,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                            child: _triggering
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('TRIGGER SOS'),
                          ),
                        ),
                        if (_contacts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Add an emergency contact first', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ),
                        if (_triggerMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(_triggerMessage!, style: const TextStyle(color: AppColors.vitality, fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Emergency contacts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  if (_contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('No contacts added -- tap + to add one', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  else
                    ..._contacts.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppColors.surfaceHigh,
                                child: Icon(Icons.person_rounded, color: AppColors.textMuted),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(
                                      '${c['phone'] ?? ''} · ${c['relationship'] ?? ''}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                onPressed: () => _delete(c['id']),
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

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a name and phone number');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      await ApiService.addSOSContact(
        token,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationshipController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not add contact. Try again.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
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
          const Text('Add emergency contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _relationshipController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Relationship (e.g. spouse, son)'),
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
                  : const Text('Add contact'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/mission_types.dart';

/// Shows the right completion UI for a mission type, then calls the
/// backend to mark it complete. Returns true if the mission was
/// successfully completed (so the caller can refresh its list/streak).
Future<bool> showMissionCompleteSheet(
  BuildContext context, {
  required String triggerId,
  required String missionType,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MissionSheet(triggerId: triggerId, missionType: missionType),
  );
  return result ?? false;
}

class _MissionSheet extends StatefulWidget {
  final String triggerId;
  final String missionType;

  const _MissionSheet({required this.triggerId, required this.missionType});

  @override
  State<_MissionSheet> createState() => _MissionSheetState();
}

class _MissionSheetState extends State<_MissionSheet> {
  bool _submitting = false;
  String? _error;

  File? _pickedPhoto;
  final _countController = TextEditingController(text: '10');
  late int _a, _b;
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _a = rand.nextInt(20) + 1;
    _b = rand.nextInt(20) + 1;
  }

  @override
  void dispose() {
    _countController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _pickedPhoto = File(picked.path));
  }

  Future<void> _complete(String proof) async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token!;
    try {
      String finalProof = proof;
      if (_pickedPhoto != null) {
        finalProof = await ApiService.uploadFile(token, _pickedPhoto!);
      }
      await ApiService.completeMission(token, widget.triggerId, proof: finalProof);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not complete mission. Try again.';
      });
    }
  }

  void _onSubmitPressed() {
    switch (widget.missionType) {
      case 'photo_sky':
        if (_pickedPhoto == null) {
          setState(() => _error = 'Take a photo first');
          return;
        }
        _complete('');
        break;
      case 'pushups':
        _complete('${_countController.text} push-ups completed');
        break;
      case 'math':
        final correct = _a + _b;
        if (int.tryParse(_answerController.text) != correct) {
          setState(() => _error = 'Not quite -- try again');
          return;
        }
        _complete('solved: $_a + $_b = $correct');
        break;
      default:
        _complete('done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = missionById(widget.missionType);

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
          Row(
            children: [
              Icon(mission.icon, color: AppColors.sunrise, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(mission.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._buildMissionBody(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _onSubmitPressed,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Complete mission'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMissionBody() {
    switch (widget.missionType) {
      case 'photo_sky':
        return [
          const Text(
            "Snap a photo of the sky to prove you're awake!",
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (_pickedPhoto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_pickedPhoto!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(_pickedPhoto == null ? 'Open camera' : 'Retake photo'),
          ),
        ];
      case 'pushups':
        return [
          const Text('How many push-ups did you do?', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: _countController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Count'),
          ),
        ];
      case 'math':
        return [
          Text('$_a + $_b = ?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Your answer'),
          ),
        ];
      default:
        return [
          const Text(
            "Confirm you've completed this to stop the alarm.",
            style: TextStyle(color: AppColors.textMuted),
          ),
        ];
    }
  }
}

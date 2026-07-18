import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/mission_types.dart';
import '../widgets/mission_complete_sheet.dart';

/// Full-screen ringing alarm. Plays a looping sound and shows the alarm
/// title until the user completes the mission (or dismisses, if allowed).
class AlarmRingingScreen extends StatefulWidget {
  final String triggerId;
  final String title;
  final String missionType;

  const AlarmRingingScreen({
    super.key,
    required this.triggerId,
    required this.title,
    required this.missionType,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);
    } catch (_) {}
  }

  Future<void> _stopRinging() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _openMission() async {
    await _stopRinging();
    if (!mounted) return;
    final completed = await showMissionCompleteSheet(
      context,
      triggerId: widget.triggerId,
      missionType: widget.missionType,
    );
    if (completed) {
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      _startRinging();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = missionById(widget.missionType);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm_rounded, color: AppColors.sunrise, size: 80),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mission.icon, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 6),
                    Text(mission.label, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openMission,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: const Text('Complete Mission to Stop Alarm', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
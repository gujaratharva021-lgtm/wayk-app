import 'package:flutter/material.dart';

class MissionType {
  final String id;
  final String label;
  final IconData icon;

  const MissionType(this.id, this.label, this.icon);
}

const missionTypes = [
  MissionType('photo_sky', 'Photo of the sky', Icons.wb_sunny_rounded),
  MissionType('pushups', 'Push-ups', Icons.fitness_center_rounded),
  MissionType('find_object', 'Find an object', Icons.search_rounded),
  MissionType('make_bed', 'Make your bed', Icons.bed_rounded),
  MissionType('shake', 'Shake your phone', Icons.vibration_rounded),
  MissionType('math', 'Solve a math problem', Icons.calculate_rounded),
  MissionType('qr_scan', 'Scan a QR code', Icons.qr_code_scanner_rounded),
];

MissionType missionById(String id) => missionTypes.firstWhere(
      (m) => m.id == id,
      orElse: () => missionTypes.first,
    );

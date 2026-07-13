import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _loading = true;
  int _days = 7;
  Map<String, dynamic>? _summary;
  List<dynamic> _bpTrend = [];
  List<dynamic> _sugarTrend = [];
  bool _exporting = false;

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
      final summary = await ApiService.getSummary(token, days: _days);
      final bp = await ApiService.getBPTrend(token, days: _days);
      final sugar = await ApiService.getSugarTrend(token, days: _days);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _bpTrend = bp;
        _sugarTrend = sugar;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _exportCSV(String type) async {
    setState(() => _exporting = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final csv = await ApiService.exportCSV(token, type, days: _days);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wayk_${type}_export.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'WAYK $type export');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not export CSV')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final bytes = await ApiService.exportPDF(token, days: _days);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wayk_health_report.pdf');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'WAYK health report');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not export PDF')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunrise))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.sunrise,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Row(
                    children: [
                      Expanded(child: _periodChip(7, '7 days')),
                      const SizedBox(width: 10),
                      Expanded(child: _periodChip(30, '30 days')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_summary != null) _summaryGrid(),
                  const SizedBox(height: 24),
                  if (_bpTrend.length >= 2) ...[
                    const Text('Blood Pressure Trend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    _bpChart(),
                    const SizedBox(height: 24),
                  ],
                  if (_sugarTrend.length >= 2) ...[
                    const Text('Blood Sugar Trend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    _sugarChart(),
                    const SizedBox(height: 24),
                  ],
                  const Text('Export data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _exportButton('BP CSV', () => _exportCSV('bp')),
                      _exportButton('Sugar CSV', () => _exportCSV('sugar')),
                      _exportButton('Water CSV', () => _exportCSV('water')),
                      _exportButton('PDF Report', _exportPDF),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _periodChip(int days, String label) {
    final selected = _days == days;
    return InkWell(
      onTap: () {
        setState(() => _days = days);
        _load();
      },
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
          style: TextStyle(color: selected ? Colors.black : AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _summaryGrid() {
    final s = _summary!;
    final items = [
      ('Avg BP', '${s['avg_systolic']}/${s['avg_diastolic']}', AppColors.danger),
      ('Avg Sugar', '${s['avg_sugar']}', AppColors.vitality),
      ('Water', '${((s['total_water_ml'] ?? 0) / 1000).toStringAsFixed(1)}L', AppColors.vitality),
      ('Missions', '${s['missions_completed']}', AppColors.sunrise),
      ('Streak', '${s['current_streak']}d', AppColors.sunrise),
      ('Best streak', '${s['longest_streak']}d', AppColors.sunrise),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.$2, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: item.$3)),
              const SizedBox(height: 4),
              Text(item.$1, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _bpChart() {
    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];
    for (int i = 0; i < _bpTrend.length; i++) {
      sysSpots.add(FlSpot(i.toDouble(), (_bpTrend[i]['systolic'] ?? 0).toDouble()));
      diaSpots.add(FlSpot(i.toDouble(), (_bpTrend[i]['diastolic'] ?? 0).toDouble()));
    }
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(spots: sysSpots, isCurved: true, color: AppColors.danger, barWidth: 3, dotData: const FlDotData(show: false)),
            LineChartBarData(spots: diaSpots, isCurved: true, color: AppColors.vitality, barWidth: 3, dotData: const FlDotData(show: false)),
          ],
        ),
      ),
    );
  }

  Widget _sugarChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _sugarTrend.length; i++) {
      spots.add(FlSpot(i.toDouble(), (_sugarTrend[i]['value'] ?? 0).toDouble()));
    }
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(spots: spots, isCurved: true, color: AppColors.sunrise, barWidth: 3, dotData: const FlDotData(show: false)),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _exporting ? null : onTap,
      icon: const Icon(Icons.ios_share_rounded, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

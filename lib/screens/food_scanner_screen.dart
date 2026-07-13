import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  File? _photo;
  bool _analyzing = false;
  String? _result;
  String? _error;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return;

    setState(() {
      _photo = File(picked.path);
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_photo == null) return;

    setState(() {
      _analyzing = true;
      _error = null;
    });

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final analysis = await ApiService.analyzeFoodPhoto(token, _photo!);
      if (!mounted) return;
      setState(() {
        _result = analysis;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = "Couldn't analyze the photo. The AI assistant might not be configured, or you're out of quota.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Scanner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Take or pick a photo of your meal, and the AI will identify the food and estimate calories.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_photo!, height: 220, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Icon(Icons.restaurant_rounded, color: AppColors.textMuted, size: 48),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_photo == null || _analyzing) ? null : _analyze,
                child: _analyzing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Analyze food'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.vitality.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.vitality, size: 18),
                        SizedBox(width: 8),
                        Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_result!, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

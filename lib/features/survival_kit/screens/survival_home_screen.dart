import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SurvivalHomeScreen extends StatelessWidget {
  const SurvivalHomeScreen({super.key});

  // Static offline survival guides (Hardcoded for zero internet reliability)
  final List<Map<String, String>> _guides = const [
    {
      'title': 'Snake Bite First-Aid',
      'category': 'Emergency Medical',
      'description': '1. Keep the person calm and still.\n2. Do NOT cut the wound or try to suck venom.\n3. Immobilize the bitten limb below heart level.\n4. Trigger SOS immediately.',
    },
    {
      'title': 'Dehydration & Water Finding',
      'category': 'Survival Basics',
      'description': '1. Look for green vegetation or animal tracks heading downhill.\n2. Avoid stagnant muddy pools.\n3. Boil collected water for at least 3 minutes before drinking.',
    },
    {
      'title': 'Wildlife Encounter (Elephant/Predator)',
      'category': 'Danger Protocol',
      'description': '1. Do not run. Running triggers chase instinct.\n2. Back away very slowly while avoiding direct eye contact.\n3. Speak in a low, calm voice to identify yourself as human.',
    },
    {
      'title': 'Night Navigation by Stars',
      'category': 'Orientation',
      'description': '1. Locate the Big Dipper constellation.\n2. Follow the pointer stars to find Polaris (North Star).\n3. Keep North behind or ahead based on your safe-zone direction.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Survival Kit & Guides'),
        backgroundColor: AppColors.backgroundWhite,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _guides.length,
        itemBuilder: (context, index) {
          final guide = _guides[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      guide['category']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(Icons.offline_bolt, color: AppColors.primaryGreen, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  guide['title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  guide['description']!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
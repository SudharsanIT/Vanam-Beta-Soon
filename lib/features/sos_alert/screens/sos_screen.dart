import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  // 🔥 டைரக்டா கால் பண்றதுக்கான Function 🔥
  Future<void> _makeEmergencyCall(BuildContext context) async {
    // நீங்க குடுத்த நம்பர் இங்க செட் பண்ணிருக்கேன்
    final Uri launchUri = Uri(scheme: 'tel', path: '9342798462');
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('கால் செய்ய முடியவில்லை! மொபைல் டயலரை செக் பண்ணவும்.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening dialer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F11) : const Color(0xFFF4F6F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('EMERGENCY SOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.0)),
            const SizedBox(height: 8),
            Text('Press the button below to call\nForest Rangers immediately', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 50),

            // 🔥 Big Red SOS Button 🔥
            GestureDetector(
              onTap: () => _makeEmergencyCall(context), // பட்டனை க்ளிக் பண்ணா கால் போகும்
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 10),
                  ],
                ),
                child: const Center(
                  child: Text('SOS', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3.0)),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // 🔥 Call Forest Department Button 🔥
            TextButton.icon(
              onPressed: () => _makeEmergencyCall(context), // இந்த பட்டனுக்கும் அதே கால் லாஜிக் தான்
              icon: const Icon(Icons.call, color: Colors.green),
              label: const Text('Call Forest Department', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
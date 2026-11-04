import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumWeatherCard extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;
  final String placeLabel;
  final String currentTime;
  final VoidCallback onTap;

  const PremiumWeatherCard({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.placeLabel,
    required this.currentTime,
    required this.onTap,
  });

  // ==========================================
  // 🔥 ULTIMATE 24-HOUR DYNAMIC BACKGROUND LOGIC 🔥
  // ==========================================

  int _getWeatherCode() => int.tryParse(weather?['weatherCode']?.toString() ?? '') ?? 0;

  bool _isNight() {
    final hour = DateTime.now().hour;
    return hour >= 19 || hour < 5; // 7 PM to 4 AM is considered Night for Icons
  }

  // Exact 24-Hour Timeline Image Resolver
  String _getSceneImage() {
    final hour = DateTime.now().hour;
    final code = _getWeatherCode();

    if (code >= 95) {
      if (hour >= 6 && hour < 18) {
        return 'https://images.unsplash.com/photo-1600377927594-ceae8f8981a6?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fHRodW5kZXJzdHJvbSUyMGFmdGVybm9vbnxlbnwwfHwwfHx8MA%3D%3D';
      } else {
        return 'https://plus.unsplash.com/premium_photo-1674684223891-5340fdb15256?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTd8fHRodW5kZXJzdHJvbSUyMGFmdGVybm9vbnxlbnwwfHwwfHx8MA%3D%3D';
      }
    }

    if (code == 63 || code == 65 || code == 66 || code == 67 || code == 81 || code == 82) {
      if (hour >= 6 && hour < 18) {
        return 'https://images.unsplash.com/photo-1692362385851-cf68a6d9604b?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8TW9kZXJhdGUlMjB0byUyMEhlYXZ5JTIwUmFpbiUyMG5pZ2h0fGVufDB8fDB8fHww';
      } else {
        return 'https://images.unsplash.com/photo-1562781105-c53c27ff6007?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fE1vZGVyYXRlJTIwdG8lMjBIZWF2eSUyMFJhaW4lMjBuaWdodHxlbnwwfHwwfHx8MA%3D%3D';
      }
    }

    if ((code >= 51 && code <= 61) || code == 80) {
      if (hour >= 6 && hour < 17) {
        return 'https://images.unsplash.com/photo-1623508488401-badfadea0157?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mzl8fGxpZ2h0JTIwUmFpbiUyMGRheXxlbnwwfHwwfHx8MA%3D%3D';
      } else if (hour >= 17 && hour < 19) {
        return 'https://images.unsplash.com/photo-1475917446375-09326db30f7a?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8bGlnaHQlMjBSYWluJTIwbW9ybmluZ3xlbnwwfHwwfHx8MA%3D%3D';
      } else {
        return 'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8cmFpbnklMjBuaWdodHxlbnwwfHwwfHx8MA%3D%3D';
      }
    }

    if (code >= 71 && code <= 86 && code != 80 && code != 81 && code != 82) {
      if (hour >= 6 && hour < 18) {
        return 'https://plus.unsplash.com/premium_photo-1687879794744-99e2898cab0d?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjF8fG1pc3R5JTIwZGF5fGVufDB8fDB8fHww';
      } else {
        return 'https://images.unsplash.com/photo-1545294477-c0a0b8033797?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fG1pc3R5JTIwbmlnaHR8ZW58MHx8MHx8fDA%3D';
      }
    }

    if (code == 45 || code == 48) {
      if (hour >= 5 && hour < 10) {
        return 'https://plus.unsplash.com/premium_photo-1669613233573-4911a0a81c63?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8TW9ybmluZyUyMEZvZyUyMGltYWdlfGVufDB8fDB8fHww';
      } else if (hour >= 17 && hour < 19) {
        return 'https://images.unsplash.com/photo-1695135670992-6966cf584753?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjB8fGV2ZW5pbmclMjBGb2clMjBpbWFnZXxlbnwwfHwwfHx8MA%3D%3D';
      } else {
        return 'https://plus.unsplash.com/premium_photo-1711311208853-51bdcf36f040?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8ZGFyayUyMEZvZyUyMGltYWdlfGVufDB8fDB8fHww';
      }
    }

    if (code == 2 || code == 3) {
      if (hour >= 5 && hour < 8) {
        return 'https://plus.unsplash.com/premium_photo-1726192458262-daa5c3cd47d5?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8NSUyMEFNJTIwLSUyMDglMjBBTSUzQSUyMFN1bnJpc2UlMjBDbG91ZHN8ZW58MHx8MHx8fDA%3D';
      } else if (hour >= 8 && hour < 12) {
        return 'https://plus.unsplash.com/premium_photo-1666605659871-7ee46f5c6688?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8OCUyMEFNJTIwLSUyMDEyJTIwUE0lM0ElMjBNb3JuaW5nJTIwQ2xvdWRzfGVufDB8fDB8fHww';
      } else if (hour >= 12 && hour < 16) {
        return 'https://images.unsplash.com/photo-1547963802-25f153e14080?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8QWZ0ZXJub29uJTIwQ2xvdWRzfGVufDB8fDB8fHww';
      } else if (hour >= 16 && hour < 18) {
        return 'https://images.unsplash.com/photo-1510551907209-df882418d5cf?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8TGF0ZSUyMEFmdGVybm9vbiUyMENsb3Vkc3xlbnwwfHwwfHx8MA%3D%3D';
      } else if (hour >= 18 && hour < 19) {
        return 'https://plus.unsplash.com/premium_photo-1668091148044-056cd744e64a?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8U3Vuc2V0JTIwQ2xvdWRzfGVufDB8fDB8fHww';
      } else {
        return 'https://images.unsplash.com/photo-1690762733108-cb8a0ed72880?w=1080&auto=format&fit=crop&q=80';
      }
    }

    if (hour >= 5 && hour < 7) {
      return 'https://plus.unsplash.com/premium_photo-1784206726631-7c5d45551618?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDE2fHx8ZW58MHx8fHx8';
    } else if (hour >= 7 && hour < 11) {
      return 'https://plus.unsplash.com/premium_photo-1732024931426-7f0d7dde2eab?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8bW9ybmluZyUyMHNreSUyMDclMjAwJTIwY2xvY2t8ZW58MHx8MHx8fDA%3D';
    } else if (hour >= 11 && hour < 15) {
      return 'https://images.unsplash.com/photo-1615286628718-4a4c8924d0eb?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTV8fGRheSUyMHN1bnxlbnwwfHwwfHx8MA%3D%3D';
    } else if (hour >= 15 && hour < 17) {
      return 'https://images.unsplash.com/photo-1608024611569-aace51b0d952?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8YWZ0ZXJub29uJTIwc2t5fGVufDB8fDB8fHww';
    } else if (hour >= 17 && hour < 19) {
      return 'https://images.unsplash.com/photo-1621704161179-ff6628e04f2a?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8YWZ0ZXJub29uJTIwc3VuJTIwc2t5fGVufDB8fDB8fHww';
    } else if (hour >= 19 && hour < 21) {
      return 'https://images.unsplash.com/photo-1678381569197-e80aef5157d0?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTR8fG1vb24lMjBza3l8ZW58MHx8MHx8fDA%3D';
    } else {
      return 'https://images.unsplash.com/photo-1777749496777-7364be02d918?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjB8fGRlZXAlMjBuaWdodCUyMHNreXxlbnwwfHwwfHx8MA%3D%3D';
    }
  }

  // Exact 24-Hour Headline Resolver
  String _getSceneHeadline() {
    final hour = DateTime.now().hour;
    final code = _getWeatherCode();

    if (code >= 95) return 'Severe Thunderstorms Warning';
    if (code == 63 || code == 65 || code == 66 || code == 67 || code == 81 || code == 82) return 'Heavy Rainfall Alert';
    if ((code >= 51 && code <= 61) || code == 80) return 'Light Rain & Drizzle';
    if (code >= 71 && code <= 86 && code != 80 && code != 81 && code != 82) return 'Snow Conditions Active';
    if (code == 45 || code == 48) return 'Low Visibility Fog';

    if (code == 2 || code == 3) {
      if (hour >= 5 && hour < 12) return 'Cloudy Morning Skies';
      if (hour >= 12 && hour < 17) return 'Overcast Afternoon';
      if (hour >= 17 && hour < 19) return 'Dramatic Cloudy Sunset';
      return 'Dark Overcast Night';
    }

    // Clear Skies Texts based on Time
    if (hour >= 5 && hour < 7) return 'Early Dawn & Sunrise';
    if (hour >= 7 && hour < 11) return 'Clear & Sunny Morning';
    if (hour >= 11 && hour < 15) return 'Scorching Midday Sun';
    if (hour >= 15 && hour < 17) return 'Warm Clear Afternoon';
    if (hour >= 17 && hour < 19) return 'Golden Hour Sunset';
    if (hour >= 19 && hour < 21) return 'Evening Twilight';
    return 'Crisp Starry Night';
  }

  String _getDateString() {
    final now = DateTime.now();
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "Today, ${now.day} ${months[now.month - 1]}";
  }

  Widget _buildRichWeatherIcon(int code, bool isDay) {
    if (code >= 95) return const Icon(Icons.thunderstorm_rounded, color: Colors.white, size: 64, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]);
    if (code >= 51 && code <= 82) return const Icon(Icons.cloudy_snowing, color: Colors.white, size: 64, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]);
    if (code == 0) return Icon(isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: isDay ? const Color(0xFFFFD600) : Colors.white, size: 64, shadows: const [Shadow(color: Colors.black45, blurRadius: 10)]);

    return SizedBox(
        width: 72,
        height: 64,
        child: Stack(
            children: [
              Positioned(top: 0, right: 0, child: Icon(isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: isDay ? const Color(0xFFFFD600) : Colors.white70, size: 48, shadows: const [Shadow(color: Colors.black45, blurRadius: 10)])),
              const Positioned(bottom: 0, left: 0, child: Icon(Icons.cloud_rounded, color: Colors.white, size: 54, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]))
            ]
        )
    );
  }

  Widget _buildCapsuleItem(IconData icon, String label, String value) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))
              ]
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black45, blurRadius: 2)]))
        ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final temp = weather?['temp']?.toString().replaceAll('°C', '') ?? '--';
    final condition = weather?['condition']?.toString() ?? '--';
    final feels = weather?['feelsLike']?.toString() ?? '--';
    final humidity = weather?['humidity']?.toString() ?? '--';
    final wind = weather?['windSpeed']?.toString() ?? '--';
    final pressure = weather?['pressure']?.toString() ?? '--';
    final state = weather?['state']?.toString() ?? 'Tamil Nadu, India';

    final dynamicImage = _getSceneImage();
    final dynamicHeadline = _getSceneHeadline();
    final weatherCodeValue = _getWeatherCode();
    final isDayTime = !_isNight();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 380,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
            image: DecorationImage(image: NetworkImage(dynamicImage), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.15), BlendMode.darken)),
          ),
          child: Stack(
            children: [
              Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.black.withValues(alpha: 0.7)], stops: const [0.0, 0.4, 1.0]))),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 24, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(placeLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black45, blurRadius: 6)])),
                              Text(state, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                            ],
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(temp, style: const TextStyle(fontSize: 90, fontWeight: FontWeight.w300, color: Colors.white, height: 1.0, letterSpacing: -3, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
                                const Padding(padding: EdgeInsets.only(top: 8.0, left: 2), child: Text('°C', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 8)]))),
                              ],
                            ),
                            _buildRichWeatherIcon(weatherCodeValue, isDayTime),
                          ],
                        ),
                        Text(dynamicHeadline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.5, shadows: [Shadow(color: Colors.black45, blurRadius: 6)])),
                        const SizedBox(height: 16),
                        Container(width: 140, height: 1.5, color: Colors.white.withValues(alpha: 0.25)),
                        const SizedBox(height: 16),
                        Row(children: [const Icon(Icons.device_thermostat_rounded, color: Colors.white, size: 18, shadows: [Shadow(color: Colors.black45, blurRadius: 2)]), const SizedBox(width: 10), Text('Feels like $feels', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]))]),
                        const SizedBox(height: 8),
                        Row(children: [const Icon(Icons.water_drop_outlined, color: Colors.white, size: 18, shadows: [Shadow(color: Colors.black45, blurRadius: 2)]), const SizedBox(width: 10), Text('Humidity $humidity', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]))]),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                              child: Row(
                                children: [
                                  _buildCapsuleItem(Icons.air_rounded, 'Wind', wind),
                                  Container(margin: const EdgeInsets.symmetric(horizontal: 16), width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                                  _buildCapsuleItem(Icons.speed_rounded, 'Pressure', pressure),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_getDateString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
                            const SizedBox(height: 4),
                            Row(children: [Text(currentTime, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])), const SizedBox(width: 6), const Icon(Icons.access_time_rounded, color: Colors.white, size: 14, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])])
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
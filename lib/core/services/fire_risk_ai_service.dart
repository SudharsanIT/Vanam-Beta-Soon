import 'dart:convert';
import 'package:http/http.dart' as http;

class FireRiskAIService {
  /// Evaluates Forest Fire Risk specifically calibrated for Tamil Nadu forest terrains.
  /// TN Forests (Western/Eastern Ghats) have high fire risks mostly during Jan-April dry seasons.
  static Map<String, dynamic> evaluateFireRisk({
    required double temp,
    required double humidity,
    required double windSpeed,
    required String locationName,
  }) {
    final now = DateTime.now();
    final month = now.month;

    // Tamil Nadu Forest Fire Season Calibration (Peak: Feb to April)
    bool isDrySeasonTN = (month >= 1 && month <= 4);

    int riskScore = 0;

    // 1. Temperature Weight
    if (temp >= 38) {
      riskScore += 40;
    } else if (temp >= 33) {
      riskScore += 25;
    } else if (temp >= 28) {
      riskScore += 10;
    }

    // 2. Humidity Weight (Lower humidity = High risk)
    if (humidity < 30) {
      riskScore += 40;
    } else if (humidity < 50) {
      riskScore += 20;
    } else if (humidity < 70) {
      riskScore += 5;
    }

    // 3. Wind Speed Weight (Spreads fire)
    if (windSpeed > 25) {
      riskScore += 20;
    } else if (windSpeed > 15) {
      riskScore += 10;
    }

    // 4. Tamil Nadu Seasonal Multiplier
    if (!isDrySeasonTN) {
      riskScore = (riskScore * 0.6).round(); // Reduced risk during monsoon/non-dry months
    }

    // Output Determination
    if (riskScore >= 65) {
      return {'level': 'High', 'colorValue': 0xFFFF5252, 'score': riskScore};
    } else if (riskScore >= 35) {
      return {'level': 'Moderate', 'colorValue': 0xFFFFB74D, 'score': riskScore};
    } else {
      return {'level': 'Low', 'colorValue': 0xFF7CB342, 'score': riskScore};
    }
  }
}
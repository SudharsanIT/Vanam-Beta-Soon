import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as developer;
import 'package:geocoding/geocoding.dart';

class WeatherService {
  WeatherService();

  static const String _weatherBoxName = 'vanam_weather_box';
  static const String _weatherDataKey = 'vanam_full_forecast';

  Future<Map<String, dynamic>?> fetchWeather(double lat, double lon) async {
    return await fetchCompleteForecast(lat, lon);
  }

  Future<Map<String, dynamic>?> fetchCompleteForecast(double lat, double lon) async {
    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
            'latitude=$lat&longitude=$lon'
            '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m'
            '&hourly=temperature_2m,precipitation_probability,weather_code'
            '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,uv_index_max'
            '&timezone=auto',
      );

      final weatherResponse = await http.get(weatherUrl).timeout(const Duration(seconds: 10));

      // 🔥 DOUBLE-BARREL GEOCODING (OSM + Native Fallback) 🔥
      String locationName = "LIVE GPS ZONE";
      String stateName = "Tamil Nadu, India";

      try {
        // Priority 1: OpenStreetMap (Most reliable for Indian Sub-localities like Mangadu)
        final geoUrl = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=14&addressdetails=1');
        final geoResponse = await http.get(geoUrl, headers: {'User-Agent': 'VanamApp/1.0'}).timeout(const Duration(seconds: 5));

        if (geoResponse.statusCode == 200) {
          final geoData = jsonDecode(geoResponse.body);
          final address = geoData['address'];
          if (address != null) {
            String? exact = address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? address['town'] ?? address['city'];
            if (exact != null && exact.trim().isNotEmpty) {
              locationName = exact;
            }
            String? state = address['state'];
            String? country = address['country'];
            if (state != null && country != null) {
              stateName = "$state, $country";
            }
          }
        }
      } catch (e) {
        // Priority 2: Native Geocoder Fallback
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String? exact = place.subLocality?.isNotEmpty == true ? place.subLocality : place.locality;
            if (exact != null && exact.isNotEmpty) locationName = exact;

            String? state = place.administrativeArea;
            String? country = place.country;
            if (state != null && country != null) stateName = "$state, $country";
          }
        } catch (e2) {
          developer.log('All geocoding failed', name: 'Vanam.Weather');
        }
      }

      if (weatherResponse.statusCode == 200) {
        final rawData = jsonDecode(weatherResponse.body);
        final current = rawData['current'];
        final hourly = rawData['hourly'];
        final daily = rawData['daily'];

        final int weatherCode = current['weather_code'];
        final bool isDay = current['is_day'] == 1;
        final conditionInfo = getWeatherConditionInfo(weatherCode, isDay);

        // Parse Hourly
        List<Map<String, dynamic>> parsedHourly = [];
        List<dynamic> hourlyTimes = hourly['time'];
        List<dynamic> hourlyTemps = hourly['temperature_2m'];
        List<dynamic> hourlyRainProb = hourly['precipitation_probability'];
        List<dynamic> hourlyCodes = hourly['weather_code'];

        int currentHourIndex = 0;
        DateTime now = DateTime.now();
        for (int i = 0; i < hourlyTimes.length; i++) {
          DateTime time = DateTime.parse(hourlyTimes[i]);
          if (time.isAfter(now) || time.hour == now.hour) {
            currentHourIndex = i;
            break;
          }
        }

        for (int i = currentHourIndex; i < currentHourIndex + 24 && i < hourlyTimes.length; i++) {
          DateTime t = DateTime.parse(hourlyTimes[i]);
          int code = hourlyCodes[i];
          parsedHourly.add({
            'time': '${t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour)} ${t.hour >= 12 ? 'PM' : 'AM'}',
            'temp': '${(hourlyTemps[i] as num).round()}°',
            'rainChance': '${hourlyRainProb[i]}%',
            'rainChanceValue': hourlyRainProb[i],
            'code': code,
          });
        }

        // Parse Daily
        List<Map<String, dynamic>> parsedDaily = [];
        List<dynamic> dailyDates = daily['time'];
        List<dynamic> maxTemps = daily['temperature_2m_max'];
        List<dynamic> minTemps = daily['temperature_2m_min'];
        List<dynamic> dailyCodes = daily['weather_code'];
        List<dynamic> dailyRainProb = daily['precipitation_probability_max'];

        List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (int i = 0; i < dailyDates.length && i < 7; i++) {
          DateTime d = DateTime.parse(dailyDates[i]);
          String dayLabel = (i == 0) ? 'Today' : weekdays[d.weekday - 1];
          parsedDaily.add({
            'day': dayLabel,
            'maxTemp': '${(maxTemps[i] as num).round()}°',
            'minTemp': '${(minTemps[i] as num).round()}°',
            'code': dailyCodes[i],
            'rainChance': '${dailyRainProb[i]}%',
          });
        }

        int maxUpcomingRainChance = 0;
        if (parsedHourly.isNotEmpty) {
          for (var h in parsedHourly.take(6)) {
            int chance = h['rainChanceValue'] ?? 0;
            if (chance > maxUpcomingRainChance) maxUpcomingRainChance = chance;
          }
        }

        final fullWeatherData = {
          'location': locationName.toUpperCase(),
          'state': stateName, // 🔥 Dynamic State & Country
          'temp': '${(current['temperature_2m'] as num).round()}°C',
          'feelsLike': '${(current['apparent_temperature'] as num).round()}°C',
          'condition': conditionInfo['title'],
          'description': conditionInfo['description'],
          'weatherCode': weatherCode,
          'isDay': isDay,
          'humidity': '${current['relative_humidity_2m']}%',
          'windSpeed': '${current['wind_speed_10m']} km/h',
          'pressure': '${(current['surface_pressure'] as num).round()} hPa',
          'maxTempToday': '${(maxTemps[0] as num).round()}°C',
          'minTempToday': '${(minTemps[0] as num).round()}°C',
          'uvIndex': '${(daily['uv_index_max'][0] as num).toStringAsFixed(1)}',
          'sunrise': _formatTimeISO(daily['sunrise'][0]),
          'sunset': _formatTimeISO(daily['sunset'][0]),
          'rainChanceToday': '${dailyRainProb[0]}%',
          'maxUpcomingRainChance': maxUpcomingRainChance,
          'hourly': parsedHourly,
          'daily': parsedDaily,
          'isOffline': false,
        };

        await _cacheWeatherData(fullWeatherData);
        return fullWeatherData;
      } else {
        return await _getOfflineWeather();
      }
    } catch (e) {
      developer.log('Network error fetching live forecast', error: e, name: 'Vanam.Weather');
      return await _getOfflineWeather();
    }
  }

  String _formatTimeISO(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      int hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      String minute = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
      String period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '--:--';
    }
  }

  Map<String, dynamic> getWeatherConditionInfo(int code, bool isDay) {
    if (code == 0) return {'title': isDay ? 'Clear Sky' : 'Clear Night', 'description': 'Optimal visibility'};
    if (code == 1 || code == 2 || code == 3) return {'title': 'Partly Cloudy', 'description': 'Scattered clouds'};
    if (code == 45 || code == 48) return {'title': 'Dense Fog', 'description': 'Reduced visibility'};
    if (code >= 51 && code <= 55) return {'title': 'Light Drizzle', 'description': 'Mild precipitation'};
    if (code >= 61 && code <= 65) return {'title': 'Heavy Rain', 'description': 'Wet conditions'};
    if (code >= 80 && code <= 82) return {'title': 'Rain Showers', 'description': 'Passing rain showers'};
    if (code >= 95) return {'title': 'Thunderstorm', 'description': 'Severe lightning & storm risk'};
    return {'title': 'Variable Climate', 'description': 'Unstable micro-climate'};
  }

  Future<void> _cacheWeatherData(Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox(_weatherBoxName);
      await box.put(_weatherDataKey, jsonEncode(data));
    } catch (e) {
      developer.log('Failed to cache weather data', error: e, name: 'Vanam.Weather');
    }
  }

  Future<Map<String, dynamic>> _getOfflineWeather() async {
    try {
      final box = await Hive.openBox(_weatherBoxName);
      final String? cachedJson = box.get(_weatherDataKey);

      if (cachedJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        decoded['isOffline'] = true;
        return decoded;
      }
    } catch (e) {
      developer.log('Failed to read cached weather', error: e, name: 'Vanam.Weather');
    }

    return {
      'location': 'LOCATION OFFLINE',
      'state': '--',
      'temp': '--',
      'feelsLike': '--',
      'condition': 'No Connection',
      'description': 'Connect once to load forecast',
      'weatherCode': -1,
      'isDay': true,
      'humidity': '--',
      'windSpeed': '--',
      'pressure': '--',
      'maxTempToday': '--',
      'minTempToday': '--',
      'uvIndex': '--',
      'sunrise': '--:--',
      'sunset': '--:--',
      'rainChanceToday': '0%',
      'maxUpcomingRainChance': 0,
      'hourly': [],
      'daily': [],
      'isOffline': true,
    };
  }
}
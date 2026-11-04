import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. THEME PROVIDER ---
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// --- 2. LANGUAGE PROVIDER (Auto-Detect Logic) ---
final languageProvider = StateProvider<String>((ref) {
  final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
  if (systemLocale == 'ta') {
    return 'ta';
  }
  return 'en'; // Default fallback
});

// --- 3. MASSIVE TRANSLATION ENGINE ---
class Tr {
  static final Map<String, Map<String, String>> _dictionary = {
    'en': {
      // General & Navigation
      'app_name': 'VANAM',
      'home': 'Home',
      'lens': 'Lens',
      'market': 'Market',
      'guide': 'Guide',
      'emergency': 'Emergency',
      'settings': 'Settings',
      'profile': 'Profile',
      'offline': 'OFFLINE',
      'online': 'ONLINE',
      'syncing': 'Syncing Sensors...',

      // Home Screen / Basecamp
      'basecamp_tools': 'BASECAMP TOOLS',
      'wild_lens': 'WILD LENS',
      'wild_lens_sub': 'AI Flora & Fauna Scanner',
      'eco_market': 'ECO MARKET',
      'eco_market_sub': 'Local Tribal Trade',
      'survival_kit': 'SURVIVAL KIT',
      'survival_kit_sub': 'Offline Medical Guides',
      'trail_map': 'TRAIL MAP',
      'trail_map_sub': 'GPS Routing & Radar',

      // Weather & Climate Radar
      'live_terrain': 'LIVE TERRAIN MAP',
      'expand': 'EXPAND',
      'satellite_view': 'SATELLITE VIEW',
      'full_forecast': 'FULL FORECAST',
      'feels_like': 'FEELS LIKE',
      'humidity': 'HUMIDITY',
      'wind_speed': 'WIND SPEED',
      'uv_index': 'UV INDEX',
      'sunrise': 'SUNRISE',
      'sunset': 'SUNSET',
      'rain_alert': 'RAIN ALERT',
      'storm_warning': 'STORM WARNING',
      'hourly_forecast': 'HOURLY FORECAST',
      '7_day_outlook': '7-DAY OUTLOOK',
      'live_radar': 'LIVE RADAR SCAN',

      // Maps & Terrain
      'geo_fence_warning': 'WARNING: Entering Restricted Zone',
      'safe_zone': 'Safe Zone',
      'danger_zone': 'Danger Zone',
      'retrace_steps': 'Retrace Steps',
      'ar_peak_finder': 'AR Peak Finder',
      'compass': 'Astro Compass',

      // SOS & Emergency
      'sos_title': 'Emergency SOS',
      'sos_desc': 'Do you need immediate assistance? This will share your live GPS location with forest rangers and local authorities.',
      'cancel': 'Cancel',
      'transmit_alert': 'Transmit Alert',
      'alert_sent': 'SOS Alert Sent. Help is on the way.',
      'alert_failed': 'Failed to send SOS. Check network.',
      'wildfire': 'Wildfire Detected',
      'animal_crossing': 'Wildlife Sighting',
      'medical_emergency': 'Medical Emergency',

      // Eco-Market & Tourism
      'apply_epass': 'Apply Forest E-Pass',
      'book_stay': 'Book Eco-Resorts',
      'hire_guide': 'Hire Local Guide',
      'buy_local': 'Buy Local Products',
      'eco_points': 'Eco Rewards',
      'tribal_honey': 'Wild Forest Honey',
      'handicrafts': 'Tribal Handicrafts',

      // Tools & AI
      'scan_pugmark': 'Scan Pugmark',
      'record_audio': 'Record Bird Sound',
      'walkie_talkie': 'Offline Walkie-Talkie',
      'night_mode': 'Night Vision Mode',
      'first_aid': 'First-Aid Guide',
    },

    // ==========================================================

    'ta': {
      // General & Navigation
      'app_name': 'வனம்',
      'home': 'முகப்பு',
      'lens': 'கேமரா',
      'market': 'சந்தை',
      'guide': 'வழிகாட்டி',
      'emergency': 'அவசரம்',
      'settings': 'அமைப்புகள்',
      'profile': 'சுயவிவரம்',
      'offline': 'ஆஃப்லைன்',
      'online': 'ஆன்லைன்',
      'syncing': 'தரவுகள் பெறப்படுகிறது...',

      // Home Screen / Basecamp
      'basecamp_tools': 'முகாம் கருவிகள்',
      'wild_lens': 'வன கேமரா',
      'wild_lens_sub': 'AI வனஉயிரின ஸ்கேனர்',
      'eco_market': 'சூழல் சந்தை',
      'eco_market_sub': 'பழங்குடியினர் வர்த்தகம்',
      'survival_kit': 'உயிர் காப்பான்',
      'survival_kit_sub': 'ஆஃப்லைன் மருத்துவ கையேடு',
      'trail_map': 'பாதை வரைபடம்',
      'trail_map_sub': 'GPS மற்றும் ரேடார்',

      // Weather & Climate Radar
      'live_terrain': 'நேரடி நிலப்பரப்பு',
      'expand': 'விரிவாக்கு',
      'satellite_view': 'செயற்கைக்கோள் பார்வை',
      'full_forecast': 'முழு வானிலை அறிக்கை',
      'feels_like': 'உணரும் வெப்பம்',
      'humidity': 'ஈரப்பதம்',
      'wind_speed': 'காற்றின் வேகம்',
      'uv_index': 'புறஊதா குறியீடு (UV)',
      'sunrise': 'சூரிய உதயம்',
      'sunset': 'சூரிய அஸ்தமனம்',
      'rain_alert': 'மழை எச்சரிக்கை',
      'storm_warning': 'புயல் எச்சரிக்கை',
      'hourly_forecast': 'மணிநேர அறிக்கை',
      '7_day_outlook': '7 நாள் முன்னறிவிப்பு',
      'live_radar': 'நேரடி ரேடார்',

      // Maps & Terrain
      'geo_fence_warning': 'எச்சரிக்கை: தடைசெய்யப்பட்ட பகுதி',
      'safe_zone': 'பாதுகாப்பான பகுதி',
      'danger_zone': 'ஆபத்தான பகுதி',
      'retrace_steps': 'வந்த வழி திரும்பு',
      'ar_peak_finder': 'AR மலை தேடி',
      'compass': 'திசைகாட்டி',

      // SOS & Emergency
      'sos_title': 'அவசரகால உதவி (SOS)',
      'sos_desc': 'உங்களுக்கு உடனடி உதவி தேவையா? உங்கள் நேரடி இருப்பிடம் வனத்துறையினருக்கு பகிரப்படும்.',
      'cancel': 'ரத்து செய்',
      'transmit_alert': 'உதவிக்கு அழை',
      'alert_sent': 'அலார்ட் அனுப்பப்பட்டது. உதவி வருகிறது.',
      'alert_failed': 'அனுப்ப முடியவில்லை. நெட்வொர்க்கை சரிபார்க்கவும்.',
      'wildfire': 'காட்டுத் தீ எச்சரிக்கை',
      'animal_crossing': 'வனவிலங்கு நடமாட்டம்',
      'medical_emergency': 'மருத்துவ அவசரம்',

      // Eco-Market & Tourism
      'apply_epass': 'இ-பாஸ் (E-Pass) விண்ணப்பிக்க',
      'book_stay': 'வன தங்கும் விடுதிகள்',
      'hire_guide': 'வழிகாட்டியை முன்பதிவு செய்',
      'buy_local': 'உள்ளூர் பொருட்களை வாங்கு',
      'eco_points': 'சூழல் புள்ளிகள் (Eco Points)',
      'tribal_honey': 'மலைத்தேன்',
      'handicrafts': 'கைவினைப்பொருட்கள்',

      // Tools & AI
      'scan_pugmark': 'கால்தடத்தை ஸ்கேன் செய்',
      'record_audio': 'பறவை ஒலியை பதிவு செய்',
      'walkie_talkie': 'ஆஃப்லைன் வாக்கி-டாக்கி',
      'night_mode': 'இரவு பார்வை முறை',
      'first_aid': 'முதலுதவி கையேடு',
    }
  };

  // Helper method to get the translated word
  static String get(String key, String langCode) {
    return _dictionary[langCode]?[key] ?? key; // Fallback to key if not found
  }
}
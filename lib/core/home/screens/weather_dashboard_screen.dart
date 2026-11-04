import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// 🔥 Connects to the Interactive Windy Map Screen
import '../../../features/offline_map/screens/windy_map_screen.dart';

class WeatherDashboardScreen extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final bool isLoading;
  final VoidCallback onRefresh;
  final double currentLat;
  final double currentLng;

  const WeatherDashboardScreen({
    super.key,
    required this.weatherData,
    required this.isLoading,
    required this.onRefresh,
    required this.currentLat,
    required this.currentLng,
  });

  // 🔥 PUT YOUR OPENWEATHER API KEY HERE FOR THE REAL RADAR TILES 🔥
  static const String _weatherApiKey = 'YOUR_API_KEY_HERE';

  static const _bg = Color(0xFF07110D);
  static const _surface = Color(0xFF0D1B15);
  static const _line = Color(0x22FFFFFF);
  static const _green = Color(0xFF9BE15D);
  static const _muted = Color(0xFF91A39A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _green,
        backgroundColor: _surface,
        onRefresh: () async {
          onRefresh();
          await Future.delayed(const Duration(milliseconds: 700));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: isLoading
                  ? const SizedBox(
                height: 520,
                child: Center(
                  child: CircularProgressIndicator(color: _green),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationHeader(),
                    const SizedBox(height: 18),
                    _buildWeatherHero(),
                    const SizedBox(height: 14),
                    _buildRiskStrip(),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'FORECAST',
                      'Next 12 hours',
                      Icons.schedule_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildHourlyForecast(),
                    const SizedBox(height: 30),
                    _buildSectionHeader(
                      'LIVE ENVIRONMENT',
                      'Precipitation radar',
                      Icons.radar_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildRadarCard(context), // 🔥 Fixed dummy data here!
                    const SizedBox(height: 30),
                    _buildSectionHeader(
                      'CLIMATE',
                      'Current conditions',
                      Icons.eco_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildClimateGrid(),
                    const SizedBox(height: 30),
                    _buildSectionHeader(
                      'OUTLOOK',
                      'Next 7 days',
                      Icons.calendar_month_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildWeeklyForecast(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: _bg.withValues(alpha: .94),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 72,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18, top: 10, bottom: 10),
        child: _roundButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
      ),
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: _green.withValues(alpha: .25)),
            ),
            child: const Icon(Icons.eco_rounded, color: _green, size: 16),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VANAM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              Text(
                'ENVIRONMENT INTELLIGENCE',
                style: TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 10, bottom: 10),
          child: _roundButton(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationHeader() {
    final location = weatherData?['location']?.toString() ?? 'Current location';

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: .18)),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: _green,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE LOCATION',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2419),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _green.withValues(alpha: .18)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location_rounded, color: _green, size: 13),
              SizedBox(width: 5),
              Text(
                'GPS',
                style: TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherHero() {
    final temp = weatherData?['temp']?.toString() ?? '--';
    final condition = weatherData?['condition']?.toString() ?? 'Syncing...';
    final description =
        weatherData?['description']?.toString() ??
            'Fetching live micro-climate';
    final high = weatherData?['maxTempToday']?.toString() ?? '--';
    final low = weatherData?['minTempToday']?.toString() ?? '--';
    final rain = weatherData?['rainChanceToday']?.toString() ?? '0%';
    final code = _weatherCode();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF193A29),
            Color(0xFF10261B),
            Color(0xFF0B1711),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F7D4C).withValues(alpha: .13),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _green.withValues(alpha: .14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              temp,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 70,
                                height: .9,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -4,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8, left: 4),
                              child: Text(
                                '°C',
                                style: TextStyle(
                                  color: _green,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                    ),
                    child: Icon(
                      _getWeatherIcon(code),
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: .06)),
                ),
                child: Row(
                  children: [
                    _miniStat(Icons.arrow_upward_rounded, 'High', '$high°'),
                    _divider(),
                    _miniStat(Icons.arrow_downward_rounded, 'Low', '$low°'),
                    _divider(),
                    _miniStat(
                      Icons.water_drop_rounded,
                      'Rain',
                      rain,
                      iconColor: const Color(0xFF73C8FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStrip() {
    final rain = _toInt(weatherData?['maxUpcomingRainChance']);
    final fireRisk = rain >= 70 ? 'MODERATE' : 'LOW';
    final floodRisk = rain >= 80 ? 'HIGH' : (rain >= 45 ? 'MODERATE' : 'LOW');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _riskItem(
              Icons.local_fire_department_rounded,
              'FIRE RISK',
              fireRisk,
              fireRisk == 'LOW' ? _green : const Color(0xFFFFB74D),
            ),
          ),
          Container(width: 1, height: 34, color: _line),
          Expanded(
            child: _riskItem(
              Icons.water_rounded,
              'FLOOD RISK',
              floodRisk,
              floodRisk == 'LOW'
                  ? _green
                  : (floodRisk == 'HIGH'
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFFFFC857)),
            ),
          ),
          Container(width: 1, height: 34, color: _line),
          Expanded(
            child: _riskItem(
              Icons.visibility_rounded,
              'VISIBILITY',
              '${weatherData?['visibility'] ?? '--'}',
              const Color(0xFF7BC8FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String eyebrow, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 17),
        const SizedBox(width: 8),
        Text(
          eyebrow,
          style: const TextStyle(
            color: _green,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    final hourly = List<dynamic>.from(weatherData?['hourly'] ?? []);
    if (hourly.isEmpty) {
      return _emptyState('Hourly forecast unavailable');
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hourly.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final item = hourly[index];
          final isFirst = index == 0;

          return Container(
            width: 82,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            decoration: BoxDecoration(
              color: isFirst ? const Color(0xFF193A29) : _surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isFirst ? _green.withValues(alpha: .28) : _line,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['time']?.toString() ?? '--',
                  style: TextStyle(
                    color: isFirst ? _green : _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  _getWeatherIcon(_toInt(item['code'])),
                  color: Colors.white,
                  size: 25,
                ),
                Text(
                  item['temp']?.toString() ?? '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF72C7FF),
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item['rainChance']?.toString() ?? '--',
                      style: const TextStyle(
                        color: Color(0xFF72C7FF),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 100% REAL LIVE RADAR TILES (NO DUMMY CIRCLES) 🔥
  Widget _buildRadarCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WindyMapScreen(
              initialLat: currentLat,
              initialLng: currentLng,
            ),
          ),
        );
      },
      child: Container(
        height: 275,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .09)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(currentLat, currentLng),
                  initialZoom: 10,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // Map preview is locked
                  ),
                ),
                children: [
                  // Base Dark Map
                  TileLayer(
                    urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    userAgentPackageName: 'com.enterprise.vanam',
                  ),

                  // 🔥 REAL WEATHER PRECIPITATION TILE LAYER 🔥
                  TileLayer(
                    urlTemplate: 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$_weatherApiKey',
                    backgroundColor: Colors.transparent,
                    userAgentPackageName: 'com.enterprise.vanam',
                  ),

                  // Current Location Pin
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(currentLat, currentLng),
                        width: 34,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _green.withValues(alpha: .7),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Fade Gradient Overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: _mapBadge(
                  Icons.radar_rounded,
                  'LIVE PRECIPITATION',
                  const Color(0xFF72C7FF),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: .08)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _LegendDot(
                        color: Color(0xFF45B8FF),
                        text: 'Light rain',
                      ),
                      SizedBox(height: 6),
                      _LegendDot(
                        color: Color(0xFF8C6BFF),
                        text: 'Heavy rain',
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text(
                          'TAP TO OPEN INTERACTIVE MAP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClimateGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _buildMetricTile(
          'FEELS LIKE',
          weatherData?['feelsLike']?.toString() ?? '--',
          Icons.thermostat_rounded,
          const Color(0xFFFFA55C),
        ),
        _buildMetricTile(
          'HUMIDITY',
          weatherData?['humidity']?.toString() ?? '--',
          Icons.water_drop_rounded,
          const Color(0xFF63C8FF),
        ),
        _buildMetricTile(
          'WIND',
          weatherData?['windSpeed']?.toString() ?? '--',
          Icons.air_rounded,
          const Color(0xFF7EE7C1),
        ),
        _buildMetricTile(
          'UV INDEX',
          weatherData?['uvIndex']?.toString() ?? '--',
          Icons.wb_sunny_outlined,
          const Color(0xFFFFCF66),
        ),
        _buildMetricTile(
          'SUNRISE',
          weatherData?['sunrise']?.toString() ?? '--:--',
          Icons.wb_twilight_rounded,
          const Color(0xFFFF9C72),
        ),
        _buildMetricTile(
          'SUNSET',
          weatherData?['sunset']?.toString() ?? '--:--',
          Icons.nights_stay_rounded,
          const Color(0xFFB79BFF),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: .14)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyForecast() {
    final daily = List<dynamic>.from(weatherData?['daily'] ?? []);
    if (daily.isEmpty) {
      return _emptyState('7-day outlook unavailable');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: List.generate(daily.length, (index) {
          final item = daily[index];
          final last = index == daily.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(
                bottom: BorderSide(color: _line),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    item['day']?.toString().toUpperCase() ?? '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .045),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getWeatherIcon(_toInt(item['code'])),
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF72C7FF),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['rainChance']?.toString() ?? '--',
                        style: const TextStyle(
                          color: Color(0xFF72C7FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item['maxTemp'] ?? '--'}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${item['minTemp'] ?? '--'}°',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _riskItem(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: _muted,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      IconData icon,
      String label,
      String value, {
        Color iconColor = Colors.white70,
      }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _line,
    );
  }

  Widget _mapBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: _muted, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _weatherCode() => _toInt(weatherData?['weatherCode']);

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.water_drop_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.grain_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_rounded;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
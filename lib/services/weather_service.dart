import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final String locationName;
  final List<double> hourlyTemperatures; // 24 values for 0:00 to 23:00
  final List<int> hourlyHumidity; // 24 values

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.locationName,
    this.hourlyTemperatures = const [],
    this.hourlyHumidity = const [],
  });

  String get condition {
    // WMO Weather interpretation codes
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 57) return 'Drizzle';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 82) return 'Rain Showers';
    if (weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 57) return '🌦️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode <= 86) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '🌡️';
  }

  bool get isHeatStress => temperature >= 30;
  
  String get heatStressLevel {
    if (temperature >= 40) return 'SEVERE';
    if (temperature >= 35) return 'HIGH';
    if (temperature >= 30) return 'MODERATE';
    return 'NORMAL';
  }
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final int precipProbability;
  final double windSpeedMax;
  final String? modelName;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.precipProbability,
    required this.windSpeedMax,
    this.modelName,
  });

  String get condition {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode <= 3) return 'Cloudy';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 57) return 'Drizzle';
    if (weatherCode <= 67) return 'Rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Showers';
    if (weatherCode >= 95) return 'Storm';
    return 'Unknown';
  }

  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 57) return '🌦️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode >= 95) return '⛈️';
    return '🌡️';
  }

  bool get isHeatStress => maxTemp >= 30;
}

class GeoLocation {
  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;

  GeoLocation({
    required this.name,
    required this.country,
    this.admin1,
    required this.latitude,
    required this.longitude,
  });

  String get displayName => admin1 != null ? '$name, $admin1, $country' : '$name, $country';

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      admin1: json['admin1'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class WeatherService {
  static const String _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  static const double _defaultLat = 11.165168;
  static const double _defaultLon = 78.055107;
  static const String _defaultLocationName = 'Paramathi Velur, Namakkal';

  Future<void> saveLocation(String name, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_location_name', name);
    await prefs.setDouble('weather_lat', lat);
    await prefs.setDouble('weather_lon', lon);
  }

  Future<Map<String, dynamic>> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('weather_location_name') ?? _defaultLocationName,
      'lat': prefs.getDouble('weather_lat') ?? _defaultLat,
      'lon': prefs.getDouble('weather_lon') ?? _defaultLon,
    };
  }

  Future<WeatherData?> getCurrentWeather() async {
    try {
      final location = await getSavedLocation();
      final lat = location['lat'] as double;
      final lon = location['lon'] as double;
      final locationName = location['name'] as String;

      final url = Uri.parse(
        '$_weatherBaseUrl?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,relative_humidity_2m&forecast_days=1'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'];
        final currentHour = DateTime.now().hour;

        final hourlyTempRaw = data['hourly']?['temperature_2m'] as List?;
        final hourlyHumRaw = data['hourly']?['relative_humidity_2m'] as List?;

        final hourlyTemps = hourlyTempRaw != null
            ? hourlyTempRaw.map((v) => (v as num).toDouble()).toList()
            : <double>[];
        final hourlyHum = hourlyHumRaw != null
            ? hourlyHumRaw.map((v) => (v as num).toInt()).toList()
            : <int>[];

        final humidity = hourlyHum.isNotEmpty && hourlyHum.length > currentHour
            ? hourlyHum[currentHour]
            : 0;

        return WeatherData(
          temperature: (current['temperature'] as num).toDouble(),
          weatherCode: (current['weathercode'] as num).toInt(),
          windSpeed: (current['windspeed'] as num).toDouble(),
          humidity: humidity,
          locationName: locationName,
          hourlyTemperatures: hourlyTemps,
          hourlyHumidity: hourlyHum,
        );
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Fetch 16-day daily forecast from a specific model
  Future<List<DailyForecast>> getDailyForecast({String? model, int days = 16}) async {
    try {
      final location = await getSavedLocation();
      final lat = location['lat'] as double;
      final lon = location['lon'] as double;

      String urlStr = '$_weatherBaseUrl?latitude=$lat&longitude=$lon'
          '&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,wind_speed_10m_max'
          '&forecast_days=$days&timezone=auto';
      if (model != null) {
        urlStr += '&models=$model';
      }

      final response = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        if (daily == null) return [];

        final dates = (daily['time'] as List).map((d) => DateTime.parse(d)).toList();
        final maxTemps = (daily['temperature_2m_max'] as List).map((v) => (v as num?)?.toDouble() ?? 0.0).toList();
        final minTemps = (daily['temperature_2m_min'] as List).map((v) => (v as num?)?.toDouble() ?? 0.0).toList();
        final codes = (daily['weather_code'] as List).map((v) => (v as num?)?.toInt() ?? 0).toList();
        final precip = daily['precipitation_probability_max'] != null
            ? (daily['precipitation_probability_max'] as List).map((v) => (v as num?)?.toInt() ?? 0).toList()
            : List.filled(dates.length, 0);
        final wind = daily['wind_speed_10m_max'] != null
            ? (daily['wind_speed_10m_max'] as List).map((v) => (v as num?)?.toDouble() ?? 0.0).toList()
            : List.filled(dates.length, 0.0);

        return List.generate(dates.length, (i) => DailyForecast(
          date: dates[i],
          maxTemp: maxTemps[i],
          minTemp: minTemps[i],
          weatherCode: codes[i],
          precipProbability: precip[i],
          windSpeedMax: wind[i],
          modelName: model ?? 'best_match',
        ));
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }

  /// Fetch forecasts from multiple models for comparison
  Future<Map<String, List<DailyForecast>>> getMultiModelForecast() async {
    final results = <String, List<DailyForecast>>{};

    // Fetch from 3 Open-Meteo models + OpenWeatherMap in parallel
    final futures = await Future.wait([
      getDailyForecast(model: null, days: 16),
      getDailyForecast(model: 'gfs_seamless', days: 16),
      getDailyForecast(model: 'ecmwf_ifs04', days: 10),
      _getOpenWeatherMapForecast(),
    ]);

    results['Best Match'] = futures[0];
    results['GFS (US/NOAA)'] = futures[1];
    results['ECMWF (Europe)'] = futures[2];
    if ((futures[3] as List).isNotEmpty) {
      results['OpenWeather'] = futures[3];
    }

    return results;
  }

  /// Fetch 5-day forecast from OpenWeatherMap (free tier)
  static const String _owmApiKey = '935c409991f171fd72459d2da354dce7';

  Future<List<DailyForecast>> _getOpenWeatherMapForecast() async {
    try {
      final location = await getSavedLocation();
      final lat = location['lat'] as double;
      final lon = location['lon'] as double;

      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_owmApiKey&units=metric'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List;

        // OWM returns 3-hour intervals; aggregate to daily
        Map<String, List<Map<String, dynamic>>> dailyGroups = {};
        for (var item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          dailyGroups.putIfAbsent(dayKey, () => []);
          dailyGroups[dayKey]!.add(item);
        }

        return dailyGroups.entries.map((entry) {
          final items = entry.value;
          final temps = items.map((i) => (i['main']['temp'] as num).toDouble()).toList();
          final maxT = temps.reduce((a, b) => a > b ? a : b);
          final minT = temps.reduce((a, b) => a < b ? a : b);
          // Use the weather code from the middle of the day
          final midItem = items[items.length ~/ 2];
          final owmId = midItem['weather'][0]['id'] as int;
          // Map OWM weather ID to WMO code (approximate)
          int wmoCode = 0;
          if (owmId >= 200 && owmId < 300) wmoCode = 95; // Thunderstorm
          else if (owmId >= 300 && owmId < 400) wmoCode = 53; // Drizzle
          else if (owmId >= 500 && owmId < 600) wmoCode = 63; // Rain
          else if (owmId >= 600 && owmId < 700) wmoCode = 73; // Snow
          else if (owmId >= 700 && owmId < 800) wmoCode = 45; // Fog
          else if (owmId == 800) wmoCode = 0; // Clear
          else if (owmId > 800) wmoCode = 2; // Cloudy

          final windSpeeds = items.map((i) => (i['wind']?['speed'] as num?)?.toDouble() ?? 0.0).toList();

          return DailyForecast(
            date: DateTime.parse(entry.key),
            maxTemp: maxT,
            minTemp: minT,
            weatherCode: wmoCode,
            precipProbability: ((midItem['pop'] as num?)?.toDouble() ?? 0.0 * 100).toInt(),
            windSpeedMax: windSpeeds.reduce((a, b) => a > b ? a : b) * 3.6, // m/s to km/h
            modelName: 'openweathermap',
          );
        }).toList();
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }

  Future<List<GeoLocation>> searchLocations(String query) async {
    if (query.length < 2) return [];
    try {
      final url = Uri.parse('$_geocodingBaseUrl?name=$query&count=8&language=en');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results == null) return [];
        return results.map((r) => GeoLocation.fromJson(r)).toList();
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }
}


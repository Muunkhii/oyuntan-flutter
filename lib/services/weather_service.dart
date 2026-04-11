// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherResult {
  final double temp;
  final String condition;
  final String emoji;
  WeatherResult({required this.temp, required this.condition, required this.emoji});
}

class WeatherService {
  // Open-Meteo — API key шаардахгүй, CORS дэмжигддэг
  static const _url =
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=47.9077&longitude=106.8832'
      '&current=temperature_2m,weathercode'
      '&timezone=Asia%2FUlaanbaatar';

  Future<WeatherResult?> fetchUlaanbaatar() async {
    try {
      final res = await http.get(Uri.parse(_url))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final cur  = json['current'] as Map<String, dynamic>;
      final temp = (cur['temperature_2m'] as num).toDouble();
      final code = (cur['weathercode']  as num).toInt();
      return WeatherResult(
        temp:      temp,
        condition: _condition(code),
        emoji:     _emoji(code),
      );
    } catch (_) {
      return null;
    }
  }

  String _condition(int code) {
    if (code == 0)                      return 'Цэлмэг';
    if (code <= 3)                      return 'Бага үүлтэй';
    if (code <= 48)                     return 'Манантай';
    if (code <= 67)                     return 'Бороотой';
    if (code <= 77)                     return 'Цастай';
    if (code <= 82)                     return 'Шаваар бороо';
    return 'Аянгатай';
  }

  String _emoji(int code) {
    if (code == 0)  return '☀️';
    if (code <= 3)  return '⛅';
    if (code <= 48) return '🌫️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '🌨️';
    if (code <= 82) return '🌧️';
    return '⛈️';
  }
}

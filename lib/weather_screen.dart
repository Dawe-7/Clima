import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:clima/theme_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

const Color primaryTextColor = Color(0xFF212121); // Dark gray
const Color secondaryTextColor = Color(0xFF757575); // Medium gray
const Color cardBackgroundColor = Colors.white;
const Color backgroundColor = Color(0xFFF5F5F5); // Light gray

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String cityName = 'Nairobi';
  String temperature = 'Loading...';
  String condition = 'Loading...';
  String windSpeed = 'Loading...';
  String humidity = 'Loading...';
  String feelsLike = 'Loading...';
  bool isLoading = true;
  String errorMessage = '';
  String sunriseTime = 'Loading...';
  String sunsetTime = 'Loading...';
  String weatherIcon = '☀️';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage =
          'Location permissions are denied. Please enable in settings.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage =
        'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      fetchWeatherDataByLocation(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        errorMessage = 'Error getting location: $e';
      });
    }
  }

  Future<void> fetchWeatherData() async {
    await _fetchWeatherData(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName');
  }

  Future<void> fetchWeatherDataByLocation(
      double latitude, double longitude) async {
    await _fetchWeatherData(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude');
  }

  Future<void> _fetchWeatherData(String baseUrl) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final apiKey = '811bbee77b5b81339fda22e8d6f7f1ad';
    final apiUrl = '$baseUrl&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          temperature = data['main']['temp'].toString();
          condition = data['weather'][0]['description'];
          windSpeed = data['wind']['speed'].toString();
          humidity = data['main']['humidity'].toString();
          feelsLike = data['main']['feels_like'].toString();
          isLoading = false;

          sunriseTime = DateFormat('h:mm a').format(
              DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000,
                  isUtc: false)
                  .toLocal());
          sunsetTime = DateFormat('h:mm a').format(
              DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000,
                  isUtc: false)
                  .toLocal());

          weatherIcon = getWeatherIcon(data['weather'][0]['icon']);
        });
      } else {
        setState(() {
          errorMessage =
          'Failed to load weather data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  String getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return '☀️';
      case '01n':
        return '🌙';
      case '02d':
      case '03d':
      case '04d':
        return '🌤️';
      case '02n':
      case '03n':
      case '04n':
        return '☁️';
      case '09d':
      case '10d':
        return '🌧️';
      case '09n':
      case '10n':
        return '☔';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor, // Subtle background color
          borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40)), // Rounded bottom corners
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Weather",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          themeManager.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: primaryTextColor,
                        ),
                        onPressed: () {
                          themeManager.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter city name',
                    hintStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    filled: true,
                    fillColor: cardBackgroundColor.withOpacity(0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.search, color: primaryTextColor),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      cityName = value;
                    });
                    fetchWeatherData();
                  },
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center, // Keep this
                            children: [
                              Text(
                                cityName,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                condition,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                weatherIcon,
                                style: const TextStyle(
                                  fontSize: 60,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '$temperature°C',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Feels like: $feelsLike°C',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sunrise: $sunriseTime, Sunset: $sunsetTime',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildWeatherDetail(
                                      'Wind Speed', '$windSpeed m/s', Icons.air),
                                  _buildWeatherDetail(
                                      'Humidity', '$humidity%', Icons.water_drop),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Hourly Forecast',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _buildHourlyForecastCard('10 AM', '🌤️ 28°C'),
                                  ),
                                  Expanded(
                                    child: _buildHourlyForecastCard('1 PM', '🌞 30°C'),
                                  ),
                                  Expanded(
                                    child: _buildHourlyForecastCard('4 PM', '🌥️ 26°C'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: primaryTextColor,
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastCard(String time, String forecast) {
    return Card(
      elevation: 2,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              forecast,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

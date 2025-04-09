import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clima/theme_manager.dart';
import 'package:clima/weather_screen.dart';

const Color primaryTextColor = Color(0xFF212121); // Dark gray

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeManager(),
      child: const ClimaApp(),
    ),
  );
}

class ClimaApp extends StatelessWidget {
  const ClimaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Clima',
          theme: ThemeData(
              colorSchemeSeed: const Color(0xff6750a4),
              useMaterial3: true,
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: primaryTextColor),
              )),
          darkTheme: ThemeData(
              colorSchemeSeed: const Color(0xff6750a4),
              useMaterial3: true,
              brightness: Brightness.dark,
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
              )),
          themeMode: themeManager.themeMode,
          home: const WeatherScreen(),
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox Maps Flutter does NOT support web
  if (!kIsWeb) {
    MapboxOptions.setAccessToken(ApiConfig.mapboxToken);
  }

  runApp(const IniatoApp());
}

class IniatoApp extends StatelessWidget {
  const IniatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iniato',
      debugShowCheckedModeBanner: false,
      theme: IniatoTheme.themeData,
      // home: kIsWeb
      //     ? const Scaffold(
      //         body: Center(
      //           child: Text(
      //             'Please run on Android or iOS',
      //             style: TextStyle(fontSize: 18),
      //           ),
      //         ),
      //       )
      //     : const SplashScreen(),
      home: const SplashScreen(),
    );
  }
}
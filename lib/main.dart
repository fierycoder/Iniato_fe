import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  // Initialize Mapbox before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // For version 2.3.0+, use MapboxOptions

  runApp(const IniatoApp());
}


Future<void> setup() async{
  await dotenv.load(
    fileName: ".env"
  );


  MapboxOptions.setAccessToken("pk.eyJ1IjoiaW10aWZheiIsImEiOiJjbWprN3U3bGUwMTJ1M2twZ2s3bG45MWFpIn0.hNw5ey_P0O2t2VPMw-Ss2A");
}
class IniatoApp extends StatelessWidget {
  const IniatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    MapboxOptions.setAccessToken("pk.eyJ1IjoiaW10aWZheiIsImEiOiJjbWprN3U3bGUwMTJ1M2twZ2s3bG45MWFpIn0.hNw5ey_P0O2t2VPMw-Ss2A");

    return MaterialApp(
      title: 'Iniato',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
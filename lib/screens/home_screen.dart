import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
MapboxMap? mapBoxMapController;

StreamSubscription? userPositionStream;

@override
  void initState() {
    super.initState();
    _setupPositionTracking();
  }


  @override
  void dispose() {
  userPositionStream?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:MapWidget(onMapCreated: _onMapCreated,),
    );
  }


  void _onMapCreated(MapboxMap controller,){
    setState(() {
      mapBoxMapController = controller;
    });
    mapBoxMapController?.location.updateSettings(LocationComponentSettings(

      enabled: true,
      pulsingEnabled: true,
    ),);
  }

  Future<void> _setupPositionTracking() async{
      bool serviceEnabled;
      gl.LocationPermission permission;

      serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();

      if(!serviceEnabled)
        {
          return Future.error('Location Services are disabled');
        }

      permission = await gl.Geolocator.checkPermission();
      if(permission == gl.LocationPermission.denied)
        {
          permission = await gl.Geolocator.requestPermission();

          if(permission == gl.LocationPermission.denied)
          {
            return Future.error('Location Services are disabled');
          }
        }

      if(permission == gl.LocationPermission.deniedForever){
        return Future.error('Location Services are permanently denied, we cannot request permission');

      }

      gl.LocationSettings locationSettings = gl.LocationSettings(accuracy: gl.LocationAccuracy.high,distanceFilter:100,);
      userPositionStream?.cancel();
      userPositionStream = gl.Geolocator.getPositionStream(locationSettings: locationSettings).listen
        (
            (gl.Position? position,)

        {
          if(position!=null)
            {
              print(position,);
            }

        },);

  }

}

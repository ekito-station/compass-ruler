import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:compass_ruler/map_page.dart';

Position myPosition = Position(
  // 初期座標（渋谷駅）
  latitude: 35.658199,
  longitude: 139.701625,
  timestamp: DateTime.now(),
  altitude: 0,
  accuracy: 0,
  heading: 0,
  speed: 0,
  speedAccuracy: 0,
  floor: null,
);

class CompassPage extends StatefulWidget {
  const CompassPage({Key? key}) : super(key: key);

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  late StreamSubscription<Position> positionStream;
  late double? direction;
  late double markerBearing;
  double bearingTolerance = 5.0;
  String distance = '';

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  double calcMarkerBearing(Position myPosition, LatLng markerPosition) {
    double myLat = myPosition.latitude;
    double myLng = myPosition.longitude;
    double markerLat = markerPosition.latitude;
    double markerLng = markerPosition.longitude;
    double bearing =
        Geolocator.bearingBetween(myLat, myLng, markerLat, markerLng);
    if (bearing < 0.0) {
      bearing += 360.0;
    }
    return bearing;
  }

  void calcMarkerDistance(Position myPosition, LatLng markerPosition) {
    double myLat = myPosition.latitude;
    double myLng = myPosition.longitude;
    double markerLat = markerPosition.latitude;
    double markerLng = markerPosition.longitude;
    double distanceInMeters =
        Geolocator.distanceBetween(myLat, myLng, markerLat, markerLng);
    distance = distanceInMeters.round().toString();
  }

  String displayPlaceDistance() {
    calcMarkerDistance(myPosition, markerPosition);
    return '$distance m';
  }

  bool checkTolerance(double compassAngle, double bearing) {
    if ((compassAngle - bearing).abs() < bearingTolerance) {
      return true;
    } else if ((compassAngle - bearing).abs() > 360 - bearingTolerance) {
      return true;
    } else {
      return false;
    }
  }

  _helpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to use"),
        content: Container(
          width: 120,
          height: 400,
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text("* Please turn on location services."),
                const SizedBox(height: 10),
                const Text(
                    "1. Long-press a point on the map to place a marker there."),
                const SizedBox(height: 10),
                Container(
                  height: 300,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset('assets/screenshot1.png'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("2. Move to the next page."),
                const SizedBox(height: 10),
                const Text(
                    "3. Turn to the direction of the marker and the distance to the marker will be displayed."),
                const SizedBox(height: 10),
                Container(
                  height: 300,
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset('assets/screenshot2.png'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      myPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compass Ruler'),
      ),
      body: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error reading heading: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            direction = snapshot.data?.heading;
            markerBearing = calcMarkerBearing(myPosition, markerPosition);
            if (direction == null) {
              return const Center(
                child: Text("Device does not have sensors."),
              );
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.expand_less,
                    size: 100,
                  ),
                  // const SizedBox(height: 10),
                  Opacity(
                      opacity:
                          checkTolerance(direction!, markerBearing) ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          Text(displayPlaceDistance(),
                              style: const TextStyle(fontSize: 45)),
                          const SizedBox(height: 10),
                          const Text("from ther marker",
                              style: TextStyle(fontSize: 30)),
                        ],
                      )),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _helpDialog,
        child: const Icon(Icons.help_outline),
      ),
    );
  }
}

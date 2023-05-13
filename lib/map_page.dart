import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:compass_ruler/compass_page.dart';

LatLng markerPosition = const LatLng(35.689702, 139.700560); // 初期座標（新宿駅）

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer _controller = Completer();

  late LatLng _initialPosition;
  late bool _loading;

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
    _loading = true;
    _getUserLocation();
    WidgetsBinding.instance!.addPostFrameCallback(
        (_) => Future.delayed(const Duration(milliseconds: 1000), () {
              _helpDialog();
            }));
  }

  void _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _loading = false;
    });
  }

  Set<Marker> createMarker() {
    return {
      Marker(
        markerId: const MarkerId("marker_1"),
        position: markerPosition,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Compass Ruler'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompassPage(),
                    ))
              },
            )
          ]),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              compassEnabled: false,
              myLocationEnabled: true,
              mapType: MapType.normal,
              markers: createMarker(),
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14.4746,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onLongPress: (LatLng latLng) {
                setState(() {
                  markerPosition = latLng;
                });
              }),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _helpDialog,
        child: const Icon(Icons.help_outline),
      ),
    );
  }
}

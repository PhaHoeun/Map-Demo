import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_widget/google_maps_widget.dart';
import 'package:google_maps_widget/src/models/direction.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  final mapsWidgetController = GlobalKey<GoogleMapsWidgetState>();
  final _driverCoordinatesController = StreamController<LatLng>();

  static const _restaurantLocation = LatLng(
    40.48017307700204,
    -3.3618026599287987,
  );
  static const _houseLocation = LatLng(40.484000837597925, -3.369978368282318);

  @override
  void initState() {
    super.initState();
    _startDriverAlongRoute();
  }

  @override
  void dispose() {
    _driverCoordinatesController.close();
    super.dispose();
  }

  Future<void> _startDriverAlongRoute() async {
    try {
      final route = await Direction.getDirections(
        googleMapsApiKey: "AIzaSyDQWTMw8fk7Pd-g61XP-js6qdsfwsqiaSA",
        origin: _restaurantLocation,
        destination: _houseLocation,
      );

      if (route == null || route.polylinePoints.isEmpty) {
        debugPrint(
          'Route fetch failed or returned no points; using fallback direct path.',
        );
        _emitFallbackPath();
        return;
      }

      debugPrint('Route fetched with ${route.polylinePoints.length} points.');
      for (final point in route.polylinePoints) {
        if (_driverCoordinatesController.isClosed) break;
        _driverCoordinatesController.add(point);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (error) {
      debugPrint('Route fetch error: $error');
      _emitFallbackPath();
    }
  }

  Future<void> _emitFallbackPath() async {
    const totalSteps = 80;
    for (var i = 0; i <= totalSteps; i++) {
      if (_driverCoordinatesController.isClosed) break;
      final t = i / totalSteps;
      _driverCoordinatesController.add(
        LatLng(
          _restaurantLocation.latitude +
              (_houseLocation.latitude - _restaurantLocation.latitude) * t,
          _restaurantLocation.longitude +
              (_houseLocation.longitude - _restaurantLocation.longitude) * t,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Map Widget')),
      body: GoogleMapsWidget(
        apiKey: "AIzaSyDQWTMw8fk7Pd-g61XP-js6qdsfwsqiaSA",
        key: mapsWidgetController,
        sourceLatLng: _restaurantLocation,
        destinationLatLng: _houseLocation,

        ///////////////////////////////////////////////////////
        //////////////    OPTIONAL PARAMETERS    //////////////
        ///////////////////////////////////////////////////////
        routeWidth: 2,
        sourceMarkerIconInfo: MarkerIconInfo(
          infoWindowTitle: "Restaurant",
          assetPath: "assets/icon/restaurant.png",
          assetMarkerSize: Size.square(48),
        ),
        destinationMarkerIconInfo: MarkerIconInfo(
          infoWindowTitle: "House",
          assetPath: "assets/icon/house.png",
          assetMarkerSize: Size.square(48),
        ),
        driverMarkerIconInfo: MarkerIconInfo(
          infoWindowTitle: "Alex",
          assetPath: "assets/icon/scooter.png",
          onTapMarker: (currentLocation) {
            debugPrint("Driver is currently at $currentLocation");
          },
          assetMarkerSize: Size.square(48),
          rotation: 360,
        ),
        updatePolylinesOnDriverLocUpdate: true,
        onPolylineUpdate: (_) {
          debugPrint("Polyline updated");
        },
        // mock stream
        driverCoordinatesStream: _driverCoordinatesController.stream,
        totalTimeCallback: (time) => debugPrint(" Total time: $time"),
        totalDistanceCallback: (distance) =>
            debugPrint(" Total distance: $distance"),
      ),
    );
  }
}

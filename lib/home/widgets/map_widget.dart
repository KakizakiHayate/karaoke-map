import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671), // 東京駅付近
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return const GoogleMap(
      initialCameraPosition: _kInitialPosition,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}

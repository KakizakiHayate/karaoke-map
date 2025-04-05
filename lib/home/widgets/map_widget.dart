import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;
  final LatLng initialLocation;
  final double initialZoom;

  const MapWidget({
    super.key,
    this.markers = const {},
    this.onMapCreated,
    this.initialLocation = const LatLng(35.6812, 139.7671), // デフォルトは東京駅付近
    this.initialZoom = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: initialZoom,
      ),
      markers: markers,
      onMapCreated: onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
    );
  }
}

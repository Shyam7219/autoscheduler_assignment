import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final Set<Marker> markers;
  final LatLng initialPosition;

  const MapWidget({
    super.key,
    required this.markers,
    required this.initialPosition,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      markers: markers,
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 12),
      myLocationEnabled: true,
    );
  }
}

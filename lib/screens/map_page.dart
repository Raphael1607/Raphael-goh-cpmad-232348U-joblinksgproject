import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  final LocationData? userLocation; 
  const MapPage({super.key, this.userLocation});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor _locIcon;              
  final Set<Marker> _markers = <Marker>{};      


  Future<BitmapDescriptor> _loadCustomIcon() async {
    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'images/home-map-pin.png',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCustomIcon().then((icon) {
      _locIcon = icon;

      final hasLoc = widget.userLocation?.latitude != null && widget.userLocation?.longitude != null;
      if (hasLoc) {
        final pos = LatLng(widget.userLocation!.latitude!, widget.userLocation!.longitude!);
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('current'),
              position: pos,
              infoWindow: const InfoWindow(title: 'Current Location'),
              icon: _locIcon,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fallback if location not provided
    final LatLng start = (widget.userLocation != null &&
            widget.userLocation!.latitude != null &&
            widget.userLocation!.longitude != null)
        ? LatLng(widget.userLocation!.latitude!, widget.userLocation!.longitude!)
        : const LatLng(1.3521, 103.8198); // Singapore as default

    final CameraPosition initial = CameraPosition(
      target: start,
      zoom: 14,
      tilt: 0,
      bearing: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.blueGrey.shade700,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initial,
        markers: _markers,
        onMapCreated: (c) => _controller.complete(c),
        myLocationButtonEnabled: false,
        myLocationEnabled: false,
      ),
    );
  }
}

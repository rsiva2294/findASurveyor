import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final FirestoreService _firestoreService;

  // A stream controller to hold the user's current location.
  final BehaviorSubject<Position> _positionStreamController = BehaviorSubject();

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), // Center of India
    zoom: 4,
  );

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition();
      // Only add to stream if the widget is still mounted.
      if(mounted) _positionStreamController.add(position);

    } catch (e) {
      if(mounted) _positionStreamController.addError(e);
    }
  }

  @override
  void dispose() {
    _positionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Surveyors Near Me')),
      body: StreamBuilder<Position>(
        stream: _positionStreamController.stream,
        builder: (context, positionSnapshot) {
          // Handle getting user's location
          if (positionSnapshot.connectionState == ConnectionState.waiting && !positionSnapshot.hasData) {
            return const Center(child: Text("Getting your location..."));
          }
          if (positionSnapshot.hasError) {
            return Center(child: Text("Error: ${positionSnapshot.error}"));
          }
          if (!positionSnapshot.hasData) {
            return const Center(child: Text("Could not determine location."));
          }

          final userPosition = positionSnapshot.data!;
          final surveyorStream = _firestoreService.streamNearbySurveyors(
            lat: userPosition.latitude,
            lng: userPosition.longitude,
          );

          // This inner StreamBuilder listens for the surveyors
          return StreamBuilder<List<Surveyor>>(
            stream: surveyorStream,
            builder: (context, surveyorSnapshot) {

              // --- THE FIX IS HERE ---
              // We build the markers directly inside the build method.
              // No more separate state variable or setState calls.
              Set<Marker> markers = {};
              if (surveyorSnapshot.hasData) {
                markers = surveyorSnapshot.data!
                    .where((s) => s.geopoint != null)
                    .map((surveyor) => Marker(
                  markerId: MarkerId(surveyor.id),
                  position: LatLng(surveyor.geopoint!.latitude, surveyor.geopoint!.longitude),
                  infoWindow: InfoWindow(
                    title: "Name: ${surveyor.surveyorNameEn}",
                    snippet: "Level: ${surveyor.iiislaLevel}",
                    onTap: (){
                      context.pushNamed(
                        AppRoutes.detail,
                        pathParameters: {'id': surveyor.id},
                      );
                    }
                  ),
                )).toSet();
              }
              // --- END FIX ---

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(userPosition.latitude, userPosition.longitude),
                  zoom: 10,
                ),
                markers: markers, // Use the markers we just built
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              );
            },
          );
        },
      ),
    );
  }
}

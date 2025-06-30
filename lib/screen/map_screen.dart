import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  final BehaviorSubject<Position> _positionStreamController = BehaviorSubject();

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
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
      if (mounted) _positionStreamController.add(position);
    } catch (e) {
      if (mounted) _positionStreamController.addError(e);
    }
  }

  @override
  void dispose() {
    _positionStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Surveyors Near Me'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.map_outlined), text: 'Map View'),
              Tab(icon: Icon(Icons.list), text: 'List View'),
            ],
          ),
        ),
        body: StreamBuilder<Position>(
          stream: _positionStreamController.stream,
          builder: (context, positionSnapshot) {
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

            return StreamBuilder<List<Surveyor>>(
              stream: surveyorStream,
              builder: (context, surveyorSnapshot) {
                final surveyors = surveyorSnapshot.data ?? [];

                // Handle loading/empty state for the surveyor data
                if (surveyorSnapshot.connectionState == ConnectionState.waiting && surveyors.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!surveyorSnapshot.hasData || surveyors.isEmpty) {
                  return const Center(child: Text("No surveyors found nearby."));
                }

                return TabBarView(
                  children: [
                    _buildMapView(surveyors, userPosition),
                    _buildListView(surveyors),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapView(List<Surveyor> surveyors, Position userPosition) {
    final Set<Marker> markers = surveyors.where((s) => s.geopoint != null).map((surveyor) {
      return Marker(
        markerId: MarkerId(surveyor.id),
        position: LatLng(surveyor.geopoint!.latitude, surveyor.geopoint!.longitude),
        infoWindow: InfoWindow(
          title: surveyor.surveyorNameEn,
          snippet: surveyor.cityEn,
          onTap: () {
            context.pushNamed(
                AppRoutes.detail,
                pathParameters: {'id': surveyor.id},
            );
          },
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(userPosition.latitude, userPosition.longitude),
        zoom: 10,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  Widget _buildListView(List<Surveyor> surveyors) {
    return ListView.builder(
      itemCount: surveyors.length,
      itemBuilder: (context, index) {
        final surveyor = surveyors[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?'),
            ),
            title: Text(surveyor.surveyorNameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${surveyor.cityEn}, ${surveyor.stateEn}'),
            trailing: LevelChipWidget(level: surveyor.iiislaLevel),
            onTap: () {
              context.pushNamed(
                  AppRoutes.detail,
                  pathParameters: {'id': surveyor.id},
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final FirestoreService _firestoreService;
  late final Future<List<Surveyor>> _nearbySurveyorsFuture;
  LatLng? _userLocation;

  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    // Assign the future once in initState. The FutureBuilder will handle it.
    _nearbySurveyorsFuture = _determinePositionAndFetch();
  }

  /// This single method handles permissions, gets the location, and fetches the data.
  Future<List<Surveyor>> _determinePositionAndFetch() async {
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

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }

      // Return the future from the service call.
      return _firestoreService.getNearbySurveyors(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      // Re-throw the exception to be caught by the FutureBuilder.
      rethrow;
    }
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
        body: FutureBuilder<List<Surveyor>>(
          future: _nearbySurveyorsFuture,
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Handle error state
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            // Handle empty/no-data state
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No surveyors found nearby."));
            }

            // If we have data, build the UI
            final surveyors = snapshot.data!;
            final Set<String> availableDepartments = {};
            for (var surveyor in surveyors) {
              availableDepartments.addAll(surveyor.departments);
            }
            final sortedDepartments = availableDepartments.toList()..sort();
            return TabBarView(
              children: [
                _buildMapView(surveyors),
                _buildListView(surveyors, sortedDepartments),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapView(List<Surveyor> surveyors) {
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
        target: _userLocation ?? const LatLng(20.5937, 78.9629),
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

  Widget _buildListView(List<Surveyor> surveyors, List<String> sortedDepartments) {

    final filteredSurveyors = _selectedDepartment == null
        ? surveyors
        : surveyors.where((surveyor) => surveyor.departments.contains(_selectedDepartment)).toList();

    return Column(
      children: [
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: sortedDepartments.length,
            itemBuilder: (context, index) {
              final department = sortedDepartments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(department.replaceAll('_', ' ').toUpperCase()),
                  selected: _selectedDepartment == department,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDepartment = selected ? department : null;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filteredSurveyors.isEmpty ? const Center(child: Text('No surveyors found')) :
          ListView.builder(
            itemCount: filteredSurveyors.length,
            itemBuilder: (context, index) {
              final surveyor = filteredSurveyors[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?'),
                  ),
                  title: Text(surveyor.surveyorNameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${surveyor.cityEn}, ${surveyor.stateEn}'),
                  trailing: surveyor.distanceInKm != null
                      ? Text('${surveyor.distanceInKm!.toStringAsFixed(1)} km')
                      : null,
                  onTap: () {
                    context.pushNamed(
                      AppRoutes.detail,
                      pathParameters: {'id': surveyor.id},
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

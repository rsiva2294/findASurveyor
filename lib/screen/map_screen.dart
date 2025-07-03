import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
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

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver{
  late final FirestoreService _firestoreService;
  late Future<List<Surveyor>> _nearbySurveyorsFuture;
  LatLng? _userLocation;

  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _nearbySurveyorsFuture = _determinePositionAndFetch();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _nearbySurveyorsFuture = _determinePositionAndFetch();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// This single method now robustly handles permissions and service status.
  Future<List<Surveyor>> _determinePositionAndFetch() async {
    // 1. Check if location services are enabled on the device.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // If not, throw a specific error that the UI can catch.
      return Future.error('Location services are disabled. Please enable them in your device settings.');
    }

    // 2. Check for app-specific permissions.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied. We cannot request permissions.');
    }

    // 3. If we get here, permissions are granted. Fetch the position.
    final position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }

    // 4. Return the future from the service call.
    return _firestoreService.getNearbySurveyors(
      lat: position.latitude,
      lng: position.longitude,
    );
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
            // Handle error state with specific, actionable feedback
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
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
                  label: Text(department.replaceAll('_', ' ').toTitleCaseExt()),
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
          child: filteredSurveyors.isEmpty ? const Center(child: Text('No surveyors match this filter.')) :
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
                  title: Text(surveyor.surveyorNameEn.toTitleCaseExt(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${surveyor.cityEn.toTitleCaseExt()}, ${surveyor.stateEn.toTitleCaseExt()}'),
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

  // --- NEW: Helper widget to show actionable error messages ---
  Widget _buildErrorWidget(String error) {
    bool isServiceError = error.contains('services are disabled');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Show a button to open settings only if the service is disabled
            if (isServiceError)
              ElevatedButton(
                onPressed: () => Geolocator.openLocationSettings(),
                child: const Text('Open Location Settings'),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (){
                setState(() {
                  _nearbySurveyorsFuture = _determinePositionAndFetch();
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

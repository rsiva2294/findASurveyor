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

enum SortOptions { distance, name, level }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

// REMOVED: `with WidgetsBindingObserver` to prevent the refresh loop.
class _MapScreenState extends State<MapScreen> {
  late final FirestoreService _firestoreService;
  late Future<List<Surveyor>> _nearbySurveyorsFuture;
  LatLng? _userLocation;

  String? _selectedDepartment;
  SortOptions _currentSortOption = SortOptions.distance; // Default sort

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _nearbySurveyorsFuture = _determinePositionAndFetch();
  }

  // This method is now only called from initState and the "Try Again" button.
  Future<List<Surveyor>> _determinePositionAndFetch() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable them in your device settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied. Please enable them in your device settings.');
    }

    final position = await Geolocator.getCurrentPosition();

    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }

    return _firestoreService.getNearbySurveyors(
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  /// A clean method to re-trigger the future for the FutureBuilder.
  void _retryFetch() {
    setState(() {
      _nearbySurveyorsFuture = _determinePositionAndFetch();
    });
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No surveyors found nearby."));
            }

            final surveyors = snapshot.data!;
            final Set<String> availableDepartments = {};
            for (var surveyor in surveyors) {
              availableDepartments.addAll(surveyor.departments);
            }
            final sortedDepartments = availableDepartments.toList()..sort();

            return TabBarView(
              physics: const NeverScrollableScrollPhysics(),
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
    // --- NEW: Client-side filtering and sorting logic ---
    List<Surveyor> filteredSurveyors = List.from(surveyors);

    // 1. Apply department filter first
    if (_selectedDepartment != null) {
      filteredSurveyors = filteredSurveyors.where((s) => s.departments.contains(_selectedDepartment)).toList();
    }

    // 2. Apply sorting logic
    switch (_currentSortOption) {
      case SortOptions.name:
        filteredSurveyors.sort((a, b) => a.surveyorNameEn.compareTo(b.surveyorNameEn));
        break;
      case SortOptions.level:
        filteredSurveyors.sort((a, b) => a.professionalRank.compareTo(b.professionalRank));
        break;
      case SortOptions.distance:
      // The list is already sorted by distance from the service
        break;
    }
    // --- END NEW LOGIC ---

    final Set<String> availableDepartments = {};
    for (var surveyor in surveyors) { // Build chips from original list
      availableDepartments.addAll(surveyor.departments);
    }
    final sortedDepartments = availableDepartments.toList()..sort();

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
        // --- NEW: Sort Dropdown Section ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Sort by:"),
              const SizedBox(width: 8),
              DropdownButton<SortOptions>(
                value: _currentSortOption,
                underline: const SizedBox.shrink(),
                style: TextStyle(fontSize: 14.0, color: ColorScheme.of(context).onSurface),
                items: const [
                  DropdownMenuItem(value: SortOptions.distance, child: Text('Distance')),
                  DropdownMenuItem(value: SortOptions.name, child: Text('Name')),
                  DropdownMenuItem(value: SortOptions.level, child: Text('Level')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentSortOption = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredSurveyors.isEmpty ? const Center(child: Text('No surveyors match this filter.')) :
          ListView.builder(
            itemCount: filteredSurveyors.length,
            itemBuilder: (context, index) {
              final surveyor = filteredSurveyors[index];
              return _buildSurveyorCard(surveyor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyorCard(Surveyor surveyor) {
    final BoxDecoration? decoration = surveyor.isVerified
        ? BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withAlpha(200),
          Theme.of(context).colorScheme.secondary.withAlpha(200),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
    )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: decoration,
      child: Padding(
        padding: EdgeInsets.all(surveyor.isVerified ? 3.0 : 0.0),
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: () {
              context.pushNamed(
                AppRoutes.detail,
                pathParameters: {'id': surveyor.id},
              );
            },
            leading: CircleAvatar(
              child: Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?'),
            ),
            title: Row(
              children: [
                Flexible(child: Text(surveyor.surveyorNameEn.toTitleCaseExt())),
                const SizedBox(width: 8),
                if (surveyor.isVerified)
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            subtitle: Text('${surveyor.cityEn.toTitleCaseExt()}, ${surveyor.stateEn.toTitleCaseExt()}'),
            trailing: surveyor.distanceInKm != null
                ? Text('${surveyor.distanceInKm!.toStringAsFixed(1)} km')
                : null,
          ),
        ),
      ),
    );
  }

  // --- Helper widget to show actionable error messages ---
  Widget _buildErrorWidget(String error) {
    bool isServiceError = error.contains('services are disabled');
    bool isPermissionError = error.contains('denied');

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
            if (isServiceError)
              ElevatedButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Location Settings'),
              ),
            if (isPermissionError)
              ElevatedButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                child: const Text('Open App Settings'),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh_outlined),
              onPressed: _retryFetch,
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

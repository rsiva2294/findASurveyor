import 'package:find_a_surveyor/model/filter_model.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterBottomSheet extends StatefulWidget {
  // A callback to pass the selected filters back to the ListScreen.
  final Function(FilterModel filters) onApplyFilters;
  // The currently active filters, so the sheet can show the previous selections.
  final FilterModel initialFilters;

  const FilterBottomSheet({
    super.key,
    required this.onApplyFilters,
    required this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final FirestoreService _firestoreService;

  // Local state for the filter selections within the sheet.
  LocationData? _selectedStateData;
  String? _selectedCity;
  String? _selectedLevel;
  String? _selectedDepartment;

  // State to hold the fetched data for the dropdowns and chips.
  late Future<FilterOptions> _filterOptionsFuture;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);

    // Set initial values from the parent screen's active filters.
    _selectedLevel = widget.initialFilters.iiislaLevel;
    _selectedDepartment = widget.initialFilters.department;

    // Fetch all filter options at once.
    _filterOptionsFuture = _firestoreService.getFilterOptions();
  }

  /// Packages up the selected filters and sends them back to the ListScreen.
  void _handleApplyFilters() {
    // This check is now a safeguard, as the button should be disabled if this is not met.
    if (_selectedStateData == null || _selectedCity == null) return;

    final filters = FilterModel(
      stateName: _selectedStateData!.stateName,
      city: _selectedCity,
      department: _selectedDepartment,
      iiislaLevel: _selectedLevel,
    );

    widget.onApplyFilters(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the apply button should be enabled
    final bool canApply = _selectedStateData != null && _selectedCity != null;

    return FutureBuilder<FilterOptions>(
      future: _filterOptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error: ${snapshot.error}")));
        }
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("Could not load filter options.")));
        }

        final filterOptions = snapshot.data!;
        final locations = filterOptions.locations;
        final departments = filterOptions.departments;

        // Pre-select state if it was part of the initial filters (runs only once)
        if (_selectedStateData == null && widget.initialFilters.stateName != null) {
          _selectedStateData = locations.firstWhere((loc) => loc.stateId == widget.initialFilters.stateName,
            orElse: () => locations.first,
          );
          if (widget.initialFilters.city != null) {
            _selectedCity = widget.initialFilters.city;
          }
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Text('Filter Surveyors', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),

                // State Dropdown
                DropdownButtonFormField<LocationData>(
                  value: _selectedStateData,
                  isExpanded: true,
                  hint: const Text('Select State*'),
                  items: locations.map((location) {
                    return DropdownMenuItem(value: location, child: Text(location.stateName));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStateData = value;
                      _selectedCity = null; // Reset city when state changes
                    });
                  },
                ),
                const SizedBox(height: 16),

                // City Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  isExpanded: true,
                  hint: const Text('Select City*'),
                  items: (_selectedStateData?.cities ?? []).map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCity = value);
                  },
                  decoration: InputDecoration(
                    enabled: _selectedStateData != null,
                  ),
                ),
                const SizedBox(height: 24),

                // Level Chips
                const Text('IIISLA Level', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: ['Fellow', 'Associate', 'Licentiate'].map((level) {
                    return ChoiceChip(
                      label: Text(level),
                      selected: _selectedLevel == level,
                      onSelected: (selected) {
                        setState(() {
                          _selectedLevel = selected ? level : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Button is disabled if the mandatory fields are not selected
                    onPressed: canApply ? _handleApplyFilters : null,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
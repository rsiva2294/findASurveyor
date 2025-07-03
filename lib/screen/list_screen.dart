import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/filter_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/screen/filter_bottom_sheet.dart';
import 'package:find_a_surveyor/screen/search_results_view.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  // Services
  late final FirestoreService _firestoreService;
  late final DatabaseService _databaseService;

  // State for the list
  final List<Surveyor> _surveyors = [];
  DocumentSnapshot? _lastDocument;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasMoreData = true;
  String? _error;
  late final ScrollController _scrollController;

  final SearchController _searchController = SearchController();

  // State for filtering
  bool _isFilterActive = false;
  FilterModel _activeFilters = FilterModel();

  // State for favorites
  late Future<List<Surveyor>> _favoritesFuture;

  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _scrollController = ScrollController()..addListener(_scrollListener);

    _loadFavorites();
    _fetchSurveyors();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _databaseService.getFavorites();
    });
  }

  void _refreshFavorites() {
    _loadFavorites();
  }

  Future<void> _fetchSurveyors() async {
    // For the default paginated list
    if (_isLoading || !_hasMoreData) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final SurveyorPage result = await _firestoreService.getSurveyors(
        limit: _limit,
        startAfterDoc: _lastDocument,
      );
      if (mounted) {
        setState(() {
          _surveyors.addAll(result.surveyorList);
          _lastDocument = result.lastDocument;
          if (result.surveyorList.length < _limit) _hasMoreData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Failed to load data.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollListener() {
    // This listener is only for the default view's pagination
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) _fetchSurveyors();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => FilterBottomSheet(
        onApplyFilters: _applyFilters,
        initialFilters: _activeFilters,
      ),
      isScrollControlled: true,
    );
  }

  void _applyFilters(FilterModel filters) {
    setState(() {
      _isFilterActive = true;
      _activeFilters = filters;
    });
  }

  void _clearFilters() {
    setState(() {
      _isFilterActive = false;
      _activeFilters = FilterModel();
      _selectedDepartment = null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  final List<String> exampleQueries = [
    "Marine Hull Madurai",
    "Associate Chennai",
    "625006",
    "Sharma Rajasthan",
    "Engineering Fellow",
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFilterActive,
      onPopInvokedWithResult: (didPop, result){
        if (didPop) {
          return;
        }
        if (_isFilterActive) {
          _clearFilters();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isFilterActive ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _clearFilters,
          ) : null,
          title: Text(_isFilterActive ? "Filtered Results" : "Find A Surveyor"),
          actions: _isFilterActive ? [] : [
            SearchAnchor(
              viewSurfaceTintColor: ColorScheme.of(context).onSurface,
              builder: (BuildContext context, SearchController controller) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    controller.openView();
                  },
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                // The suggestions builder is now very simple.
                if (controller.text.isEmpty) {
                  return [
                    // Tip Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.tips_and_updates, color: Colors.teal),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Tip: Combine fields like department, location, or name to refine your search",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Search powered by "),
                                Image.asset(
                                  Theme.of(context).brightness == Brightness.light ?
                                  'assets/icon/Algolia-mark-circle-white.png' :
                                  'assets/icon/Algolia-mark-circle-blue.png',
                                  height: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Suggestion Tiles
                    ...exampleQueries.map((query) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.search, color: Colors.teal),
                        title: Text(query),
                        onTap: () {
                          controller.text = query;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        },
                      );
                    }),
                  ];
                }

                // It just returns our new, dedicated search results widget.
                return [
                  SearchResultsView(searchController: controller)
                ];
              },
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _isFilterActive ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: _showFilterSheet,
            ),
          ],
        ),
        body: _isFilterActive ? _buildFilteredBody() : _buildDefaultBody(),
        floatingActionButton: _isFilterActive ?
        FloatingActionButton.extended(
          onPressed: _clearFilters,
          label: Text("Clear Filter"),
          icon: Icon(Icons.filter_list_off_outlined),
        ) : FloatingActionButton.extended(
          label: const Text("Near Me"),
          icon: const Icon(Icons.location_on),
          onPressed: () {
            context.pushNamed(AppRoutes.map).then((_) => _refreshFavorites());
          },
        ),
      ),
    );
  }

  // The default view with Favorites and paginated "All Surveyors"
  Widget _buildDefaultBody() {
    return RefreshIndicator(
      onRefresh: () async {
        _surveyors.clear();
        _lastDocument = null;
        _hasMoreData = true;
        _loadFavorites();
        await _fetchSurveyors();
      },
      child: CustomScrollView(
        controller: _scrollController, // Controller is attached here
        slivers: [
          _buildSectionHeader("Favorites"),
          _buildFavoritesList(),
          _buildSectionHeader("All Surveyors"),
          _buildPaginatedSliverList(),
          _buildPaginationIndicator(),
        ],
      ),
    );
  }

  // The view for when filters are applied
  Widget _buildFilteredBody() {
    // Now, the department chips will be built inside the FutureBuilder's scope,
    // once the filtered surveyors are loaded.
    return FutureBuilder<List<Surveyor>>(
      future: _firestoreService.getFilteredSurveyors(filters: _activeFilters),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final allFilteredSurveyors = snapshot.data;
        if (allFilteredSurveyors == null || allFilteredSurveyors.isEmpty) {
          return const Center(child: Text("No surveyors match your criteria."));
        }

        // Derive departments from the ACTUAL filtered list
        final Set<String> departmentsSet = {};
        for (var surveyor in allFilteredSurveyors) {
          departmentsSet.addAll(surveyor.departments);
        }
        final sortedDepartments = departmentsSet.toList()..sort();

        // Filter the surveyors based on the selected department chip
        final surveyorsToDisplay = _selectedDepartment == null
            ? allFilteredSurveyors
            : allFilteredSurveyors
            .where((s) => s.departments.contains(_selectedDepartment))
            .toList();

        if (surveyorsToDisplay.isEmpty && _selectedDepartment != null) {
          // Handle case where a department is selected but no surveyors match it
          // from the already filtered list.
          return Column(
            children: [
              _buildDepartmentFilterChips(sortedDepartments), // Still show all available departments from the broader filter
              const Divider(height: 1),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No surveyors found for the selected department in the current filter results."),
                  ),
                ),
              ),
            ],
          );
        }

        if (surveyorsToDisplay.isEmpty && _selectedDepartment == null && allFilteredSurveyors.isNotEmpty) {
          // This case should ideally not be hit if allFilteredSurveyors is not empty,
          // but as a fallback.
          return Column(
            children: [
              _buildDepartmentFilterChips(sortedDepartments),
              const Divider(height: 1),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No surveyors match your criteria."),
                  ),
                ),
              ),
            ],
          );
        }


        return Column(
          children: [
            _buildDepartmentFilterChips(sortedDepartments),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: surveyorsToDisplay.length,
                itemBuilder: (context, index) =>
                    _buildSurveyorCard(surveyorsToDisplay[index]),
              ),
            ),
          ],
        );
      },
    );
  }

// _buildDepartmentFilterChips remains largely the same,
// as it now receives the correct list of departments.
  Widget _buildDepartmentFilterChips(List<String> departments) {
    if (departments.isEmpty) {
      return const SizedBox(height: 60, child: Center(child: Text("No departments to filter by.")));
    }
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final department = departments[index];
          final isSelected = _selectedDepartment == department;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(department.replaceAll('_', ' ').toTitleCaseExt()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDepartment = selected ? department : null;
                  // No need to re-fetch, the FutureBuilder will re-evaluate
                  // its builder method and the list will be filtered locally.
                });
              },
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return FutureBuilder<List<Surveyor>>(
      future: _favoritesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No favorites added yet."))));
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSurveyorCard(snapshot.data![index]),
            childCount: snapshot.data!.length,
          ),
        );
      },
    );
  }

  Widget _buildPaginatedSliverList() {
    if (_error != null && _surveyors.isEmpty) return SliverFillRemaining(child: Center(child: Text(_error!)));
    if (_surveyors.isEmpty && _isLoading) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    if (_surveyors.isEmpty && !_isLoading) return const SliverFillRemaining(child: Center(child: Text("No surveyors found.")));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSurveyorCard(_surveyors[index]),
        childCount: _surveyors.length,
      ),
    );
  }

  Widget _buildPaginationIndicator() {
    return SliverToBoxAdapter(
      child: _isLoading && _surveyors.isNotEmpty
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSurveyorCard(Surveyor surveyor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        child: ListTile(
          onTap: () {
            context.pushNamed(
              AppRoutes.detail,
              pathParameters: {'id': surveyor.id},
            ).then((_) => _refreshFavorites());
          },
          leading: CircleAvatar(
            child: Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?'),
          ),
          title: Text(surveyor.surveyorNameEn.toTitleCaseExt()),
          subtitle: Text('${surveyor.cityEn.toTitleCaseExt()}, ${surveyor.stateEn.toTitleCaseExt()}'),
          trailing: LevelChipWidget(level: surveyor.iiislaLevel),
        ),
      ),
    );
  }
}

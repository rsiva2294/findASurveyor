import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/filter_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/screen/filter_bottom_sheet.dart';
import 'package:find_a_surveyor/screen/profile_bottom_sheet.dart';
import 'package:find_a_surveyor/screen/search_results_view.dart';
import 'package:find_a_surveyor/service/authentication_service.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum SortOptions { level, name }

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  // Services
  late final FirestoreService _firestoreService;
  late final DatabaseService _databaseService;
  late final AuthenticationService _authenticationService;

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
  List<Surveyor> _favorites = [];
  bool _isLoadingFavorites = false;
  SortOptions filteredSortOption = SortOptions.level; // Default sort for filtered results
  String? _selectedDepartment;

  bool _showVerified = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authenticationService = Provider.of<AuthenticationService>(context, listen: false);
    _scrollController = ScrollController()..addListener(_scrollListener);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadFavorites(),
      _fetchSurveyors(),
    ]);
  }

  /// Implements the "cache-then-network" strategy for favorites.
  Future<void> _loadFavorites() async {
    setState(() { _isLoadingFavorites = true; });

    // 1. Instantly load from the local cache to show the UI immediately.
    try {
      final localFavorites = await _databaseService.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = localFavorites;
        });
      }
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
    }

    // 2. Then, fetch the source of truth from the cloud.
    final user = _authenticationService.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final cloudFavorites = await _firestoreService.getCloudFavorites(user.uid);

        // 3. Sync the cloud data back to the local cache.
        await _databaseService.clearFavorites();
        await _databaseService.bulkInsertFavorites(cloudFavorites);

        // 4. Update the UI with the definitive, synced list.
        if (mounted) {
          setState(() {
            _favorites = cloudFavorites;
          });
        }
      } catch (e, stack) {
        FirebaseCrashlytics.instance.recordError(e, stack);
        print("Could not sync favorites from cloud: $e");
      }
    }

    if (mounted) {
      setState(() { _isLoadingFavorites = false; });
    }
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
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack);
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
      filteredSortOption = SortOptions.name;
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
            context.pushNamed(AppRoutes.mapName).then((_) => _refreshFavorites());
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
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController, // Controller is attached here
          slivers: [
            _buildTopSearchBar(context),
            _buildSectionHeader("Favorites"),
            _buildFavoritesList(),
            _buildSectionHeader("All Surveyors"),
            _buildPaginatedSliverList(),
            _buildPaginationIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 5, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SearchAnchor(
                  searchController: _searchController,
                  viewSurfaceTintColor: Theme.of(context).colorScheme.onSurface,
                  builder: (context, controller) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10.0),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.openView(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Search surveyors',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetContext) => ProfileSheet(
                              parentContext: context,
                              onLoginSuccess: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final isStillMounted = mounted;
                                try {
                                  final userCredential = await _authenticationService.linkGoogleToCurrentUser();
                                  if (userCredential != null && isStillMounted) {
                                    setState(() {});
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('You are now signed-in'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e, stack) {
                                  FirebaseCrashlytics.instance.recordError(e, stack);
                                  if (isStillMounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            child: const Icon(Icons.settings),
                          ),
                        ),
                      ],
                    ),
                  ),
                  suggestionsBuilder: (context, controller) {
                    if (controller.text.isEmpty) {
                      return [
                        Card(
                          margin: const EdgeInsets.all(8),
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
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Search powered by "),
                                    Image.asset(
                                      Theme.of(context).brightness == Brightness.light
                                          ? 'assets/icon/Algolia-mark-circle-white.png'
                                          : 'assets/icon/Algolia-mark-circle-blue.png',
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
                    return [
                      SearchResultsView(
                        searchController: controller,
                        onProfileScreenClosed: _refreshFavorites,
                      ),
                    ];
                  },
                ),
              ),
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
      ),
    );
  }

  // The view for when filters are applied
  Widget _buildFilteredBody() {
    return SafeArea(
      child: FutureBuilder<List<Surveyor>>(
        future: _firestoreService.getFilteredSurveyors(filters: _activeFilters),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No surveyors match your initial criteria."),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _clearFilters, child: const Text("Clear Filters"))
                ],
              ),
            );
          }

          // --- Start of Client-Side Filtering and Sorting ---
          final allFilteredSurveyors = snapshot.data!;
          List<Surveyor> surveyorsToDisplay = List.from(allFilteredSurveyors);

          // 1. Apply department sub-filter
          if (_selectedDepartment != null) {
            surveyorsToDisplay = surveyorsToDisplay
                .where((s) => s.departments.contains(_selectedDepartment))
                .toList();
          }

          if (_showVerified) {
            surveyorsToDisplay = surveyorsToDisplay.where((s) => s.isVerified).toList();
          }

          // 2. Apply sorting
          switch (filteredSortOption) {
            case SortOptions.name:
              surveyorsToDisplay.sort((a, b) => a.surveyorNameEn.compareTo(b.surveyorNameEn));
              break;
            case SortOptions.level:
              surveyorsToDisplay.sort((a, b) => a.professionalRank.compareTo(b.professionalRank));
              break;
          }

          final Set<String> departmentsSet = {};
          for (var surveyor in allFilteredSurveyors) {
            departmentsSet.addAll(surveyor.departments);
          }
          final sortedDepartments = departmentsSet.toList()..sort();
          // --- End of Client-Side Logic ---

          return Column(
            children: [
              _buildFilterControls(sortedDepartments), // New widget for controls
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text("Show Verified:"),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: _showVerified,
                        onChanged: (bool value) {
                          setState(() {
                            _showVerified = value;
                          });
                        },
                      ),
                    ),
                    Spacer(),
                    const Text("Sort by:"),
                    const SizedBox(width: 8),
                    DropdownButton<SortOptions>(
                      value: filteredSortOption,
                      underline: const SizedBox.shrink(),
                      style: TextStyle(fontSize: 14.0, color: ColorScheme.of(context).onSurface),
                      items: const [
                        DropdownMenuItem(value: SortOptions.level, child: Text('By Level')),
                        DropdownMenuItem(value: SortOptions.name, child: Text('By Name')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            filteredSortOption = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: surveyorsToDisplay.isEmpty
                    ? const Center(child: Text("No surveyors match the selected department."))
                    : ListView.builder(
                  itemCount: surveyorsToDisplay.length,
                  itemBuilder: (context, index) => _buildSurveyorCard(surveyorsToDisplay[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterControls(List<String> departments) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final department = departments[index];
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
    if (_isLoadingFavorites && _favorites.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())));
    }
    if (_favorites.isEmpty) {
      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No favorites added yet."))));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSurveyorCard(_favorites[index], isFromFav: true),
        childCount: _favorites.length,
      ),
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

  Widget _buildSurveyorCard(Surveyor surveyor, {bool isFromFav = false}) {
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
    ) : null;

    final hasImage = surveyor.profilePictureUrl != null && surveyor.profilePictureUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: decoration,
      child: Padding(
        padding: EdgeInsets.all(surveyor.isVerified ? 3 : 0.0),
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: () {
              context.pushNamed(
                AppRoutes.detailName,
                pathParameters: {'id': surveyor.id},
                extra: surveyor,
              ).then((_) => _loadInitialData());
            },
            leading: Hero(
              tag: isFromFav ? 'surveyor_avatar_${surveyor.id}_fav' : 'surveyor_avatar_${surveyor.id}',
              child: CircleAvatar(
                backgroundImage: hasImage ? NetworkImage(surveyor.profilePictureUrl!) : null,
                child: !hasImage
                    ? Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?')
                    : null,
              ),
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
            trailing: LevelChipWidget(level: surveyor.iiislaLevel),
          ),
        ),
      ),
    );
  }
}

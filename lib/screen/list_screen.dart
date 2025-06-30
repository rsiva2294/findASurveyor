import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/database_service.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
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
  late final FirestoreService _firestoreService;
  final List<Surveyor> _surveyors = [];
  DocumentSnapshot? _lastDocument;
  final int _limit = 20;

  bool _isLoading = false;
  bool _hasMoreData = true;
  String? _firestoreError;

  late final ScrollController _scrollController;

  late final DatabaseService _databaseService;
  late Future<List<Surveyor>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
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
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _firestoreError = null;
    });

    try {
      final SurveyorPage result = await _firestoreService.getSurveyors(
        limit: _limit,
        startAfterDoc: _lastDocument,
      );

      final newSurveyors = result.surveyorList;
      final newLastDocument = result.lastDocument;

      if (mounted) {
        setState(() {
          _surveyors.addAll(newSurveyors);
          _lastDocument = newLastDocument;

          if (newSurveyors.length < _limit) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firestoreError = "Failed to load data. Please check your connection.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _fetchSurveyors();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find A Surveyor"),
        actions: [
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
              return [
                FutureBuilder<List<Surveyor>>(
                  future: _firestoreService.searchSurveyors(controller.text),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Could not perform search. Please try again.'),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      if (controller.text.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('Search by name, city, or pincode.'),
                          ),
                        );
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No results found.'),
                          ),
                        );
                      }
                    }

                    return Column(
                      children: snapshot.data!.map((surveyor) {
                        return ListTile(
                          title: Text(surveyor.surveyorNameEn),
                          subtitle: Text('${surveyor.cityEn}, ${surveyor.stateEn}'),
                          trailing: LevelChipWidget(level: surveyor.iiislaLevel),
                          onTap: () {
                            controller.closeView(surveyor.id);
                            context.pushNamed(
                              AppRoutes.detail,
                              pathParameters: {'id': surveyor.id},
                            ).then((_) => _refreshFavorites());
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ];
            },
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSectionHeader("Favorites"),
          _buildFavoritesList(),

          _buildSectionHeader("All Surveyors"),
          _buildAllSurveyorsList(),

          _buildPaginationIndicator(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("Near Me"),
        icon: Icon(Icons.location_on),
        onPressed: () {
          context.pushNamed(AppRoutes.map).then((_) => _refreshFavorites());
        },
      ),
    );
  }

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
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Center(child: Text("Error loading favorites: ${snapshot.error}")));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No favorites added yet."),
            ),
          ));
        }

        final favorites = snapshot.data!;
        // Use SliverList for lists inside a CustomScrollView
        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final surveyor = favorites[index];
              return _buildSurveyorCard(surveyor);
            },
            childCount: favorites.length,
          ),
        );
      },
    );
  }

  Widget _buildAllSurveyorsList() {
    if (_firestoreError != null && _surveyors.isEmpty) {
      return SliverToBoxAdapter(child: Center(child: Text(_firestoreError!)));
    }
    if (_surveyors.isEmpty && !_isLoading) {
      return const SliverToBoxAdapter(child: Center(child: Text("No surveyors found.")));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final surveyor = _surveyors[index];
          return _buildSurveyorCard(surveyor);
        },
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

  // A single, reusable method to build the surveyor card UI
  Widget _buildSurveyorCard(Surveyor surveyor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        child: ListTile(
          onTap: () {
            // Navigate and then refresh the favorites list when we come back.
            context.pushNamed(
              AppRoutes.detail,
              pathParameters: {'id': surveyor.id},
            ).then((_) => _refreshFavorites());
          },
          leading: CircleAvatar(
            child: Text(surveyor.surveyorNameEn.isNotEmpty ? surveyor.surveyorNameEn[0] : '?'),
          ),
          title: Text(surveyor.surveyorNameEn),
          subtitle: Text('${surveyor.cityEn}, ${surveyor.stateEn}'),
          trailing: LevelChipWidget(level: surveyor.iiislaLevel),
        ),
      ),
    );
  }
}

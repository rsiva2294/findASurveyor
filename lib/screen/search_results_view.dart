import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:find_a_surveyor/env/env.dart';
import 'package:find_a_surveyor/model/algolia_surveyor_model.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/service/firestore_service.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

class SearchResultsView extends StatefulWidget {
  final SearchController searchController;
  final VoidCallback onProfileScreenClosed;

  const SearchResultsView({super.key, required this.searchController, required this.onProfileScreenClosed});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final _hitsSearcher = HitsSearcher(
    applicationID: Env.algoliaAppId,
    apiKey: Env.algoliaApiKey,
    indexName: 'surveyors',
  );

  Stream<HitsPage> get _searchPage =>
      _hitsSearcher.responses.map(HitsPage.fromResponse);

  final PagingController<int, AlgoliaSurveyor> _pagingController =
  PagingController(firstPageKey: 0);

  late final FirestoreService firestoreService;

  @override
  void initState() {
    super.initState();

    widget.searchController.addListener(_onSearchTextChanged);

    _searchPage.listen((page) {
      if (page.pageKey == 0) {
        _pagingController.refresh();
      }
      if (page.isLastPage) {
        _pagingController.appendLastPage(page.items);
      } else {
        _pagingController.appendPage(page.items, page.pageKey + 1);
      }
    }).onError((error) {
      _pagingController.error = error;
    });

    _pagingController.addPageRequestListener((pageKey) {
      _hitsSearcher.applyState((state) => state.copyWith(page: pageKey));
    });

    // Trigger the initial search
    _onSearchTextChanged();
    firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  void _onSearchTextChanged() {
    EasyDebounce.debounce(
      'search-debouncer', // A unique ID for this debouncer
      const Duration(seconds: 1), // The delay duration
          () { // The function to call after the delay
        if (mounted && widget.searchController.text.isNotEmpty) {
          _hitsSearcher.query(widget.searchController.text);
        }
      },
    );
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchTextChanged);
    _hitsSearcher.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: PagedListView<int, AlgoliaSurveyor>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<AlgoliaSurveyor>(
          itemBuilder: (itemContext, algoliaSurveyor, index) => ListTile(
            title: Text(algoliaSurveyor.surveyorNameEn.toTitleCaseExt()),
            subtitle: Text('${algoliaSurveyor.cityEn.toTitleCaseExt()}, ${algoliaSurveyor.stateEn.toTitleCaseExt()}'),
            trailing: LevelChipWidget(level: algoliaSurveyor.iiislaLevel),
              onTap: () async {
                final navContext = context;
                final Surveyor surveyor = await firestoreService.getSurveyorByID(algoliaSurveyor.id);
                if (!navContext.mounted) return;
                navContext.pushNamed(
                  AppRoutes.detail,
                  pathParameters: {'id': surveyor.id},
                  extra: surveyor,
                ).then((_) => widget.onProfileScreenClosed());
                widget.searchController.closeView(surveyor.surveyorNameEn);
              }
          ),
          noItemsFoundIndicatorBuilder: (_) => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No results found.'),
            ),
          ),
          firstPageErrorIndicatorBuilder: (_) => Center(
            child: Text('An error occurred: ${_pagingController.error}'),
          ),
        ),
      ),
    );
  }
}
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:find_a_surveyor/model/algolia_surveyor_model.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
import 'package:find_a_surveyor/utils/extension_util.dart';
import 'package:find_a_surveyor/widget/level_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class SearchResultsView extends StatefulWidget {
  final SearchController searchController;

  const SearchResultsView({super.key, required this.searchController});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  final _hitsSearcher = HitsSearcher(
    applicationID: 'QJ52WWP79Q',
    apiKey: 'b6a0f495786b4ce759df5b564d6f21b6',
    indexName: 'surveyors',
  );

  Stream<HitsPage> get _searchPage =>
      _hitsSearcher.responses.map(HitsPage.fromResponse);

  final PagingController<int, AlgoliaSurveyor> _pagingController =
  PagingController(firstPageKey: 0);

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
          itemBuilder: (context, surveyor, index) => ListTile(
            title: Text(surveyor.surveyorNameEn.toTitleCaseExt()),
            subtitle: Text('${surveyor.cityEn.toTitleCaseExt()}, ${surveyor.stateEn.toTitleCaseExt()}'),
            trailing: LevelChipWidget(level: surveyor.iiislaLevel),
            onTap: () {
              widget.searchController.closeView(surveyor.surveyorNameEn);
              context.pushNamed(AppRoutes.detail, pathParameters: {'id': surveyor.id});
            },
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
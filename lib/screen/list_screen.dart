import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_a_surveyor/model/surveyor_model.dart';
import 'package:find_a_surveyor/navigator/page/surveyor_page.dart';
import 'package:find_a_surveyor/navigator/router_config.dart';
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
  String? _error;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    _fetchSurveyors();
  }

  Future<void> _fetchSurveyors() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
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
          _error = "Failed to load data. Please check your connection.";
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

  Widget _buildBody() {
    if (_error != null && _surveyors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSurveyors,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_surveyors.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_surveyors.isEmpty && !_isLoading) {
      return const Center(child: Text('No surveyors found.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _surveyors.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _surveyors.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final surveyor = _surveyors[index];

        return InkWell(
          onTap: () {
            context.goNamed(
              AppRoutes.detail,
              pathParameters: {'id': surveyor.id},
            );
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  surveyor.surveyorNameEn.isNotEmpty
                      ? surveyor.surveyorNameEn[0]
                      : '?',
                ),
              ),
              title: Text(surveyor.surveyorNameEn),
              subtitle: Text('${surveyor.cityEn}, ${surveyor.stateEn}'),
              trailing: LevelChipWidget(level: surveyor.iiislaLevel),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find A Surveyor")),
      body: _buildBody(),
    );
  }
}

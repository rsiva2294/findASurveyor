
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';

class HitsPage {
  final List<AlgoliaSurveyor> items;
  final int pageKey;
  final bool isLastPage;

  HitsPage(this.items, this.pageKey, this.isLastPage);

  factory HitsPage.fromResponse(SearchResponse response) {
    final items = response.hits.map(AlgoliaSurveyor.fromAlgolia).toList();
    final isLastPage = response.page + 1 >= response.nbPages;
    return HitsPage(items, response.page, isLastPage);
  }
}

class AlgoliaSurveyor {
  final String id;
  final String surveyorNameEn;
  final String cityEn;
  final String stateEn;
  final String? iiislaLevel;

  AlgoliaSurveyor({
    required this.id,
    required this.surveyorNameEn,
    required this.cityEn,
    required this.stateEn,
    this.iiislaLevel,
  });

  factory AlgoliaSurveyor.fromAlgolia(Map<String, dynamic> json) {
    return AlgoliaSurveyor(
      id: json['objectID'] ?? '',
      surveyorNameEn: json['surveyor_name_en'] ?? 'No Name',
      cityEn: json['city_en'] ?? 'No City',
      stateEn: json['state_en'] ?? 'No State',
      iiislaLevel: json['iiisla_level'],
    );
  }
}
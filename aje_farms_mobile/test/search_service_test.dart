import 'package:flutter_test/flutter_test.dart';

import 'package:aje_farms_mobile/src/models/search_result.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';
import 'package:aje_farms_mobile/src/services/local_search_service.dart';
import 'package:aje_farms_mobile/src/services/search_service.dart';

void main() {
  const repository = DemoAppRepository();
  const service = LocalSearchService(
    learningRepository: repository,
    communityRepository: repository,
  );

  test('local search finds and ranks learning content', () async {
    final response = await service.search(
      const SearchRequest(query: 'nyanya', scope: SearchScope.learning),
    );

    expect(response.query, 'nyanya');
    expect(response.isOffline, isTrue);
    expect(response.results, isNotEmpty);
    expect(response.results.first.kind, SearchResultKind.course);
    expect(response.results.first.id, 'nyanya');
  });

  test('local search tolerates a one-word typo and respects scope', () async {
    final typo = await service.search(
      const SearchRequest(query: 'nyaynya', scope: SearchScope.learning),
    );
    expect(typo.results.first.id, 'nyanya');

    final community = await service.search(
      const SearchRequest(query: 'jamii', scope: SearchScope.community),
    );
    expect(
      community.results.every(
        (result) => result.kind == SearchResultKind.community,
      ),
      isTrue,
    );
  });

  test('local search validates query and result limits', () async {
    await expectLater(
      service.search(const SearchRequest(query: 'x')),
      throwsA(isA<SearchException>()),
    );
    await expectLater(
      service.search(const SearchRequest(query: 'mpunga', limit: 51)),
      throwsA(isA<SearchException>()),
    );
  });
}

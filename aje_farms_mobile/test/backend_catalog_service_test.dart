import 'dart:async';

import 'package:aje_farms_mobile/src/repositories/cached_app_repository.dart';
import 'package:aje_farms_mobile/src/repositories/demo_app_repository.dart';
import 'package:aje_farms_mobile/src/services/backend_catalog_service.dart';
import 'package:aje_farms_mobile/src/services/backend_session_storage.dart';
import 'package:aje_farms_mobile/src/services/catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() async {
    await BackendSessionStorage.writeToken('catalog-test-token');
  });

  // The catalog feed is what the community tab renders after any refresh or
  // restart. Dropping imageUrl here left posts with hasImage: true and no URL,
  // so an uploaded photo showed once and then became a grey placeholder — the
  // "my picture disappeared" report. The community service parser kept the
  // field, which is why the photo looked fine until the first refresh.
  test('keeps the community photo URL when loading the catalog feed', () async {
    final service = BackendCatalogService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async => http.Response(_catalogJson, 200)),
    );

    final catalog = await service.loadCatalog();
    final post = catalog.communityPosts.single;

    expect(post.hasImage, isTrue);
    expect(post.imageUrl, 'https://cdn.example.test/community/photo.jpg');
  });

  test('loads catalog data from backend and maps wire fields', () async {
    late http.Request capturedRequest;
    final service = BackendCatalogService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(_catalogJson, 200);
      }),
    );

    final catalog = await service.loadCatalog();

    expect(
      capturedRequest.url.toString(),
      'http://localhost:3000/api/catalog',
    );
    expect(
        capturedRequest.headers['Authorization'], 'Bearer catalog-test-token');
    expect(catalog.courses.single.id, 'pilipili');
    expect(catalog.documents.single.id, 'pilipili-mwongozo');
    expect(catalog.courses.single.icon, Icons.grass);
    expect(
      catalog.courses.single.lessons.map((lesson) => lesson.type.name),
      ['video', 'reading'],
    );
    expect(
      catalog.courses.single.lessons.first.resourceUrl,
      'http://localhost:3000/api/lessons/video-1/video',
    );
    expect(catalog.courses.single.lessons.first.sourceTitle, 'Video ya AJE');
    expect(catalog.problemCategories.single.color, const Color(0xFFE15241));
    expect(catalog.communityPosts.single.replies.single.isExpert, isTrue);
    expect(catalog.plans.single.recommended, isTrue);
    expect(
      catalog.homeTopics,
      ['Matunda na Mbogamboga', 'Nafaka', 'Mifugo', 'Mengineyo'],
    );
  });

  test('cached repository keeps fallback then notifies after refresh',
      () async {
    const fallback = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: fallback,
      communitySeed: fallback,
      subscriptionSeed: fallback,
    );
    var notifications = 0;
    repository.addListener(() => notifications++);

    expect(repository.courses.first.id, 'pasheni');

    await repository.refresh(_FakeCatalogService());

    expect(notifications, 2);
    expect(repository.courses.single.id, 'pilipili');
    expect(repository.problemCategories.single.title, 'Magonjwa');
    expect(repository.plans.single.title, 'Mwaka 1');
  });

  test('cached repository accepts an empty reviewed course catalogue',
      () async {
    const fallback = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: fallback,
      communitySeed: fallback,
      subscriptionSeed: fallback,
    );

    await repository.refresh(_EmptyCourseCatalogService());

    expect(repository.courses, isEmpty);
    expect(repository.featuredCourse, isNull);
    expect(repository.suggestedCourse, isNull);
    expect(repository.lastRefreshFailed, isFalse);
  });

  test('failed refresh discards previously unlocked learning content',
      () async {
    const unlockedCatalog = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: unlockedCatalog,
      communitySeed: unlockedCatalog,
      subscriptionSeed: unlockedCatalog,
    );
    await repository.refresh(_FakeCatalogService());

    expect(repository.courses, isNotEmpty);
    expect(repository.documents, isNotEmpty);
    expect(
      repository.courses
          .expand((course) => course.lessons)
          .any((lesson) => !lesson.isPremium),
      isTrue,
    );

    await repository.refresh(_FailingCatalogService());

    expect(repository.lastRefreshFailed, isTrue);
    expect(repository.courses, isEmpty);
    expect(repository.documents, isEmpty);
    expect(repository.problemCategories, isNotEmpty);
    expect(repository.posts, isNotEmpty);
    expect(repository.plans, isNotEmpty);
  });

  test('account boundary clears protected content but keeps public metadata',
      () async {
    const seed = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: seed,
      communitySeed: seed,
      subscriptionSeed: seed,
    );
    await repository.refresh(_FakeCatalogService());

    repository.clearProtectedContent();

    expect(repository.courses, isEmpty);
    expect(repository.documents, isEmpty);
    expect(repository.isInitialLoadPending, isFalse);
    expect(repository.lastRefreshFailed, isFalse);
    expect(repository.problemCategories, isNotEmpty);
    expect(repository.posts, isNotEmpty);
    expect(repository.plans, isNotEmpty);
  });

  test('account boundary invalidates an in-flight unlocked catalog response',
      () async {
    const seed = DemoAppRepository();
    final repository = CachedAppRepository(
      learningSeed: seed,
      communitySeed: seed,
      subscriptionSeed: seed,
    );
    final unlockedSnapshot = await _FakeCatalogService().loadCatalog();
    final deferredService = _DeferredCatalogService();

    final refresh = repository.refresh(deferredService);
    expect(repository.isRefreshing, isTrue);

    repository.clearProtectedContent();
    deferredService.complete(unlockedSnapshot);
    await refresh;

    expect(repository.isRefreshing, isFalse);
    expect(repository.courses, isEmpty);
    expect(repository.documents, isEmpty);
  });
}

class _FakeCatalogService implements CatalogService {
  @override
  Future<String> lessonVideoUrl(String lessonId) async =>
      'https://example.test/v';

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    final service = BackendCatalogService(
      baseUrl: Uri.parse('http://localhost:3000'),
      client: MockClient((_) async => http.Response(_catalogJson, 200)),
    );
    return service.loadCatalog();
  }
}

class _EmptyCourseCatalogService implements CatalogService {
  @override
  Future<String> lessonVideoUrl(String lessonId) async =>
      'https://example.test/v';

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    final snapshot = await _FakeCatalogService().loadCatalog();
    return CatalogSnapshot(
      homeTopics: snapshot.homeTopics,
      courses: const [],
      documents: const [],
      problemCategories: snapshot.problemCategories,
      communityPosts: snapshot.communityPosts,
      plans: snapshot.plans,
    );
  }
}

class _FailingCatalogService implements CatalogService {
  @override
  Future<String> lessonVideoUrl(String lessonId) async =>
      'https://example.test/v';

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    throw const CatalogException('Authentication required.');
  }
}

class _DeferredCatalogService implements CatalogService {
  final _snapshot = Completer<CatalogSnapshot>();

  void complete(CatalogSnapshot snapshot) => _snapshot.complete(snapshot);

  @override
  Future<String> lessonVideoUrl(String lessonId) async =>
      'https://example.test/v';

  @override
  Future<CatalogSnapshot> loadCatalog() => _snapshot.future;
}

const _catalogJson = '''
{
  "homeTopics": [
    "Matunda na Mbogamboga",
    "Nafaka",
    "Mifugo",
    "Mengineyo"
  ],
  "courses": [
    {
      "id": "pilipili",
      "title": "Kilimo cha Pilipili",
      "description": "Mbegu, matunzo, magonjwa na soko.",
      "badge": "Mpya",
      "icon": "grass",
      "progress": 0.25,
      "imageUrl": "https://example.com/pilipili.jpg",
      "outcomes": ["Chagua mbegu bora"],
      "lessons": [
        {
          "id": "video-1",
          "title": "Video ya utangulizi",
          "type": "video",
          "meta": "Dakika 5",
          "description": "Tazama video.",
          "sourceTitle": "Video ya AJE",
          "resourceUrl": "/api/lessons/video-1/video",
          "isPremium": false
        },
        {
          "title": "Somo la kusoma",
          "type": "reading",
          "meta": "Dakika 5",
          "description": "Soma maelezo.",
          "sourceTitle": "Kitabu cha Pilipili, ukurasa 12",
          "isPremium": false
        }
      ]
    }
  ],
  "documents": [
    {
      "id": "pilipili-mwongozo",
      "title": "Mwongozo wa pilipili",
      "courseId": "pilipili",
      "courseTitle": "Kilimo cha Pilipili",
      "description": "Pakua mwongozo.",
      "type": "pdf",
      "sizeLabel": "1 MB",
      "isPremium": true
    }
  ],
  "problemCategories": [
    {
      "title": "Magonjwa",
      "topic": "Magonjwa ya mimea",
      "icon": "spa",
      "color": "#E15241",
      "summary": "Dalili za magonjwa.",
      "examples": ["Majani njano"]
    }
  ],
  "communityPosts": [
    {
      "id": "post-remote",
      "author": "AJE",
      "location": "Arusha",
      "time": "Leo",
      "content": "Angalizo la bei ya mazao leo.",
      "likes": 3,
      "comments": 1,
      "tags": ["Masoko"],
      "replies": [
        {
          "author": "Mtaalamu AJE",
          "body": "Fuata ubora wa madaraja.",
          "time": "Leo",
          "isExpert": true
        }
      ],
      "isExpert": true,
      "hasImage": true,
      "imageUrl": "https://cdn.example.test/community/photo.jpg"
    }
  ],
  "plans": [
    {
      "title": "Mwaka 1",
      "subtitle": "Ufikiaji wa mwaka",
      "price": "TZS 90,000",
      "icon": "star",
      "recommended": true
    }
  ]
}
''';

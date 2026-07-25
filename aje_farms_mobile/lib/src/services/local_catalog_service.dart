import 'catalog_service.dart';

/// Demo-mode catalog service. Demo builds serve a bundled catalog through
/// [DemoAppRepository], so nothing here talks to a backend.
class LocalCatalogService implements CatalogService {
  const LocalCatalogService();

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    throw const CatalogException(
      'Catalog refresh requires a connected backend.',
    );
  }

  @override
  Future<String> lessonVideoUrl(String lessonId) async {
    throw const CatalogException(
      'Video inahitaji muunganisho wa mtandao.',
    );
  }
}

import 'app_photo.dart';

export 'app_photo.dart';

/// Backward-compatible alias for [AppPhoto].
class NetworkPhoto extends AppPhoto {
  const NetworkPhoto({required String url, super.key}) : super(source: url);
}

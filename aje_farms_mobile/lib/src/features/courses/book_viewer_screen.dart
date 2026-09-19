import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/snack.dart';
import '../../theme/app_theme.dart';

typedef BookViewerBuilder = Widget Function(Uri sourceUri);
typedef BookUrlRefresher = Future<String> Function();

class BookViewerScreen extends StatefulWidget {
  const BookViewerScreen({
    required this.title,
    required this.sourceUrl,
    this.viewerBuilder,
    this.onRefreshUrl,
    super.key,
  });

  final String title;
  final String sourceUrl;
  final BookViewerBuilder? viewerBuilder;
  final BookUrlRefresher? onRefreshUrl;

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  int? _pageNumber;
  int? _pageCount;
  late String _sourceUrl;
  var _viewerRevision = 0;
  var _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _sourceUrl = widget.sourceUrl;
  }

  @override
  Widget build(BuildContext context) {
    final sourceUri = _validSourceUri(_sourceUrl);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (sourceUri != null)
            IconButton(
              tooltip: 'Fungua kwa programu nyingine',
              onPressed: () => _openExternally(sourceUri),
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
      body: sourceUri == null
          ? const _BookLoadError()
          : widget.viewerBuilder?.call(sourceUri) ?? _buildViewer(sourceUri),
      bottomNavigationBar: _pageNumber == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  _pageCount == null
                      ? 'Ukurasa $_pageNumber'
                      : 'Ukurasa $_pageNumber kati ya $_pageCount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
    );
  }

  Widget _buildViewer(Uri sourceUri) {
    return PdfViewer.uri(
      sourceUri,
      key: ValueKey((sourceUri, _viewerRevision)),
      useProgressiveLoading: true,
      preferRangeAccess: true,
      params: PdfViewerParams(
        // Keep memory use predictable on low-end Android devices while pages
        // are progressively rendered and recycled.
        limitRenderingCache: true,
        maxImageBytesCachedOnMemory: 48 * 1024 * 1024,
        verticalCacheExtent: 0.5,
        backgroundColor: context.colors.background,
        onViewerReady: (_, controller) {
          if (!mounted) return;
          setState(() {
            _pageNumber = controller.pageNumber ?? 1;
            _pageCount = controller.pageCount;
          });
        },
        onPageChanged: (pageNumber) {
          if (!mounted || pageNumber == null || pageNumber == _pageNumber) {
            return;
          }
          setState(() => _pageNumber = pageNumber);
        },
        loadingBannerBuilder: (context, downloadedBytes, totalBytes) {
          final progress = totalBytes == null || totalBytes == 0
              ? null
              : downloadedBytes / totalBytes;
          return Center(
            child: Semantics(
              label: 'Inapakia kitabu',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: progress),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Inapakia kurasa za kitabu…'),
                ],
              ),
            ),
          );
        },
        errorBannerBuilder: (context, _, __, ___) => _BookLoadError(
          isRetrying: _isRetrying,
          onRetry: _retry,
          onOpenExternally: () => _openExternally(sourceUri),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final refreshedUrl = await widget.onRefreshUrl?.call();
      if (refreshedUrl != null && _validSourceUri(refreshedUrl) == null) {
        throw const FormatException('Invalid refreshed book URL');
      }
      if (!mounted) return;
      setState(() {
        if (refreshedUrl != null) _sourceUrl = refreshedUrl;
        _viewerRevision++;
        _isRetrying = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRetrying = false);
      showSnack(context, 'Kitabu hakikuweza kupakiwa. Kagua mtandao wako.');
    }
  }

  Future<void> _openExternally(Uri sourceUri) async {
    if (!await launchUrl(sourceUri, mode: LaunchMode.externalApplication) &&
        mounted) {
      showSnack(context, 'Kitabu hakikuweza kufunguka. Jaribu tena baadaye.');
    }
  }
}

Uri? _validSourceUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      !const {'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}

class _BookLoadError extends StatelessWidget {
  const _BookLoadError({
    this.isRetrying = false,
    this.onRetry,
    this.onOpenExternally,
  });

  final bool isRetrying;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenExternally;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 44, color: context.colors.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kitabu hakikuweza kupakiwa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: isRetrying ? null : onRetry,
                icon: isRetrying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isRetrying ? 'Inajaribu tena…' : 'Jaribu tena'),
              ),
            ],
            if (onOpenExternally != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onOpenExternally,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Fungua kwa programu nyingine'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

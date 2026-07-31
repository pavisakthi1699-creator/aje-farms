import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_radius.dart';
import 'loading_skeleton.dart';

/// Renders bundled assets or remote URLs for course and hero imagery.
class AppPhoto extends StatefulWidget {
  const AppPhoto({required this.source, super.key});

  final String source;

  @override
  State<AppPhoto> createState() => _AppPhotoState();
}

class _AppPhotoState extends State<AppPhoto> {
  bool get _isAsset => widget.source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return Image.asset(
        widget.source,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${widget.source}-$_retry'),
      imageUrl: widget.source,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(color: context.colors.primaryContainer, child: const Center(child: LoadingSkeleton(width: 72, height: 72, borderRadius: AppRadius.xl))),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return InkWell(
      onTap: () async {
        await CachedNetworkImage.evictFromCache(widget.source);
        if (mounted) setState(() => _retry++);
      },
      child: Container(
      color: context.colors.primaryContainer,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.broken_image_outlined, color: context.colors.primary, size: 44),
        const SizedBox(height: 6),
        Text('Picha haijapatikana. Gusa ujaribu tena.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
      ]),
      ),
    );
  }

  var _retry = 0;
}

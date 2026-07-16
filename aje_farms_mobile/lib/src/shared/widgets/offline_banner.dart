import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_spacing.dart';
import 'connectivity_scope.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    this.showCatalogStale = false,
    super.key,
  });

  final bool showCatalogStale;

  @override
  Widget build(BuildContext context) {
    final offline = !context.isDeviceOnline;
    if (!offline && !showCatalogStale) {
      return const SizedBox.shrink();
    }

    final message = offline
        ? 'Huna mtandao. Unaweza kuendelea na maudhui yaliyohifadhiwa.'
        : 'Imeshindikana kusasisha maudhui mapya. Unaona taarifa za hivi karibuni.';

    final surfaceColor =
        offline ? context.colors.surfacePeach : context.colors.surfaceMuted;
    final iconColor =
        offline ? context.colors.secondary : context.colors.primary;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
        color: surfaceColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppDecorations.pastelPanel(
                      context, context.colors.surface),
                  child: Icon(
                    offline ? Icons.wifi_off : Icons.cloud_off_outlined,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

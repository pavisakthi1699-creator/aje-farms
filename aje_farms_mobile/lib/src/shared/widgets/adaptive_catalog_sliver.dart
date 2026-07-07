import 'package:flutter/material.dart';

import '../../theme/app_breakpoints.dart';
import '../../theme/app_spacing.dart';

/// Lazy list on narrow windows; two-column grid on expanded widths.
class AdaptiveCatalogSliver extends StatelessWidget {
  const AdaptiveCatalogSliver({
    required this.itemCount,
    required this.itemBuilder,
    required this.padding,
    this.listItemSpacing = AppSpacing.xl,
    this.gridMaxCrossAxisExtent = 360,
    this.gridMainAxisExtent = 480,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;
  final double listItemSpacing;
  final double gridMaxCrossAxisExtent;
  final double gridMainAxisExtent;

  @override
  Widget build(BuildContext context) {
    final useGrid = AppBreakpoints.isExpanded(context);

    return SliverPadding(
      padding: padding,
      sliver: useGrid
          ? SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: gridMaxCrossAxisExtent,
                mainAxisSpacing: listItemSpacing,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisExtent: gridMainAxisExtent,
              ),
              delegate: SliverChildBuilderDelegate(
                itemBuilder,
                childCount: itemCount,
              ),
            )
          : SliverList.builder(
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: listItemSpacing),
                  child: itemBuilder(context, index),
                );
              },
            ),
    );
  }
}

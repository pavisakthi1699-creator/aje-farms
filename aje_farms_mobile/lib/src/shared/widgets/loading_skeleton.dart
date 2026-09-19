import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.md,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<LoadingSkeleton> createState() => LoadingSkeletonState();
}

class LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduceMotionOf(context);
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
      return;
    }
    if (_controller != null) {
      return;
    }
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeleton,
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = _controller;
    if (controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + (controller.value * 2.4), 0),
              end: Alignment(0.2 + (controller.value * 2.4), 0),
              colors: [
                colors.surfaceMuted,
                Color.lerp(colors.surfaceMuted, colors.primary, 0.12)!,
                colors.surface,
                Color.lerp(colors.surfaceMuted, colors.primary, 0.12)!,
                colors.surfaceMuted,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class CourseCatalogSkeleton extends StatelessWidget {
  const CourseCatalogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingSkeleton(height: 34, borderRadius: AppRadius.sm),
        const SizedBox(height: AppSpacing.md),
        const LoadingSkeleton(height: 18, width: 260),
        const SizedBox(height: AppSpacing.xxl),
        Card(
          color: context.colors.surfaceLavender,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                LoadingSkeleton(width: 48, height: 48, borderRadius: 24),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(height: 16),
                      SizedBox(height: AppSpacing.sm),
                      LoadingSkeleton(height: 14, width: 180),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var index = 0; index < 2; index += 1) ...[
          const Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  height: 190,
                  borderRadius: AppRadius.xl,
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(height: 22),
                      SizedBox(height: AppSpacing.sm),
                      LoadingSkeleton(height: 14),
                      SizedBox(height: AppSpacing.sm),
                      LoadingSkeleton(height: 14, width: 220),
                      SizedBox(height: AppSpacing.lg),
                      LoadingSkeleton(height: 8, borderRadius: AppRadius.pill),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class CommunityFeedSkeleton extends StatelessWidget {
  const CommunityFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: context.colors.surfaceMuted,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 18, width: 160),
                SizedBox(height: AppSpacing.sm),
                LoadingSkeleton(height: 14, width: 240),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          children: [
            LoadingSkeleton(
                width: 72, height: 34, borderRadius: AppRadius.pill),
            SizedBox(width: AppSpacing.sm),
            LoadingSkeleton(
                width: 88, height: 34, borderRadius: AppRadius.pill),
            SizedBox(width: AppSpacing.sm),
            LoadingSkeleton(
                width: 72, height: 34, borderRadius: AppRadius.pill),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var index = 0; index < 3; index += 1)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(height: 16, width: 120),
                    SizedBox(height: AppSpacing.sm),
                    LoadingSkeleton(height: 14),
                    SizedBox(height: AppSpacing.sm),
                    LoadingSkeleton(height: 14, width: 200),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

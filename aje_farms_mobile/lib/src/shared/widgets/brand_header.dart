// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class BrandHeader extends StatelessWidget {
  const BrandHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 48.0;
    return Semantics(
      header: !compact,
      label: 'Chuo Kikuu Cha Mtaani',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: size,
              height: size,
              decoration: AppDecorations.circleIconButton(context),
              child: Center(
                child: BrandMark(size: compact ? 26 : 30),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              'Chuo Kikuu Cha Mtaani',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 18 : 22,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

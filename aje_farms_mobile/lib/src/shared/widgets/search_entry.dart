import '../../ui.dart';

class SearchActionButton extends StatelessWidget {
  const SearchActionButton({
    this.scope = SearchScope.all,
    super.key,
  });

  final SearchScope scope;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tr('Tafuta'),
      icon: const Icon(Icons.search),
      onPressed: () => AppNavigator.pushSearch(context, scope: scope),
    );
  }
}

class ContextualSearchBar extends StatelessWidget {
  const ContextualSearchBar({
    required this.hint,
    required this.scope,
    super.key,
  });

  final String hint;
  final SearchScope scope;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hint,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppNavigator.pushSearch(context, scope: scope),
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.colors.surfaceMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

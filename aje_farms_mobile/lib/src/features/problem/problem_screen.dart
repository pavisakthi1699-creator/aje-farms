// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class ProblemScreen extends StatefulWidget {
  const ProblemScreen({this.initialTopic, super.key});

  final String? initialTopic;

  @override
  State<ProblemScreen> createState() => ProblemScreenState();
}

class ProblemScreenState extends State<ProblemScreen> {
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, ProblemCategory category) {
    AppFeedback.tap();
    final detail = _detailController.text.trim();
    final prompt = detail.isEmpty
        ? tr('Nina shida kuhusu {topic}. Naweza kupata ushauri?', {
            'topic': tr(category.topic),
          })
        : tr(
            'Nina shida kuhusu {topic}. Zao/mnyama: {detail}. Naweza kupata ushauri?',
            {'topic': tr(category.topic), 'detail': detail},
          );

    AppNavigator.pushAiChat(
      context,
      initialPromptTopic: tr(category.topic),
      initialPromptDetail: detail.isEmpty ? null : detail,
      initialPrompt: prompt,
    );
  }

  void _openUnknownProblem(BuildContext context) {
    AppFeedback.tap();
    final detail = _detailController.text.trim();
    final prompt = detail.isEmpty
        ? tr(
            'Sijui tatizo kwenye shamba langu. Nisaidie kuuliza maswali ya kutambua.',
          )
        : tr(
            'Sijui tatizo kwenye {detail}. Nisaidie kuuliza maswali ya kutambua.',
            {'detail': detail},
          );

    AppNavigator.pushAiChat(
      context,
      initialPromptTopic: tr('Sijui tatizo'),
      initialPromptDetail: detail.isEmpty ? null : detail,
      initialPrompt: prompt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final learningRepository = context.dependencies.learningRepository;
    final problemCategories = learningRepository.problemCategories;
    final suggestedCourse = learningRepository.suggestedCourse;
    final selectedCategory = problemCategories
        .where((category) => category.topic == widget.initialTopic)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Tueleze Changamoto'))),
      body: AppLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              tr('Eleza tatizo'),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tr('Una changamoto gani leo kwenye shamba lako?'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (selectedCategory != null) ...[
              Semantics(
                liveRegion: true,
                child: Card(
                  color: context.colors.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      selectedCategory.icon,
                      color: context.colors.primary,
                    ),
                    title: Text(tr('Changamoto uliyochagua')),
                    subtitle: Text(tr(selectedCategory.title)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              controller: _detailController,
              labelText: tr('Zao au mnyama (hiari)'),
              hintText: tr('Mfano: nyanya, pasheni, kuku wa nyama'),
              prefixIcon: const Icon(Icons.agriculture_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: problemCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final category = problemCategories[index];
                return ProblemCategoryTile(
                  key: ValueKey('problem-category-${category.topic}'),
                  category: category,
                  onTap: () => _openChat(context, category),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            UnknownProblemTile(onTap: () => _openUnknownProblem(context)),
            if (suggestedCourse != null) ...[
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                tr('Mada Pendekezwa'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: InteractiveInk(
                  borderRadius: AppRadius.lg,
                  onTap: () => AppNavigator.pushCourse(
                    context,
                    suggestedCourse,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.colors.primaryContainer,
                          child: Icon(Icons.spa, color: context.colors.primary),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestedCourse.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                suggestedCourse.badge,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: context.colors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        ExcludeSemantics(
                          child: Icon(Icons.chevron_right,
                              color: context.colors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

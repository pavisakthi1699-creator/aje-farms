// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class ProblemScreen extends StatefulWidget {
  const ProblemScreen({super.key});

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
    final detail = _detailController.text.trim();
    final prompt = detail.isEmpty
        ? 'Nina shida kuhusu ${category.topic}. Naweza kupata ushauri?'
        : 'Nina shida kuhusu ${category.topic}. Zao/mnyama: $detail. Naweza kupata ushauri?';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          initialPromptTopic: category.topic,
          initialPromptDetail: detail.isEmpty ? null : detail,
          initialPrompt: prompt,
        ),
      ),
    );
  }

  void _openUnknownProblem(BuildContext context) {
    final detail = _detailController.text.trim();
    final prompt = detail.isEmpty
        ? 'Sijui tatizo kwenye shamba langu. Nisaidie kuuliza maswali ya kutambua.'
        : 'Sijui tatizo kwenye $detail. Nisaidie kuuliza maswali ya kutambua.';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          initialPromptTopic: 'Sijui tatizo',
          initialPromptDetail: detail.isEmpty ? null : detail,
          initialPrompt: prompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final learningRepository = context.dependencies.learningRepository;
    final problemCategories = learningRepository.problemCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('Tueleze Changamoto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Eleza Tatizo',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Una changamoto gani leo kwenye shamba lako?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _detailController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Zao au mnyama (hiari)',
              hintText: 'Mfano: nyanya, pasheni, kuku wa nyama',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.agriculture_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: problemCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
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
          const SizedBox(height: 14),
          UnknownProblemTile(onTap: () => _openUnknownProblem(context)),
          const SizedBox(height: 28),
          Text('Mada Pengekezi',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            leading: const CircleAvatar(
              backgroundColor: AppColors.blue,
              child: Icon(Icons.spa, color: AppColors.primary),
            ),
            title: const Text('Kuzuia Ukungu kwenye Nyanya'),
            subtitle: const Text('Dakika 3 kusoma'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(
                      course: learningRepository.suggestedCourse)),
            ),
          ),
        ],
      ),
    );
  }
}

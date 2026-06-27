part of '../../app.dart';

class ProblemScreen extends StatelessWidget {
  const ProblemScreen({super.key});

  void _openChat(BuildContext context, String topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => AiChatScreen(initialPromptTopic: topic)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _demoRepository.problemCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final category = _demoRepository.problemCategories[index];
              return _ProblemCategoryTile(
                category: category,
                onTap: () => _openChat(context, category.topic),
              );
            },
          ),
          const SizedBox(height: 14),
          _UnknownProblemTile(onTap: () => _openChat(context, 'Sijui tatizo')),
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
                      course: _demoRepository.suggestedCourse)),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: use_key_in_widget_constructors

import '../../ui.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = context.dependencies.learningRepository.courses;

    return Scaffold(
      appBar: AppBar(title: const Text('Mafunzo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chagua Mada.\nJifunze Kilimo.',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800, height: 1.05),
          ),
          const SizedBox(height: 8),
          Text(
            'Chagua kozi hapa chini ili kuongeza tija kwenye shamba lako leo.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          LearningSummaryCard(courses: courses),
          const SizedBox(height: 16),
          ...courses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: CourseCard(course: course),
            ),
          ),
        ],
      ),
    );
  }
}

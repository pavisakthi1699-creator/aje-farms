import 'package:flutter/material.dart';

enum DemoLessonType {
  video('Video', Icons.play_circle_outline),
  pdf('PDF', Icons.picture_as_pdf_outlined),
  quiz('Tathmini', Icons.quiz_outlined);

  const DemoLessonType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class DemoLesson {
  const DemoLesson({
    required this.title,
    required this.type,
    required this.meta,
    this.isPremium = false,
  });

  final String title;
  final DemoLessonType type;
  final String meta;
  final bool isPremium;
}

class DemoCourse {
  const DemoCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.progress,
    required this.imageUrl,
    required this.outcomes,
    required this.lessons,
  });

  final String id;
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final double progress;
  final String imageUrl;
  final List<String> outcomes;
  final List<DemoLesson> lessons;
}

class ProblemCategory {
  const ProblemCategory({
    required this.title,
    required this.topic,
    required this.icon,
    required this.color,
  });

  final String title;
  final String topic;
  final IconData icon;
  final Color color;
}

class CommunityPost {
  const CommunityPost({
    required this.author,
    required this.location,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    this.relatedTopic,
    this.hasImage = false,
  });

  final String author;
  final String location;
  final String time;
  final String content;
  final int likes;
  final int comments;
  final String? relatedTopic;
  final bool hasImage;
}

class PlanOption {
  const PlanOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.icon,
    this.recommended = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final bool recommended;
}

const knowledgeBase = '''
TAARIFA ZILIZOIDHINISHWA:

Kilimo cha Pasheni:
- Pasheni inahitaji udongo unaopitisha maji vizuri.
- Eneo lisituamishe maji kwa sababu mizizi inaweza kuoza.
- Shamba linahitaji maandalizi mazuri kabla ya kupanda.
- Tumia nguzo na waya kusaidia mmea kupanda vizuri.
- Matunzo muhimu ni kumwagilia kwa mpangilio, kupalilia, na kufuatilia wadudu.

Ufugaji wa Kuku:
- Kuku wanahitaji banda lenye hewa ya kutosha, usafi na ulinzi.
- Chanjo ni muhimu katika kupunguza magonjwa.
- Chakula bora na maji safi vinasaidia ukuaji mzuri.

Kilimo cha Nyanya:
- Nyanya zinahitaji kitalu bora kabla ya kuhamishia miche shambani.
- Udongo uwe na rutuba na usiotuamisha maji.
- Matunzo ni kumwagilia, kuweka mbolea, na kudhibiti wadudu.
''';

const demoCourses = [
  DemoCourse(
    id: 'pasheni',
    title: 'Kilimo cha Pasheni',
    description:
        'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.',
    badge: 'Maarufu',
    icon: Icons.local_florist,
    progress: 0.65,
    imageUrl:
        'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?auto=format&fit=crop&w=900&q=80',
    outcomes: [
      'Kuchagua eneo sahihi',
      'Kuandaa shamba kabla ya kupanda',
      'Kutambua changamoto za mwanzo',
      'Kujua hatua za matunzo',
    ],
    lessons: [
      DemoLesson(
          title: 'Maandalizi ya shamba',
          type: DemoLessonType.video,
          meta: 'DKK 5'),
      DemoLesson(
          title: 'Mwongozo mfupi wa pasheni',
          type: DemoLessonType.pdf,
          meta: '2 MB'),
      DemoLesson(
          title: 'Jaribio la maarifa',
          type: DemoLessonType.quiz,
          meta: 'Maswali 10',
          isPremium: true),
    ],
  ),
  DemoCourse(
    id: 'kuku',
    title: 'Ufugaji wa Kuku',
    description: 'Nyumba bora, chakula, chanjo, usafi na biashara ya kuku.',
    badge: 'Inafaa kwa wanaoanza',
    icon: Icons.egg_alt,
    progress: 0,
    imageUrl:
        'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=900&q=80',
    outcomes: [
      'Kujenga banda lenye hewa na usalama',
      'Kupanga ratiba ya chanjo',
      'Kuchagua chakula bora',
      'Kupunguza hatari ya magonjwa',
    ],
    lessons: [
      DemoLesson(
          title: 'Misingi ya ufugaji wa kuku',
          type: DemoLessonType.video,
          meta: 'DKK 6'),
      DemoLesson(
          title: 'Ratiba ya chanjo', type: DemoLessonType.pdf, meta: '1 MB'),
      DemoLesson(
          title: 'Biashara ya kuku',
          type: DemoLessonType.quiz,
          meta: 'Premium',
          isPremium: true),
    ],
  ),
  DemoCourse(
    id: 'nyanya',
    title: 'Kilimo cha Nyanya',
    description:
        'Kitalu, upandaji, mbolea, udhibiti wa wadudu na maandalizi ya soko.',
    badge: 'Kozi mpya',
    icon: Icons.grass,
    progress: 0,
    imageUrl:
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=900&q=80',
    outcomes: [
      'Kuandaa kitalu bora',
      'Kuhamisha miche yenye afya',
      'Kutumia mbolea kwa wakati',
      'Kudhibiti wadudu na magonjwa',
    ],
    lessons: [
      DemoLesson(
          title: 'Kuandaa kitalu', type: DemoLessonType.video, meta: 'DKK 4'),
      DemoLesson(
          title: 'Udhibiti wa wadudu', type: DemoLessonType.pdf, meta: '2 MB'),
      DemoLesson(
          title: 'Maandalizi ya soko',
          type: DemoLessonType.quiz,
          meta: 'Premium',
          isPremium: true),
    ],
  ),
];

const problemCategories = [
  ProblemCategory(
      title: 'Magonjwa ya mimea',
      topic: 'Magonjwa ya mimea',
      icon: Icons.spa,
      color: Color(0xFFE15241)),
  ProblemCategory(
      title: 'Wadudu na Visumbufu',
      topic: 'Wadudu',
      icon: Icons.bug_report,
      color: Color(0xFFE07A2F)),
  ProblemCategory(
      title: 'Mbolea na Udongo',
      topic: 'Mbolea',
      icon: Icons.eco,
      color: Color(0xFF188C5B)),
  ProblemCategory(
      title: 'Maji / Umwagiliaji',
      topic: 'Maji na Umwagiliaji',
      icon: Icons.water_drop,
      color: Color(0xFF2F7DE1)),
  ProblemCategory(
      title: 'Soko na Bei',
      topic: 'Soko',
      icon: Icons.trending_up,
      color: Color(0xFFD5961B)),
  ProblemCategory(
      title: 'Ufugaji',
      topic: 'Ufugaji',
      icon: Icons.handshake,
      color: Color(0xFFC85A3C)),
];

const communityPosts = [
  CommunityPost(
    author: 'Joseph M.',
    location: 'Morogoro',
    time: 'Saa 2 zilizopita',
    content: 'Naomba ushauri, majani ya pasheni yangu yanabadilika rangi.',
    likes: 12,
    comments: 4,
    hasImage: true,
  ),
  CommunityPost(
    author: 'Mama Asha',
    location: 'Mbeya',
    time: 'Saa 5 zilizopita',
    content: 'Natafuta mwongozo wa kuanza ufugaji wa kuku wa nyama.',
    relatedTopic: 'Ufugaji wa Kuku',
    likes: 34,
    comments: 8,
  ),
];

const planOptions = [
  PlanOption(
      title: 'Wiki 1',
      subtitle: 'Ufikiaji wa haraka',
      price: 'TZS 3,000',
      icon: Icons.calendar_month),
  PlanOption(
      title: 'Mwezi 1',
      subtitle: 'Thamani bora zaidi',
      price: 'TZS 10,000',
      icon: Icons.star,
      recommended: true),
  PlanOption(
      title: 'Kozi Maalum',
      subtitle: 'Utaalamu wa kina',
      price: 'TZS 50,000',
      icon: Icons.menu_book),
];

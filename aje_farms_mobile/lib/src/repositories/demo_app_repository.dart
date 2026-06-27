import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';
import 'community_repository.dart';
import 'learning_repository.dart';
import 'subscription_repository.dart';

class DemoAppRepository
    implements LearningRepository, CommunityRepository, SubscriptionRepository {
  const DemoAppRepository();

  @override
  List<Course> get courses => _courses;

  @override
  List<ProblemCategory> get problemCategories => _problemCategories;

  @override
  List<CommunityPost> get posts => _communityPosts;

  @override
  List<PlanOption> get plans => _plans;

  @override
  Course get featuredCourse => _courses.first;

  @override
  Course get suggestedCourse => _courses.last;
}

const _courses = [
  Course(
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
      Lesson(
          title: 'Maandalizi ya shamba', type: LessonType.video, meta: 'DKK 5'),
      Lesson(
          title: 'Mwongozo mfupi wa pasheni',
          type: LessonType.pdf,
          meta: '2 MB'),
      Lesson(
        title: 'Jaribio la maarifa',
        type: LessonType.quiz,
        meta: 'Maswali 10',
        isPremium: true,
      ),
    ],
  ),
  Course(
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
      Lesson(
          title: 'Misingi ya ufugaji wa kuku',
          type: LessonType.video,
          meta: 'DKK 6'),
      Lesson(title: 'Ratiba ya chanjo', type: LessonType.pdf, meta: '1 MB'),
      Lesson(
        title: 'Biashara ya kuku',
        type: LessonType.quiz,
        meta: 'Premium',
        isPremium: true,
      ),
    ],
  ),
  Course(
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
      Lesson(title: 'Kuandaa kitalu', type: LessonType.video, meta: 'DKK 4'),
      Lesson(title: 'Udhibiti wa wadudu', type: LessonType.pdf, meta: '2 MB'),
      Lesson(
        title: 'Maandalizi ya soko',
        type: LessonType.quiz,
        meta: 'Premium',
        isPremium: true,
      ),
    ],
  ),
];

const _problemCategories = [
  ProblemCategory(
    title: 'Magonjwa ya mimea',
    topic: 'Magonjwa ya mimea',
    icon: Icons.spa,
    color: Color(0xFFE15241),
  ),
  ProblemCategory(
    title: 'Wadudu na Visumbufu',
    topic: 'Wadudu',
    icon: Icons.bug_report,
    color: Color(0xFFE07A2F),
  ),
  ProblemCategory(
    title: 'Mbolea na Udongo',
    topic: 'Mbolea',
    icon: Icons.eco,
    color: Color(0xFF188C5B),
  ),
  ProblemCategory(
    title: 'Maji / Umwagiliaji',
    topic: 'Maji na Umwagiliaji',
    icon: Icons.water_drop,
    color: Color(0xFF2F7DE1),
  ),
  ProblemCategory(
    title: 'Soko na Bei',
    topic: 'Soko',
    icon: Icons.trending_up,
    color: Color(0xFFD5961B),
  ),
  ProblemCategory(
    title: 'Ufugaji',
    topic: 'Ufugaji',
    icon: Icons.handshake,
    color: Color(0xFFC85A3C),
  ),
];

const _communityPosts = [
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

const _plans = [
  PlanOption(
    title: 'Wiki 1',
    subtitle: 'Ufikiaji wa haraka',
    price: 'TZS 3,000',
    icon: Icons.calendar_month,
  ),
  PlanOption(
    title: 'Mwezi 1',
    subtitle: 'Thamani bora zaidi',
    price: 'TZS 10,000',
    icon: Icons.star,
    recommended: true,
  ),
  PlanOption(
    title: 'Kozi Maalum',
    subtitle: 'Utaalamu wa kina',
    price: 'TZS 50,000',
    icon: Icons.menu_book,
  ),
];

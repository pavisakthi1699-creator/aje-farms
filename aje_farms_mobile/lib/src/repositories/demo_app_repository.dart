import 'package:flutter/material.dart';

import '../models/app_document.dart';
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
  List<AppDocument> get documents => _documents;

  @override
  List<ProblemCategory> get problemCategories => _problemCategories;

  @override
  List<CommunityPost> get posts => _communityPosts;

  @override
  List<PlanOption> get plans => _plans;

  @override
  Course? get featuredCourse => _courses.first;

  @override
  Course? get suggestedCourse => _courses.last;
}

const _courses = [
  Course(
    id: 'pasheni',
    title: 'Kilimo cha Pasheni',
    description:
        'Jifunze maandalizi ya shamba, upandaji, matunzo, magonjwa na masoko.',
    badge: 'Maarufu',
    icon: Icons.local_florist,
    progress: 0,
    imageUrl: 'assets/images/courses/pasheni.jpg',
    outcomes: [
      'Kuchagua eneo sahihi',
      'Kuandaa shamba kabla ya kupanda',
      'Kutambua changamoto za mwanzo',
      'Kujua hatua za matunzo',
    ],
    lessons: [
      Lesson(
        title: 'Kuchagua eneo la shamba',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Chunguza mwanga, njia ya maji na nafasi ya kupanga mistari. Rekodi hali ya eneo kabla ya kuandaa shamba.',
      ),
      Lesson(
        title: 'Kuandaa shamba na nguzo',
        type: LessonType.reading,
        meta: 'Dakika 6',
        description:
            'Panga eneo la kupanda na mfumo wa kuusaidia mmea kukua. Rekebisha mpango kulingana na hali ya shamba lako.',
      ),
      Lesson(
        title: 'Kufuatilia afya ya mmea',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Kagua majani, shina na unyevu mara kwa mara. Piga picha na wasiliana na mtaalamu kabla ya kutumia tiba usiyoifahamu.',
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
    imageUrl: 'assets/images/courses/kuku.jpg',
    outcomes: [
      'Kujenga banda lenye hewa na usalama',
      'Kupanga ratiba ya chanjo',
      'Kuchagua chakula bora',
      'Kupunguza hatari ya magonjwa',
    ],
    lessons: [
      Lesson(
        title: 'Kuandaa banda',
        type: LessonType.reading,
        meta: 'Dakika 6',
        description:
            'Kagua nafasi, hewa, usalama na urahisi wa kusafisha banda kabla ya kuleta kuku.',
      ),
      Lesson(
        title: 'Maji, chakula na usafi',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Weka utaratibu wa maji safi, chakula na usafi, kisha andika mabadiliko unayoona kila siku.',
      ),
      Lesson(
        title: 'Kuweka kumbukumbu za afya',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Rekodi dalili, umri na historia ya kundi. Kwa chanjo, dawa au dalili kali, tumia ratiba iliyoidhinishwa na daktari wa mifugo wa eneo lako.',
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
    imageUrl: 'assets/images/courses/nyanya.jpg',
    outcomes: [
      'Kuandaa kitalu bora',
      'Kuhamisha miche yenye afya',
      'Kutumia mbolea kwa wakati',
      'Kudhibiti wadudu na magonjwa',
    ],
    lessons: [
      Lesson(
        title: 'Kuandaa kitalu',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Panga sehemu ya kitalu, ulinzi wa miche na utaratibu wa kukagua unyevu bila kuzidisha maji.',
      ),
      Lesson(
        title: 'Kufuatilia miche na mimea',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Kagua majani na ukuaji, rekodi dalili na piga picha. Tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.',
      ),
      Lesson(
        title: 'Kujiandaa kwa mavuno',
        type: LessonType.reading,
        meta: 'Dakika 5',
        description:
            'Panga uvunaji, upangaji wa ubora, hifadhi ya muda mfupi na mawasiliano na wanunuzi bila kutegemea bei isiyothibitishwa.',
      ),
    ],
  ),
];

const List<AppDocument> _documents = [];

const _problemCategories = [
  ProblemCategory(
    title: 'Magonjwa ya mimea',
    topic: 'Magonjwa ya mimea',
    icon: Icons.spa,
    color: Color(0xFFE15241),
    summary: 'Majani kubadilika rangi, kuoza, kunyauka au ukungu.',
    examples: ['Ukungu', 'Majani njano'],
  ),
  ProblemCategory(
    title: 'Wadudu na Visumbufu',
    topic: 'Wadudu',
    icon: Icons.bug_report,
    color: Color(0xFFE07A2F),
    summary: 'Vidukari, viwavi, funza au mashambulizi yasiyoeleweka.',
    examples: ['Viwavi', 'Vidukari'],
  ),
  ProblemCategory(
    title: 'Mbolea na Udongo',
    topic: 'Mbolea',
    icon: Icons.eco,
    color: Color(0xFF188C5B),
    summary: 'Rutuba, aina ya mbolea, muda wa kuweka na kipimo.',
    examples: ['DAP', 'Udongo mchovu'],
  ),
  ProblemCategory(
    title: 'Maji / Umwagiliaji',
    topic: 'Maji na Umwagiliaji',
    icon: Icons.water_drop,
    color: Color(0xFF2F7DE1),
    summary: 'Ratiba ya maji, mifereji, ukame au maji kusimama.',
    examples: ['Kukauka', 'Maji mengi'],
  ),
  ProblemCategory(
    title: 'Soko na Bei',
    topic: 'Soko',
    icon: Icons.trending_up,
    color: Color(0xFFD5961B),
    summary: 'Bei, wanunuzi, muda wa kuuza na maandalizi ya mavuno.',
    examples: ['Kulinganisha bei', 'Wanunuzi'],
  ),
  ProblemCategory(
    title: 'Ufugaji',
    topic: 'Ufugaji',
    icon: Icons.handshake,
    color: Color(0xFFC85A3C),
    summary: 'Kuku, mbuzi au ngombe: afya, chakula, banda na chanjo.',
    examples: ['Chanjo', 'Chakula'],
  ),
];

const _communityPosts = [
  CommunityPost(
    id: 'seed-community-guidelines',
    author: 'Timu ya AJE Farms',
    location: 'Tanzania',
    time: 'Mwongozo wa jamii',
    content:
        'Karibu kwenye jamii ya AJE Farms. Eleza hali uliyoiona, eneo na zao au mnyama. Usishiriki taarifa binafsi, na thibitisha ushauri wa dawa au chanjo na mtaalamu wa eneo lako.',
    likes: 0,
    comments: 0,
    tags: ['Jamii', 'Mwongozo'],
    replies: [],
    isExpert: true,
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
    title: 'Mwaka 1',
    subtitle: 'Okoa TZS 20,000',
    price: 'TZS 100,000',
    icon: Icons.trending_up,
  ),
];

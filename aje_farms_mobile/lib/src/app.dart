import 'package:flutter/material.dart';

import 'data/demo_content.dart';
import 'theme/app_theme.dart';

class AjeFarmsApp extends StatelessWidget {
  const AjeFarmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJE Farms',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandHeader(),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.agriculture, color: Colors.white, size: 72),
                      SizedBox(height: 24),
                      Text(
                        'Kilimo na Ujasiliamali',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Jifunze kilimo kwa vitendo, fanya tathmini, uliza AI, na ongea na mtaalamu unapohitaji.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                ),
                child: const Text('Anza Sasa'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                ),
                child: const Text('Ingia / Jisajili'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingia')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Authentication',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Hapa tutaunganisha phone OTP, email login, na role-based access kupitia Supabase au Firebase.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 28),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Namba ya simu',
              prefixText: '+255 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _showSnack(context, 'OTP ya mfano imetumwa.'),
            child: const Text('Tuma OTP'),
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    CoursesScreen(),
    AiChatScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), label: 'Nyumbani'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'Mafunzo'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined), label: 'Uliza AI'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined), label: 'Jamii'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Akaunti'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCourse = demoCourses.first;

    return Scaffold(
      appBar: AppBar(
        title: const _BrandHeader(compact: true),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Text(
            'Karibu, Mkulima',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Endeleza shamba lako leo',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          _HeroActionCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProblemScreen()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniActionCard(
                  color: AppColors.mint,
                  icon: Icons.smart_toy_outlined,
                  title: 'Uliza AI',
                  subtitle: 'Majibu ya Papo',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiChatScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniActionCard(
                  color: AppColors.text,
                  foreground: Colors.white,
                  icon: Icons.star,
                  title: 'Premium',
                  subtitle: 'Fungua Soko',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Masomo Yangu',
            actionIcon: Icons.add,
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoursesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _CourseProgressCard(
            course: activeCourse,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(course: activeCourse)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Mada Zinazovuma',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _TrendingTopics(),
          const SizedBox(height: 24),
          _CommunityTeaser(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommunityScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

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
            itemCount: problemCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final category = problemCategories[index];
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
                  builder: (_) => CourseDetailScreen(course: demoCourses.last)),
            ),
          ),
        ],
      ),
    );
  }
}

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          ...demoCourses.map(
            (course) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _CourseCard(course: course),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({required this.course, super.key});

  final DemoCourse course;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 310,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(course.title),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkPhoto(url: course.imageUrl),
                  Container(color: Colors.black.withValues(alpha: 0.32)),
                  const Center(
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 46),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.badge.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(course.title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Text(course.description),
                          const SizedBox(height: 18),
                          Text('Malengo ya Somo:',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          ...course.outcomes.map(
                            (outcome) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(outcome)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Masomo',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...course.lessons.map(
                    (lesson) => _LessonTile(
                      lesson: lesson,
                      onTap: () {
                        if (lesson.isPremium) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PaywallScreen()),
                          );
                        } else {
                          _showSnack(
                              context, '${lesson.type.label}: ${lesson.title}');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AskAiPanel(
                    courseTitle: course.title,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              AiChatScreen(initialPromptTopic: course.title)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ExpertPanel(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const WhatsAppEscalationScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({this.initialPromptTopic, super.key});

  final String? initialPromptTopic;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.model,
      text:
          'Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?',
    ),
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final topic = widget.initialPromptTopic;
    if (topic != null && topic.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send('Nina shida kuhusu $topic. Naweza kupata ushauri?');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? value]) async {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
      _controller.clear();
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _messages
          .add(_ChatMessage(role: _ChatRole.model, text: _answerFor(text)));
      _isLoading = false;
    });
  }

  String _answerFor(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pasheni')) {
      return 'Kwa pasheni, hakikisha udongo unapisha maji vizuri na eneo halituamishi maji. Tumia nguzo na waya kusaidia mmea kupanda vizuri.\n\nChanzo: Mwongozo mfupi wa pasheni';
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return 'Kwa nyanya, anza na kitalu bora, epuka maji kusimama, na fuatilia dalili za ukungu mapema. Ondoa majani yaliyoathirika na tumia ushauri wa mtaalamu kabla ya dawa.\n\nChanzo: Mwongozo mfupi wa nyanya';
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return 'Kwa kuku, zingatia banda lenye hewa, usafi, maji safi, chakula bora na ratiba ya chanjo. Usafi wa banda hupunguza magonjwa.\n\nChanzo: Mwongozo wa kuku kwa wanaoanza';
    }
    return 'Hili ni jibu la mfano lililofungwa kwenye maarifa yaliyoidhinishwa. Eleza zao, eneo, dalili, na muda wa tatizo ili nipendekeze hatua inayofuata.\n\nChanzo: Taarifa zilizoidhinishwa';
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Dawa gani kwa ukungu?',
      'Mbolea ya DAP',
      'Matatizo ya Nyanya'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mwalimu AI'),
            Text('Online',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.blue,
              child: Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingBubble(),
                  );
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 58,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ActionChip(
                  label: Text(suggestions[index]),
                  onPressed: () => _send(suggestions[index]),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Uliza ushauri kuhusu kilimo...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () => _send(),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jamii ya Wakulima')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showSnack(context, 'Kutuma post kutaunganishwa na backend.'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _CommunityFilters(),
          const SizedBox(height: 18),
          ...communityPosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _CommunityPostCard(post: post),
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tathmini')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ActionCard(
            color: AppColors.blue,
            icon: Icons.quiz,
            title: 'Jaribio la Kilimo cha Pasheni',
            body: 'Maswali 10 kuhusu maandalizi, udongo, na matunzo.',
            action: 'Anza Tathmini',
            onTap: () => _showSnack(context, 'Tathmini ya mfano imeanza.'),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            color: AppColors.peach,
            icon: Icons.assignment_turned_in,
            title: 'Kazi ya Vitendo',
            body: 'Pakia picha ya shamba lako ili ipitiwe na mtaalamu.',
            action: 'Tuma Kazi',
            onTap: () =>
                _showSnack(context, 'Upakiaji wa picha utaunganishwa baadaye.'),
          ),
        ],
      ),
    );
  }
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isProcessing = false;
  bool _isSuccess = false;

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const _PaymentStatusScreen(
        isSuccess: false,
        title: 'Inasubiri uthibitisho...',
        body:
            'Tafadhali ingiza namba ya siri kwenye simu yako kuthibitisha malipo.',
      );
    }

    if (_isSuccess) {
      return const _PaymentStatusScreen(
        isSuccess: true,
        title: 'Malipo Yamefanikiwa!',
        body:
            'Akaunti yako imefunguliwa kwa siku 30. Asante kwa kujiunga nasi.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AJE Farms'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Baadaye'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 190,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              image: DecorationImage(
                image: NetworkImage(demoCourses.first.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.42), BlendMode.darken),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Pill(label: 'Kifurushi Kimeisha', color: AppColors.secondary),
                SizedBox(height: 10),
                Text(
                  'Muda wa jaribio umeisha',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lipa kuendelea kupata mafunzo, vitabu na msaada wa AI kwenye kilimo chako.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ...planOptions.map((plan) => _PlanTile(plan: plan)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'NJIA ZA KULIPA',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 10,
                    children: [
                      _PaymentBadge(label: 'M-Pesa', color: Colors.red),
                      _PaymentBadge(label: 'Tigo', color: Colors.blue),
                      _PaymentBadge(label: 'Airtel', color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _handlePayment,
                    icon: const Icon(Icons.smartphone),
                    label: const Text('Lipa kwa Mobile Money'),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                          child: Text(
                              'Malipo yako ni salama. Tunalinda taarifa zako zote.')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhatsAppEscalationScreen extends StatelessWidget {
  const WhatsAppEscalationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongea na Mtaalamu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.chat_bubble_outline,
                color: AppColors.primary, size: 42),
          ),
          const SizedBox(height: 20),
          const Text(
            'Msaada wa Moja kwa Moja',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 25,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Tutafungua WhatsApp na ujumbe uliotayarishwa ili upate msaada wa haraka kutoka kwa wataalamu wetu.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PREVIEW YA UJUMBE',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5DDD5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.68,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF8C6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Habari Mwalimu, nahitaji msaada kuhusu kilimo. Nimetokea kwenye app ya AJE Farms.',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline, color: AppColors.primary),
                    title: Text(
                        'Mtaalamu wetu atajibu ndani ya dakika chache baada ya kutuma ujumbe huu.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showSnack(
                context, 'WhatsApp link: https://wa.me/255700000000'),
            icon: const Icon(Icons.send),
            label: const Text('Fungua WhatsApp sasa'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Rudi nyuma'),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('Somo jipya limeongezwa'),
            subtitle: Text('Angalia mwongozo mpya wa nyanya.'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Jaribio linakaribia kuisha'),
            subtitle: Text('Lipia kifurushi ili kuendelea kujifunza.'),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akaunti Yangu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryContainer,
            child: Text('+255',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '+255 7XX XXX XXX',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const Center(
              child: Text('Mkulima Mwanachama',
                  style: TextStyle(color: AppColors.muted))),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text('Hali ya Akaunti',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.schedule, color: AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Majaribio (Trial)',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                        'Muda wako wa majaribio unakwisha baada ya saa 2. Jiunge sasa ili uendelee kupata ushauri.'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Lipia Kifurushi Sasa'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Shughuli Zangu',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.menu_book,
                  title: 'Mafunzo yangu',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoursesScreen()),
                  ),
                ),
                _ProfileRow(
                  icon: Icons.description_outlined,
                  title: 'Nyaraka zilizohifadhiwa',
                  onTap: () => _showSnack(
                      context, 'Nyaraka zilizohifadhiwa zitaonekana hapa.'),
                ),
                _ProfileRow(
                  icon: Icons.quiz_outlined,
                  title: 'Tathmini na kazi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AssessmentsScreen()),
                  ),
                ),
                _ProfileRow(
                  icon: Icons.settings_outlined,
                  title: 'Mipangilio',
                  onTap: () =>
                      _showSnack(context, 'Mipangilio itaunganishwa baadaye.'),
                ),
                _ProfileRow(
                  icon: Icons.help_outline,
                  title: 'Msaada / WhatsApp',
                  subtitle: 'Tupo kwa ajili yako 24/7',
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatsAppEscalationScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () =>
                _showSnack(context, 'Umeondoka kwenye akaunti ya mfano.'),
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Ondoka kwenye Akaunti',
                style: TextStyle(color: Colors.red)),
          ),
          const Center(
              child: Text('Toleo la App 2.4.0',
                  style: TextStyle(color: AppColors.muted, fontSize: 11))),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 48,
          height: compact ? 38 : 48,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          'AJE Farms',
          style: TextStyle(
              fontSize: compact ? 18 : 22, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blue,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -8,
                child: Icon(Icons.eco,
                    size: 96, color: Colors.white.withValues(alpha: 0.48)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Pill(label: '24h Jaribio Lako'),
                  const SizedBox(height: 22),
                  Text('Una changamoto gani leo?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Pata ushauri wa kitaalamu papo hapo kwa msaada wa AI.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.search),
                    label: const Text('Eleza Tatizo'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(170, 50),
                      backgroundColor: AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  const _MiniActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.foreground = AppColors.text,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: foreground == Colors.white
                      ? Colors.white12
                      : Colors.white,
                  child: Icon(icon,
                      color: foreground == Colors.white
                          ? Colors.white
                          : AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: TextStyle(
                        color: foreground, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                      color: foreground.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.course, required this.onTap});

  final DemoCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.peach,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 94,
                  height: 94,
                  child: _NetworkPhoto(url: course.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('SEHEMU YA 4/6',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${(course.progress * 100).round()}%',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: course.progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final DemoCourse course;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkPhoto(url: course.imageUrl),
                  Positioned(
                      left: 16, top: 16, child: _Pill(label: course.badge)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(course.description),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(course: course)),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Anza Kujifunza'),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.text),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AiChatScreen(
                                  initialPromptTopic: course.title)),
                        ),
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: const Text('Uliza AI'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const WhatsAppEscalationScreen()),
                        ),
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Mtaalamu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.onTap});

  final DemoLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor:
              lesson.isPremium ? Colors.grey.shade100 : AppColors.blue,
          child: Icon(lesson.isPremium ? Icons.lock_outline : lesson.type.icon,
              color: lesson.isPremium ? Colors.grey : AppColors.primary),
        ),
        title: Text(lesson.title,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${lesson.type.label} - ${lesson.meta}'),
        trailing:
            Icon(lesson.isPremium ? Icons.lock_outline : Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _AskAiPanel extends StatelessWidget {
  const _AskAiPanel({required this.courseTitle, required this.onTap});

  final String courseTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Una swali gani?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Mwalimu AI yuko tayari kujibu maswali kuhusu $courseTitle'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Uliza AI Sasa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertPanel extends StatelessWidget {
  const _ExpertPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE8F8EE),
              child: Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
            ),
            const SizedBox(height: 12),
            Text('Ongea na Mtaalamu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            const Text('Pata ushauri binafsi kupitia WhatsApp yetu.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366)),
              child: const Text('Tuma Ujumbe WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChatRole { user, model }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});

  final _ChatRole role;
  final String text;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.text : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text,
                style: TextStyle(
                    color: isUser ? Colors.white : AppColors.text,
                    height: 1.35)),
            if (!isUser && message.text.contains('Chanzo:')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Ona Kwenye Mafunzo',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: const Text('Mwalimu AI anaandika...'),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(post.author.substring(0, 1),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${post.location} - ${post.time}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Text(post.content),
            if (post.hasImage) ...[
              const SizedBox(height: 14),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 42),
                ),
              ),
            ],
            if (post.relatedTopic != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(post.relatedTopic!,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSnack(context, 'Jibu la mfano.'),
                    icon: const Icon(Icons.mode_comment_outlined),
                    label: const Text('Jibu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              AiChatScreen(initialPromptTopic: post.content)),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('Uliza AI'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WhatsAppEscalationScreen()),
                  ),
                  icon: const Icon(Icons.phone_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityFilters extends StatelessWidget {
  const _CommunityFilters();

  @override
  Widget build(BuildContext context) {
    const filters = ['Zote', 'Mimea', 'Mifugo', 'Masoko'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => ChoiceChip(
          selected: index == 0,
          label: Text(filters[index]),
          onSelected: (_) {},
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan});

  final PlanOption plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: plan.recommended ? AppColors.mint : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: CircleAvatar(
            backgroundColor:
                plan.recommended ? AppColors.primary : Colors.grey.shade100,
            child: Icon(plan.icon,
                color: plan.recommended ? Colors.white : AppColors.text),
          ),
          title: Text(plan.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(plan.recommended
              ? 'Inapendekezwa - ${plan.subtitle}'
              : plan.subtitle),
          trailing: Text(
            plan.price,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusScreen extends StatelessWidget {
  const _PaymentStatusScreen({
    required this.isSuccess,
    required this.title,
    required this.body,
  });

  final bool isSuccess;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSuccess)
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Color(0xFFDFF6E7),
                  child:
                      Icon(Icons.verified_user, color: Colors.green, size: 48),
                )
              else
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(strokeWidth: 5),
                ),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProblemCategoryTile extends StatelessWidget {
  const _ProblemCategoryTile({required this.category, required this.onTap});

  final ProblemCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: category.color.withValues(alpha: 0.12),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(height: 12),
              Text(category.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnknownProblemTile extends StatelessWidget {
  const _UnknownProblemTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryContainer,
        child: Icon(Icons.help_outline, color: AppColors.primary),
      ),
      title: const Text('Sijui tatizo',
          style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: const Text('Mwalimu AI itakusaidia kutambua'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _TrendingTopics extends StatelessWidget {
  const _TrendingTopics();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.water_drop, 'Maji', Colors.blue),
      (Icons.bug_report, 'Wadudu', Colors.red),
      (Icons.eco, 'Mbolea', AppColors.primary),
      (Icons.trending_up, 'Soko', AppColors.secondary),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            width: 96,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$1, color: item.$3),
                const SizedBox(height: 10),
                Text(item.$2,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommunityTeaser extends StatelessWidget {
  const _CommunityTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.blue,
          child: Icon(Icons.groups_outlined, color: Colors.blue),
        ),
        title: const Text('Jiunge na Jamii',
            style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Wakulima 1,200+'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 34),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 18),
              Text(
                action,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.actionIcon, required this.onAction});

  final String title;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        IconButton.filledTonal(onPressed: onAction, icon: Icon(actionIcon)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color = Colors.white});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.82 : 1),
          borderRadius: BorderRadius.circular(999)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: dark ? AppColors.text : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primaryContainer,
        child: const Icon(Icons.landscape_outlined,
            color: AppColors.primary, size: 44),
      ),
    );
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

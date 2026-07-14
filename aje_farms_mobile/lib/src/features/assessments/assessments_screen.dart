// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scores = context.session.state.assessmentScores;
    final pasheniScore = scores['pasheni-basics'];
    final fieldScore = scores['field-assignment'];

    return Scaffold(
      appBar: AppBar(title: const Text('Tathmini')),
      body: AppLayout(
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Pima ujuzi wako',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Jaribu maarifa yako na uwasilishe kazi ya vitendo kutoka shambani.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ActionCard(
            color: context.colors.surfaceMuted,
            icon: Icons.quiz,
            title: 'Jaribio la Kilimo cha Pasheni',
            body: pasheniScore == null
                ? 'Maswali 5 kuhusu maandalizi, udongo, na matunzo.'
                : 'Alama yako ya mwisho: $pasheniScore/5. Unaweza kurudia kuboresha.',
            action: pasheniScore == null ? 'Anza Tathmini' : 'Rudia Tathmini',
            onTap: () {
              AppFeedback.tap();
              AppNavigator.pushQuiz(context);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          ActionCard(
            color: context.colors.surfacePeach,
            icon: Icons.assignment_turned_in,
            title: 'Kazi ya Vitendo',
            body: fieldScore == null
                ? 'Eleza hali ya shamba lako na hatua utakazochukua wiki hii.'
                : 'Kazi imewasilishwa. Alama ya ukamilifu: $fieldScore/5.',
            action: fieldScore == null ? 'Tuma Kazi' : 'Hariri Kazi',
            onTap: () {
              AppFeedback.tap();
              AppNavigator.pushFieldAssignment(context);
            },
          ),
        ],
      ),
      ),
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

const _quizQuestions = [
  QuizQuestion(
    prompt: 'Pasheni inapendelea udongo wa aina gani?',
    options: [
      'Udongo unaopitisha maji vizuri',
      'Udongo unaotuamisha maji',
      'Udongo usio na rutuba kabisa',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    prompt: 'Kwa nini maji yasituame karibu na mizizi?',
    options: [
      'Husaidia mizizi kuoza',
      'Hupunguza hatari ya mizizi kuoza',
      'Hufanya mmea usihitaji nguzo',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    prompt: 'Nguzo na waya hutumika kwa nini kwenye pasheni?',
    options: [
      'Kusaidia mmea kupanda vizuri',
      'Kuzuia mmea kupata mwanga',
      'Kubadilisha aina ya udongo',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    prompt: 'Ni hatua gani ni sehemu ya matunzo?',
    options: [
      'Kumwagilia bila mpangilio',
      'Kupalilia na kufuatilia wadudu',
      'Kuacha shamba bila ukaguzi',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    prompt: 'Unapoona dalili zisizoeleweka, hatua bora ya kwanza ni ipi?',
    options: [
      'Kutumia dawa yoyote mara moja',
      'Kukagua dalili na kuuliza ushauri',
      'Kungoa mimea yote',
    ],
    correctIndex: 1,
  ),
];

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  final Map<int, int> _answers = {};

  Future<void> _submit() async {
    if (_answers.length < _quizQuestions.length) {
      showSnack(context, 'Jibu maswali yote kabla ya kutuma.');
      return;
    }
    final score = _quizQuestions.indexed.where((entry) {
      final (index, question) = entry;
      return _answers[index] == question.correctIndex;
    }).length;
    await context.session.saveAssessmentScore('pasheni-basics', score);
    if (!mounted) return;
    AppFeedback.success();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          score >= 4 ? Icons.emoji_events_outlined : Icons.quiz_outlined,
          color: context.colors.primary,
          size: 36,
        ),
        title: const Text('Matokeo ya Tathmini'),
        content: Text(
          'Umepata $score kati ya ${_quizQuestions.length}.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Endelea'),
          ),
          FilledButton(
            onPressed: () {
              AppFeedback.tap();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Rudi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jaribio la Pasheni')),
      body: AppLayout(
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          for (final entry in _quizQuestions.indexed) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.$1 + 1}. ${entry.$2.prompt}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final option in entry.$2.options.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InteractiveInk(
                          borderRadius: AppRadius.lg,
                          enableHaptic: false,
                          onTap: () {
                            AppFeedback.selection();
                            setState(() => _answers[entry.$1] = option.$1);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _answers[entry.$1] == option.$1
                                  ? context.colors.primaryContainer
                                  : context.colors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: _answers[entry.$1] == option.$1
                                    ? context.colors.primary
                                    : context.colors.borderSubtle,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _answers[entry.$1] == option.$1
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: _answers[entry.$1] == option.$1
                                      ? context.colors.primary
                                      : context.colors.muted,
                                  size: 22,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    option.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton.icon(
            onPressed: () {
              AppFeedback.tap();
              _submit();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Tuma Majibu'),
          ),
        ],
      ),
      ),
    );
  }
}

class FieldAssignmentScreen extends StatefulWidget {
  const FieldAssignmentScreen({super.key});

  @override
  State<FieldAssignmentScreen> createState() => FieldAssignmentScreenState();
}

class FieldAssignmentScreenState extends State<FieldAssignmentScreen> {
  final _cropController = TextEditingController();
  final _observationController = TextEditingController();
  final _actionController = TextEditingController();

  @override
  void dispose() {
    _cropController.dispose();
    _observationController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final filled = [
      _cropController.text.trim(),
      _observationController.text.trim(),
      _actionController.text.trim(),
    ].where((value) => value.length >= 4).length;
    if (filled < 3) {
      showSnack(context, 'Jaza zao, ulichogundua, na hatua utakayochukua.');
      return;
    }
    await context.session.saveAssessmentScore('field-assignment', 5);
    if (!mounted) return;
    AppFeedback.success();
    Navigator.of(context).pop();
    showSnack(context, 'Kazi imewasilishwa na kuhifadhiwa.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kazi ya Vitendo')),
      body: AppLayout(
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Eleza ulichoona shambani',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Andika kwa ufupi zao, uchunguzi, na hatua utakazochukua wiki hii.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: _cropController,
            labelText: 'Zao au mifugo',
            hintText: 'Mfano: nyanya, pasheni, kuku',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _observationController,
            labelText: 'Umegundua nini?',
            hintText: 'Eleza dalili au hali uliyoiona shambani',
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _actionController,
            labelText: 'Hatua utakazochukua',
            hintText: 'Andika hatua za wiki hii',
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () {
              AppFeedback.tap();
              _submit();
            },
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('Hifadhi Kazi'),
          ),
        ],
      ),
      ),
    );
  }
}

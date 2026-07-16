// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fieldScore =
        context.session.state.assessmentScores['field-assignment'];

    return Scaffold(
      appBar: AppBar(title: const Text('Kazi za vitendo')),
      body: AppLayout(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              'Tumia maarifa shambani',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Eleza hali ya shamba lako na hatua utakazochukua. Hakuna jaribio la maswali.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xxl),
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

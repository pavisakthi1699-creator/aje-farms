part of '../../app.dart';

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

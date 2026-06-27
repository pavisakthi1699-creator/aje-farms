part of '../../app.dart';

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

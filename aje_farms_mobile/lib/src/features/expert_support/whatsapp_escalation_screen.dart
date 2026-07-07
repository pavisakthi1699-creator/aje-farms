// ignore_for_file: use_key_in_widget_constructors

import "../../ui.dart";
import "package:url_launcher/url_launcher.dart";

class WhatsAppEscalationScreen extends StatelessWidget {
  const WhatsAppEscalationScreen({super.key});

  static const _expertPhone = String.fromEnvironment(
    'AJE_WHATSAPP_EXPERT_PHONE',
    defaultValue: '255700000000',
  );
  static const _message =
      'Habari Mwalimu, nahitaji msaada kuhusu kilimo. Nimetokea kwenye app ya AJE Farms.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ongea na Mtaalamu')),
      body: AppLayout(
        child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.md),
          CircleAvatar(
            radius: 44,
            backgroundColor: context.colors.whatsappSurface,
            child: Icon(
              Icons.chat_bubble_outline,
              color: context.colors.whatsapp,
              size: 42,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Msaada wa Moja kwa Moja',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tutafungua WhatsApp na ujumbe uliotayarishwa ili upate msaada wa haraka kutoka kwa wataalamu wetu.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREVIEW YA UJUMBE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.muted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.whatsappChatBg,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.68,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.colors.whatsappBubble,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.textPrimary
                                  .withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          _message,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.info_outline, color: context.colors.primary),
                    title: const Text(
                      'Mtaalamu wetu atajibu ndani ya dakika chache baada ya kutuma ujumbe huu.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: () {
              AppFeedback.tap();
              _openWhatsApp(context);
            },
            icon: const Icon(Icons.send),
            label: const Text('Fungua WhatsApp sasa'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.whatsapp,
              foregroundColor: context.colors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () {
              AppFeedback.tap();
              Navigator.of(context).maybePop();
            },
            child: const Text('Rudi nyuma'),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.https('wa.me', '/$_expertPhone', {'text': _message});
    final fallback = Uri.parse(
      'https://api.whatsapp.com/send?phone=$_expertPhone&text=${Uri.encodeComponent(_message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    showSnack(context, 'WhatsApp haijapatikana kwenye kifaa hiki.');
  }
}

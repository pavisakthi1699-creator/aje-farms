import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/services/secure_supabase_storage.dart';

// The publishable key is safe to ship in the client — it identifies the
// project, not a secret, and every legitimate write still goes through
// RLS-denied tables plus the AJE API's own auth checks. Override with
// --dart-define for a different Supabase project (e.g. a staging one).
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://iufjpfyozeuulzjscdoq.supabase.co',
);
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_Ao6tBuFwOxyWwOkF7_voqw_mYKCVFZr',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseLocalStorage(projectUrl: _supabaseUrl),
      pkceAsyncStorage: const SecureSupabasePkceStorage(),
    ),
  );
  runApp(const AjeFarmsApp());
}

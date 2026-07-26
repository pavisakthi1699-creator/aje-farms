import 'package:aje_farms_mobile/src/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BrandMark renders the official AJE Farms logo asset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandMark(),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/aje-farms-logo.png',
    );
    expect(find.bySemanticsLabel('Nembo ya AJE Farms'), findsOneWidget);
  });
}

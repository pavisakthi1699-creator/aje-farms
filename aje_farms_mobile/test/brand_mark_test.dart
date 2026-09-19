import 'package:aje_farms_mobile/src/ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BrandMark renders the official Chuo Kikuu Cha Mtaani logo asset',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandMark(),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/chuo-kikuu-cha-mtaani-logo.png',
    );
    expect(
      find.bySemanticsLabel('Nembo ya Chuo Kikuu Cha Mtaani'),
      findsOneWidget,
    );
  });
}

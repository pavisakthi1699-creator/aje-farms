import 'package:aje_farms_mobile/src/features/courses/book_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('book viewer opens the protected PDF inside the app',
      (tester) async {
    Uri? openedUri;

    await tester.pumpWidget(
      MaterialApp(
        home: BookViewerScreen(
          title: 'Mwongozo wa Kilimo',
          sourceUrl: 'https://storage.example.test/book.pdf?token=signed',
          viewerBuilder: (uri) {
            openedUri = uri;
            return const Center(child: Text('PDF reader'));
          },
        ),
      ),
    );

    expect(find.text('Mwongozo wa Kilimo'), findsOneWidget);
    expect(find.text('PDF reader'), findsOneWidget);
    expect(
      openedUri,
      Uri.parse('https://storage.example.test/book.pdf?token=signed'),
    );
  });

  testWidgets('book viewer rejects a malformed source URL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BookViewerScreen(
          title: 'Mwongozo wa Kilimo',
          sourceUrl: 'not-a-web-address',
        ),
      ),
    );

    expect(find.text('Kitabu hakikuweza kupakiwa.'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsNothing);
  });
}

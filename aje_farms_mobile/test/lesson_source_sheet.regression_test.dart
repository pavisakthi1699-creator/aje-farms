import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression: ISSUE-001 — long lesson text hid the source-book action below
// an overflowing, non-scrollable lesson sheet.
// Found by /qa on 2026-08-06 while testing a live source PDF in the emulator.
void main() {
  testWidgets('long reading lesson can scroll to its source-book action',
      (tester) async {
    const lesson = Lesson(
      id: 'lesson-long-reading',
      title: 'Matumizi ya Maji na Mbolea na madawa',
      type: LessonType.reading,
      meta: 'Dakika 8',
      description: '$_longParagraph$_longParagraph$_longParagraph',
      sourceTitle: 'Mwongozo kamili wa kilimo',
    );

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: AppDependencies.demo(),
        child: AppSessionScope(
          controller: AppSessionController(),
          child: const MaterialApp(
            home: Scaffold(
              body: LessonPreviewSheet(
                courseId: 'course-1',
                lessonId: 'lesson-long-reading',
                lessonProgressKey: 'course-1:lesson-long-reading',
                lesson: lesson,
                courseTitle: 'Kilimo Cha Mbogamboga',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Soma kitabu kizima'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Soma kitabu kizima'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Soma kitabu kizima').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _longParagraph =
    'Tumia maji kwa uangalifu kulingana na hali ya udongo na mahitaji ya mimea. '
    'Kagua shamba kila siku, fuata vipimo vya mbolea, na zingatia usalama. '
    'Weka kumbukumbu za shughuli zote ili uweze kupima maendeleo ya mazao. ';

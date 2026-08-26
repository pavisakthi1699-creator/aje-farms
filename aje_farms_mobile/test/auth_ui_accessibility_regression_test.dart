import 'package:aje_farms_mobile/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapAuth() {
    return AppDependenciesScope(
      dependencies: AppDependencies.demo(),
      child: AppSessionScope(
        controller: AppSessionController(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthScreen(),
        ),
      ),
    );
  }

  testWidgets('sign-in password can be shown and hidden', (tester) async {
    await tester.pumpWidget(wrapAuth());

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(passwordField().obscureText, isTrue);
    expect(passwordField().autocorrect, isFalse);
    expect(passwordField().enableSuggestions, isFalse);
    expect(passwordField().smartDashesType, SmartDashesType.disabled);
    expect(passwordField().smartQuotesType, SmartQuotesType.disabled);
    expect(passwordField().enableIMEPersonalizedLearning, isFalse);
    expect(find.byTooltip('Onyesha nenosiri'), findsOneWidget);

    await tester.tap(find.byTooltip('Onyesha nenosiri'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
    expect(passwordField().autocorrect, isFalse);
    expect(passwordField().enableSuggestions, isFalse);
    expect(passwordField().smartDashesType, SmartDashesType.disabled);
    expect(passwordField().smartQuotesType, SmartQuotesType.disabled);
    expect(passwordField().enableIMEPersonalizedLearning, isFalse);
    expect(find.byTooltip('Ficha nenosiri'), findsOneWidget);

    await tester.tap(find.byTooltip('Ficha nenosiri'));
    await tester.pump();

    expect(passwordField().obscureText, isTrue);
  });

  testWidgets('switching auth mode re-hides a revealed password',
      (tester) async {
    await tester.pumpWidget(wrapAuth());

    await tester.tap(find.byTooltip('Onyesha nenosiri'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );

    await tester.tap(find.text('Jisajili'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
  });

  testWidgets('reset password visibility controls are independent',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const PasswordResetScreen(),
      ),
    );

    List<TextField> passwordFields() =>
        tester.widgetList<TextField>(find.byType(TextField)).toList();

    expect(passwordFields().map((field) => field.obscureText), [true, true]);
    expect(
      passwordFields().every((field) => field.autocorrect == false),
      isTrue,
    );
    expect(passwordFields().every((field) => !field.enableSuggestions), isTrue);
    expect(
      passwordFields().every(
        (field) => field.smartDashesType == SmartDashesType.disabled,
      ),
      isTrue,
    );
    expect(
      passwordFields().every(
        (field) => field.smartQuotesType == SmartQuotesType.disabled,
      ),
      isTrue,
    );
    expect(
      passwordFields().every(
        (field) => !field.enableIMEPersonalizedLearning,
      ),
      isTrue,
    );
    expect(find.byTooltip('Onyesha nenosiri jipya'), findsOneWidget);
    expect(find.byTooltip('Onyesha nenosiri lililorudiwa'), findsOneWidget);

    await tester.tap(find.byTooltip('Onyesha nenosiri jipya'));
    await tester.pump();

    expect(passwordFields().map((field) => field.obscureText), [false, true]);

    await tester.tap(find.byTooltip('Onyesha nenosiri lililorudiwa'));
    await tester.pump();

    expect(passwordFields().map((field) => field.obscureText), [false, false]);
  });

  testWidgets('brand header exposes one curated semantic label',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: BrandHeader()),
      ),
    );

    expect(
      find.bySemanticsLabel('Chuo Kikuu Cha Mtaani'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Chuo Kikuu Cha Mtaani')).label,
      'Chuo Kikuu Cha Mtaani',
    );

    semantics.dispose();
  });

  test('primary body typography remains at least 16sp', () {
    final textTheme = AppTheme.light().textTheme;

    expect(textTheme.bodyLarge?.fontSize, greaterThanOrEqualTo(16));
    expect(textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(16));
  });
}

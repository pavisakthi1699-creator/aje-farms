import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aje_farms_mobile/src/ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppTranslations local unit tests', () {
    test('translates core Swahili UI keys to English', () {
      expect(
        AppTranslations.translate('Nyumbani', isEnglish: true),
        equals('Home'),
      );
      expect(
        AppTranslations.translate('Kozi', isEnglish: true),
        equals('Courses'),
      );
      expect(
        AppTranslations.translate('Jamii ya Wakulima', isEnglish: true),
        equals('Farmers Community'),
      );
      expect(
        AppTranslations.translate('Msaidizi AI', isEnglish: true),
        equals('AI Assistant'),
      );
      expect(
        AppTranslations.translate('Hariri Profaili', isEnglish: true),
        equals('Edit Profile'),
      );
    });

    test('translates dynamic course topics to English', () {
      expect(
        AppTranslations.translate(
          'Ufugaji wa Kuku wa Kienyeji',
          isEnglish: true,
        ),
        equals('Indigenous Poultry Farming'),
      );
      expect(
        AppTranslations.translate('Kilimo cha Mahindi', isEnglish: true),
        equals('Maize Farming'),
      );
    });

    test('translates notification keys and moderation labels to English', () {
      expect(
        AppTranslations.translate('Taarifa', isEnglish: true),
        equals('Notifications'),
      );
      expect(
        AppTranslations.translate('Arifa', isEnglish: true),
        equals('Notifications'),
      );
      expect(
        AppTranslations.translate('Arifa za mafunzo na jamii', isEnglish: true),
        equals('Learning and community notifications'),
      );
      expect(
        AppTranslations.translate('Washa au zima vikumbusho kwenye app.',
            isEnglish: true),
        equals('Turn reminders on or off in the app.'),
      );
      expect(
        AppTranslations.translate('Arifa zimewashwa', isEnglish: true),
        equals('Notifications enabled'),
      );
      expect(
        AppTranslations.translate('Arifa zimezimwa', isEnglish: true),
        equals('Notifications disabled'),
      );
      expect(
        AppTranslations.translate('Hakuna arifa mpya', isEnglish: true),
        equals('No new notifications'),
      );
      expect(
        AppTranslations.translate('Jibu jipya', isEnglish: true),
        equals('New reply'),
      );
      expect(
        AppTranslations.translate('Post imefichwa', isEnglish: true),
        equals('Post hidden'),
      );
      expect(
        AppTranslations.translate('Post imerejeshwa', isEnglish: true),
        equals('Post restored'),
      );
      expect(
        AppTranslations.translate('Ripoti imepitiwa', isEnglish: true),
        equals('Report reviewed'),
      );
      expect(
        AppTranslations.translate('Mkulima amejibu post yako.', isEnglish: true),
        equals('A farmer replied to your post.'),
      );
      expect(
        AppTranslations.translate(
          'Post yako imefichwa baada ya ukaguzi wa timu ya Chuo Kikuu Cha Mtaani.',
          isEnglish: true,
        ),
        equals(
            'Your post was hidden after review by the Mtaani Open University team.'),
      );
    });

    test('translates dynamic notification patterns in both directions', () {
      // Swahili -> English
      expect(
        AppTranslations.translate(
          'free imewashwa kwenye kifaa hiki.',
          isEnglish: true,
        ),
        equals('free is active on this device.'),
      );
      expect(
        AppTranslations.translate(
          'Umewasilisha kazi 3. Endelea kutumia maarifa shambani.',
          isEnglish: true,
        ),
        equals(
            'You have submitted 3 assignments. Keep using your skills on the farm.'),
      );
      expect(
        AppTranslations.translate(
          'Una nyaraka 5 za kusoma baadaye.',
          isEnglish: true,
        ),
        equals('You have 5 documents saved to read later.'),
      );
      expect(
        AppTranslations.translate(
          'Umetuma post 2. Angalia majibu mapya.',
          isEnglish: true,
        ),
        equals('You have shared 2 posts. Check for new replies.'),
      );
      expect(
        AppTranslations.translate(
          'Asha amejibu post yako.',
          isEnglish: true,
        ),
        equals('Asha replied to your post.'),
      );

      // English -> Swahili
      expect(
        AppTranslations.translate(
          'free is active on this device.',
          isEnglish: false,
        ),
        equals('free imewashwa kwenye kifaa hiki.'),
      );
      expect(
        AppTranslations.translate(
          'You have submitted 3 assignments. Keep using your skills on the farm.',
          isEnglish: false,
        ),
        equals('Umewasilisha kazi 3. Endelea kutumia maarifa shambani.'),
      );
      expect(
        AppTranslations.translate(
          'You have 5 documents saved to read later.',
          isEnglish: false,
        ),
        equals('Una nyaraka 5 za kusoma baadaye.'),
      );
      expect(
        AppTranslations.translate(
          'You have shared 2 posts. Check for new replies.',
          isEnglish: false,
        ),
        equals('Umetuma post 2. Angalia majibu mapya.'),
      );
      expect(
        AppTranslations.translate(
          'Asha replied to your post.',
          isEnglish: false,
        ),
        equals('Asha amejibu post yako.'),
      );
    });

    test('returns original text in Swahili mode', () {
      expect(
        AppTranslations.translate('Nyumbani', isEnglish: false),
        equals('Nyumbani'),
      );
      expect(
        AppTranslations.translate('Kozi', isEnglish: false),
        equals('Kozi'),
      );
    });

    testWidgets('extension context.tr works reactively with session language',
        (tester) async {
      final sessionController = AppSessionController();

      await tester.pumpWidget(
        AppSessionScope(
          controller: sessionController,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: Text('Nyumbani'.tr(context)),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Default language is Swahili
      expect(find.text('Nyumbani'), findsOneWidget);

      // Switch language preference to English
      await sessionController.setLanguagePreference(const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}

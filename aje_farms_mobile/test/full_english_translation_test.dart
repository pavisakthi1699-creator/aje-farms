import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aje_farms_mobile/src/ui.dart';
import 'package:aje_farms_mobile/src/services/demo_mwalimu_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Full App A-to-Z English Translation Verification', () {
    test('Translates all Home and Dashboard content to English', () {
      expect('Nyumbani'.trDirect(isEnglish: true), equals('Home'));
      expect('Kipaumbele cha leo'.trDirect(isEnglish: true), equals("Today's priority"));
      expect('Eleza tatizo la shamba'.trDirect(isEnglish: true), equals('Describe farm problem'));
      expect('Chagua aina ya changamoto ili kupata mwongozo sahihi wa hatua za kuchukua.'.trDirect(isEnglish: true),
          equals('Select problem category to get step-by-step guidance.'));
      expect('Endelea na kozi'.trDirect(isEnglish: true), equals('Continue course'));
      expect('Jiunge na Jamii'.trDirect(isEnglish: true), equals('Join Community'));
    });

    test('Translates all Course and Curriculum details to English', () {
      expect('Kozi'.trDirect(isEnglish: true), equals('Courses'));
      expect('Kilimo cha Pasheni'.trDirect(isEnglish: true), equals('Passion Fruit Farming'));
      expect('Ufugaji wa Kuku'.trDirect(isEnglish: true), equals('Poultry Farming'));
      expect('Kilimo cha Nyanya'.trDirect(isEnglish: true), equals('Tomato Farming'));
      expect('Kuchagua eneo la shamba'.trDirect(isEnglish: true), equals('Choosing farm site'));
      expect('Dakika 5'.trDirect(isEnglish: true), equals('5 mins'));
      expect('Somo la sasa'.trDirect(isEnglish: true), equals('Current lesson'));
      expect('Limekamilika'.trDirect(isEnglish: true), equals('Completed'));
      expect('Ongea na Mtaalamu'.trDirect(isEnglish: true), equals('Talk to an Expert'));
      expect('Tuma Ujumbe WhatsApp'.trDirect(isEnglish: true), equals('Send WhatsApp Message'));
    });

    test('Translates Problem intake and diagnosis to English', () {
      expect('Eleza tatizo'.trDirect(isEnglish: true), equals('Describe problem'));
      expect('Mada maarufu za matatizo'.trDirect(isEnglish: true), equals('Trending Problem Topics'));
      expect('Wadudu na Magonjwa'.trDirect(isEnglish: true), equals('Pests & Diseases'));
      expect('Mbolea na Udongo'.trDirect(isEnglish: true), equals('Fertilizer & Soil'));
      expect('Umwagiliaji na Maji'.trDirect(isEnglish: true), equals('Irrigation & Water'));
      expect('Afya ya Mifugo'.trDirect(isEnglish: true), equals('Livestock Health'));
      expect('Sijui tatizo'.trDirect(isEnglish: true), equals("I don't know the problem"));
    });

    test('Translates AI Chat and reporting to English', () {
      expect('Habari! Mimi ni Mwalimu AI. Nawezaje kukusaidia kuhusu kilimo leo?'.trDirect(isEnglish: true),
          equals('Hello! I am Mwalimu AI. How can I assist you with farming today?'));
      expect('Uliza chochote kuhusu kilimo au ufugaji...'.trDirect(isEnglish: true),
          equals('Ask anything about farming or livestock...'));
      expect('Hali: Mtandaoni'.trDirect(isEnglish: true), equals('Status: Online'));
      expect('Ripoti jibu hili'.trDirect(isEnglish: true), equals('Report this response'));
      expect('Kwa nini unaripoti jibu hili?'.trDirect(isEnglish: true), equals('Why are you reporting this response?'));
      expect('Jibu linaudhi au halifai'.trDirect(isEnglish: true), equals('Response is offensive or inappropriate'));
      expect('Muktadha uliotumwa'.trDirect(isEnglish: true), equals('Sent Context'));
      expect('Mwalimu AI anaandika'.trDirect(isEnglish: true), equals('Mwalimu AI is typing'));
      expect('Ona Kwenye Mafunzo'.trDirect(isEnglish: true), equals('View in Courses'));
      expect('Msaidizi wa Binadamu'.trDirect(isEnglish: true), equals('Human Assistant'));

      // AI Answers and Citations
      expect(
        'Kwa nyanya, piga picha ya dalili, rekodi sehemu ya mmea iliyoathirika na hali ya unyevu. Usichague dawa kwa jina la dalili pekee; pata utambuzi wa mtaalamu wa eneo lako.'.trDirect(isEnglish: true),
        equals('For tomatoes, photograph the symptoms, record the affected plant part and moisture levels. Do not choose chemicals by symptom name alone; obtain a diagnosis from a local specialist.'),
      );
      expect(
        'Kagua majani na ukuaji, rekodi dalili na tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.'.trDirect(isEnglish: true),
        equals('Inspect leaves and growth, record symptoms, and identify the issue with expert guidance before applying treatments.'),
      );
      expect(
        'Kwa kuku, rekodi umri, idadi, dalili na muda zilipoanza. Tenga kuku mwenye dalili kali inapowezekana na wasiliana na daktari wa mifugo kwa utambuzi, chanjo au dawa.'.trDirect(isEnglish: true),
        equals('For poultry, record age, quantity, symptoms, and onset time. Isolate severely symptomatic birds where possible and contact a veterinarian for diagnosis, vaccination, or medication.'),
      );
      expect(
        'Kilimo cha Nyanya'.trDirect(isEnglish: true),
        equals('Tomato Farming'),
      );
    });

    test('DemoMwalimuAiService recognizes English and Swahili prompts', () async {
      const service = DemoMwalimuAiService();
      
      final tomatoAnswerEn = await service.answer('Tomato problems with leaves');
      expect(tomatoAnswerEn.text, contains('Kwa nyanya'));
      expect(tomatoAnswerEn.sources.first.courseTitle, equals('Kilimo cha Nyanya'));
      expect(tomatoAnswerEn.text.trDirect(isEnglish: true), startsWith('For tomatoes'));
      expect(tomatoAnswerEn.sources.first.courseTitle.trDirect(isEnglish: true), equals('Tomato Farming'));
      expect(tomatoAnswerEn.sources.first.excerpt.trDirect(isEnglish: true), startsWith('Inspect leaves'));

      final chickenAnswerEn = await service.answer('My poultry is sick');
      expect(chickenAnswerEn.text, contains('Kwa kuku'));
      expect(chickenAnswerEn.text.trDirect(isEnglish: true), startsWith('For poultry'));

      final pestAnswerEn = await service.answer('Pest attacking crops');
      expect(pestAnswerEn.text, contains('Kwa wadudu'));
      expect(pestAnswerEn.text.trDirect(isEnglish: true), startsWith('For pests'));

      // Suggestion chip: "What symptoms should I record?"
      final symptomAnswer = await service.answer('What symptoms should I record?');
      expect(symptomAnswer.text, contains('kurekodi dalili'));
      expect(symptomAnswer.text.trDirect(isEnglish: true), startsWith('To record symptoms accurately'));

      // User typed "hi ok"
      final greetingAnswer = await service.answer('hi ok');
      expect(greetingAnswer.text, contains('Mimi ni Mwalimu AI'));
      expect(greetingAnswer.text.trDirect(isEnglish: true), startsWith('Hello! I am Mwalimu AI'));

      // Fallback message test
      final fallbackAnswer = await service.answer('xyz unknown completely random string 123');
      expect(fallbackAnswer.text, contains('Sina taarifa ya kutosha'));
      expect(fallbackAnswer.text.trDirect(isEnglish: true), startsWith('I do not have enough information'));
    });

    test('Translates Community feed, posts, and moderation to English', () {
      expect('Jamii ya Wakulima'.trDirect(isEnglish: true), equals('Farmers Community'));
      expect('Tuma Swali'.trDirect(isEnglish: true), equals('Ask Question'));
      expect('Hakuna machapisho bado'.trDirect(isEnglish: true), equals('No posts yet'));
      expect('Mtaalamu aliyethibitishwa'.trDirect(isEnglish: true), equals('Verified expert'));
      expect('Inahitaji haraka'.trDirect(isEnglish: true), equals('Urgent'));
      expect('Jibu'.trDirect(isEnglish: true), equals('Reply'));
      expect('Majadiliano'.trDirect(isEnglish: true), equals('Discussions'));
      expect('Usalama wa jamii'.trDirect(isEnglish: true), equals('Community safety'));
      expect('Hatua inayofuata'.trDirect(isEnglish: true), equals('Next step'));
      expect('Andaa muhtasari'.trDirect(isEnglish: true), equals('Prepare summary'));
    });

    test('Translates Profile, Settings, and Account status to English', () {
      expect('Profaili'.trDirect(isEnglish: true), equals('Profile'));
      expect('Hali ya Akaunti'.trDirect(isEnglish: true), equals('Account Status'));
      expect('Mkulima Mwanachama'.trDirect(isEnglish: true), equals('Member Farmer'));
      expect('Shughuli Zangu'.trDirect(isEnglish: true), equals('My Activity'));
      expect('Mafunzo yangu'.trDirect(isEnglish: true), equals('My learning'));
      expect('Nyaraka zilizohifadhiwa'.trDirect(isEnglish: true), equals('Saved documents'));
      expect('Kazi za vitendo'.trDirect(isEnglish: true), equals('Practical assignments'));
      expect('Mipangilio'.trDirect(isEnglish: true), equals('Settings'));
      expect('Ondoka kwenye Akaunti'.trDirect(isEnglish: true), equals('Log Out of Account'));
      expect('Muonekano wa app'.trDirect(isEnglish: true), equals('App Appearance'));
      expect('Hifadhi Mipangilio'.trDirect(isEnglish: true), equals('Save Settings'));
    });

    test('Translates Search filters and results counter to English', () {
      expect('Tafuta'.trDirect(isEnglish: true), equals('Search'));
      expect('Matokeo bora'.trDirect(isEnglish: true), equals('Top Results'));
      expect('Futa utafutaji'.trDirect(isEnglish: true), equals('Clear search'));
      expect('Mada maarufu'.trDirect(isEnglish: true), equals('Popular Topics'));
      expect('Hakuna matokeo yaliyopatikana'.trDirect(isEnglish: true), equals('No results found'));
    });

    test('Translates dynamic patterns to English', () {
      expect('5 wamependa'.trDirect(isEnglish: true), equals('5 liked'));
      expect('12 majibu'.trDirect(isEnglish: true), equals('12 replies'));
      expect('4 zimehifadhiwa'.trDirect(isEnglish: true), equals('4 saved'));
      expect('Zuia John?'.trDirect(isEnglish: true), equals('Block John?'));
      expect('Somo linalofuata: Kuchagua eneo la shamba'.trDirect(isEnglish: true),
          equals('Next lesson: Choosing farm site'));
      expect('8 matokeo yamepatikana.'.trDirect(isEnglish: true), equals('8 results found.'));
    });
  });
}

extension on String {
  String trDirect({required bool isEnglish}) =>
      AppTranslations.translate(this, isEnglish: isEnglish);
}

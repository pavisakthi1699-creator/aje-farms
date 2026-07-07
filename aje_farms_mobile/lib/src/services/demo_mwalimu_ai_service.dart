import 'mwalimu_ai_service.dart';

class DemoMwalimuAiService implements MwalimuAiService {
  const DemoMwalimuAiService();

  @override
  Future<MwalimuAiAnswer> answer(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lower = prompt.toLowerCase();
    if (lower.contains('pasheni')) {
      return _answer(
        'Kwa pasheni, hakikisha udongo unapisha maji vizuri na eneo halituamishi maji. Angalia kama kuna majani ya njano, madoa au wadudu chini ya jani kabla ya kuchagua dawa. Tumia nguzo na waya kusaidia mmea kupanda vizuri.',
        const MwalimuAiSource(
          id: 'pasheni:mwongozo-mfupi-wa-pasheni',
          courseId: 'pasheni',
          lessonId: 'mwongozo-mfupi-wa-pasheni',
          courseTitle: 'Kilimo cha Pasheni',
          title: 'Mwongozo mfupi wa pasheni',
          type: 'pdf',
          excerpt:
              'Pakua muhtasari wa hatua za kupanda, kuweka nguzo, kumwagilia na kutambua dalili za mwanzo.',
        ),
      );
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return _answer(
        'Kwa nyanya, anza kwa kutenga miche iliyoathirika, epuka maji kusimama kwenye shina, na fuatilia ukungu chini ya majani. Ondoa majani yaliyoathirika na tumia ushauri wa mtaalamu kabla ya dawa.',
        const MwalimuAiSource(
          id: 'nyanya:udhibiti-wa-wadudu',
          courseId: 'nyanya',
          lessonId: 'udhibiti-wa-wadudu',
          courseTitle: 'Kilimo cha Nyanya',
          title: 'Udhibiti wa wadudu',
          type: 'pdf',
          excerpt:
              'Tambua viwavi, vidukari na ukungu mapema kabla ya kuchagua dawa au hatua ya shamba.',
        ),
      );
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return _answer(
        'Kwa kuku, zingatia banda lenye hewa, usafi, maji safi, chakula bora na ratiba ya chanjo. Usafi wa banda hupunguza magonjwa.',
        const MwalimuAiSource(
          id: 'kuku:misingi-ya-ufugaji-wa-kuku',
          courseId: 'kuku',
          lessonId: 'misingi-ya-ufugaji-wa-kuku',
          courseTitle: 'Ufugaji wa Kuku',
          title: 'Misingi ya ufugaji wa kuku',
          type: 'video',
          excerpt:
              'Jifunze mahitaji ya banda, maji, chakula na usafi kabla ya kuleta vifaranga.',
        ),
      );
    }
    if (lower.contains('wadudu') || lower.contains('viwavi')) {
      return _plain(
          'Kwa wadudu, kagua chini ya majani asubuhi au jioni, tambua kama ni viwavi, vidukari au funza, kisha ondoa sehemu zilizoathirika. Usitumie dawa kabla ya kujua mdudu na kiwango cha madhara.');
    }
    if (lower.contains('mbolea') || lower.contains('udongo')) {
      return _plain(
          'Kwa mbolea na udongo, angalia rangi ya majani, ukuaji wa mmea na historia ya shamba. Kama huna kipimo cha udongo, anza na samadi iliyoiva vizuri na fuata dozi ndogo ya mbolea kulingana na zao.');
    }
    if (lower.contains('maji') || lower.contains('umwagiliaji')) {
      return _plain(
          'Kwa maji, hakikisha udongo una unyevu lakini hautuamishi maji. Mwagilia asubuhi au jioni, tengeneza mifereji midogo kama maji yanasimama, na punguza kumwagilia kama majani yanaonekana kulegea baada ya mvua.');
    }
    if (lower.contains('soko') || lower.contains('bei')) {
      return _plain(
          'Kwa soko, linganisha bei kwa wanunuzi wawili au watatu, panga kuvuna kulingana na ubora unaotakiwa, na hifadhi mazao sehemu yenye kivuli kabla ya kusafirisha.');
    }
    return _plain(
        'Sina taarifa ya kutosha kwenye maelezo yako. Eleza zao au mnyama, eneo, dalili kuu, na muda ambao tatizo limeanza ili nipendekeze hatua salama inayofuata.');
  }
}

MwalimuAiAnswer _answer(String text, MwalimuAiSource source) {
  return MwalimuAiAnswer(text: text, sources: [source]);
}

MwalimuAiAnswer _plain(String text) {
  return MwalimuAiAnswer(text: text);
}

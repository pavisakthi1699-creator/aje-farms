import 'mwalimu_ai_service.dart';

class DemoMwalimuAiService implements MwalimuAiService {
  const DemoMwalimuAiService();

  @override
  Future<MwalimuAiAnswer> answer(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lower = prompt.toLowerCase();
    if (lower.contains('pasheni')) {
      return _answer(
        'Kwa pasheni, rekodi hali ya majani, shina, unyevu na muda ambao dalili zimeonekana. Piga picha ya sehemu iliyoathirika na wasiliana na mtaalamu wa eneo lako kabla ya kutumia dawa.',
        const MwalimuAiSource(
          id: 'pasheni:kufuatilia-afya-ya-mmea',
          courseId: 'pasheni',
          lessonId: 'kufuatilia-afya-ya-mmea',
          courseTitle: 'Kilimo cha Pasheni',
          title: 'Kufuatilia afya ya mmea',
          type: 'reading',
          excerpt:
              'Kagua majani, shina na unyevu mara kwa mara, kisha pata uthibitisho wa mtaalamu kabla ya kutumia tiba.',
        ),
      );
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return _answer(
        'Kwa nyanya, piga picha ya dalili, rekodi sehemu ya mmea iliyoathirika na hali ya unyevu. Usichague dawa kwa jina la dalili pekee; pata utambuzi wa mtaalamu wa eneo lako.',
        const MwalimuAiSource(
          id: 'nyanya:kufuatilia-miche-na-mimea',
          courseId: 'nyanya',
          lessonId: 'kufuatilia-miche-na-mimea',
          courseTitle: 'Kilimo cha Nyanya',
          title: 'Kufuatilia miche na mimea',
          type: 'reading',
          excerpt:
              'Kagua majani na ukuaji, rekodi dalili na tambua tatizo kwa msaada wa mtaalamu kabla ya kutumia dawa.',
        ),
      );
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return _answer(
        'Kwa kuku, rekodi umri, idadi, dalili na muda zilipoanza. Tenga kuku mwenye dalili kali inapowezekana na wasiliana na daktari wa mifugo kwa utambuzi, chanjo au dawa.',
        const MwalimuAiSource(
          id: 'kuku:kuweka-kumbukumbu-za-afya',
          courseId: 'kuku',
          lessonId: 'kuweka-kumbukumbu-za-afya',
          courseTitle: 'Ufugaji wa Kuku',
          title: 'Kuweka kumbukumbu za afya',
          type: 'reading',
          excerpt:
              'Rekodi dalili na historia ya kundi, kisha tumia mwongozo wa daktari wa mifugo kwa chanjo na dawa.',
        ),
      );
    }
    if (lower.contains('wadudu') || lower.contains('viwavi')) {
      return _plain(
          'Kwa wadudu, piga picha ya mdudu na sehemu iliyoathirika, rekodi zao na eneo, kisha pata utambuzi kabla ya kuchagua hatua. Usitumie dawa usiyoifahamu.');
    }
    if (lower.contains('mbolea') || lower.contains('udongo')) {
      return _plain(
          'Kwa mbolea na udongo, rekodi zao, hatua ya ukuaji na historia ya shamba. Kipimo cha udongo na ushauri wa mtaalamu wa eneo lako vinahitajika kabla ya kuchagua aina au kipimo cha mbolea.');
    }
    if (lower.contains('maji') || lower.contains('umwagiliaji')) {
      return _plain(
          'Kwa maji, rekodi zao, aina ya udongo, mvua na hali ya unyevu. Kagua kama maji yanasimama au udongo umekauka, kisha linganisha na mwongozo wa zao na eneo lako.');
    }
    if (lower.contains('soko') || lower.contains('bei')) {
      return _plain(
          'Kwa soko, thibitisha tarehe, eneo, daraja la bidhaa na chanzo cha bei. Linganisha taarifa kutoka zaidi ya mnunuzi mmoja kabla ya kufanya uamuzi.');
    }
    return _plain(
        'Sina taarifa ya kutosha kwenye maelezo yako. Eleza zao au mnyama, eneo, dalili kuu, na muda ambao tatizo limeanza ili nipendekeze hatua salama inayofuata.');
  }

  @override
  Future<void> reportAnswer(
    String messageId, {
    required String reason,
    String? details,
  }) async {}
}

MwalimuAiAnswer _answer(String text, MwalimuAiSource source) {
  return MwalimuAiAnswer(text: text, sources: [source]);
}

MwalimuAiAnswer _plain(String text) {
  return MwalimuAiAnswer(text: text);
}

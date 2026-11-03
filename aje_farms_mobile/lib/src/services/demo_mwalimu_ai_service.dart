import 'mwalimu_ai_service.dart';

class DemoMwalimuAiService implements MwalimuAiService {
  const DemoMwalimuAiService();

  @override
  Future<MwalimuAiAnswer> answer(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lower = prompt.toLowerCase();
    if (lower.contains('pasheni') || lower.contains('passion')) {
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
    if (lower.contains('nyanya') ||
        lower.contains('ukungu') ||
        lower.contains('tomato') ||
        lower.contains('fungus') ||
        lower.contains('blight')) {
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
    if (lower.contains('kuku') ||
        lower.contains('ufugaji') ||
        lower.contains('chicken') ||
        lower.contains('poultry') ||
        lower.contains('hen') ||
        lower.contains('livestock')) {
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
    if (lower.contains('wadudu') ||
        lower.contains('viwavi') ||
        lower.contains('pest') ||
        lower.contains('insect') ||
        lower.contains('caterpillar') ||
        lower.contains('bug')) {
      return _plain(
          'Kwa wadudu, piga picha ya mdudu na sehemu iliyoathirika, rekodi zao na eneo, kisha pata utambuzi kabla ya kuchagua hatua. Usitumie dawa usiyoifahamu.');
    }
    if (lower.contains('mbolea') ||
        lower.contains('udongo') ||
        lower.contains('fertilizer') ||
        lower.contains('soil') ||
        lower.contains('nutrient') ||
        lower.contains('fertility')) {
      return _plain(
          'Kwa mbolea na udongo, rekodi zao, hatua ya ukuaji na historia ya shamba. Kipimo cha udongo na ushauri wa mtaalamu wa eneo lako vinahitajika kabla ya kuchagua aina au kipimo cha mbolea.');
    }
    if (lower.contains('maji') ||
        lower.contains('umwagiliaji') ||
        lower.contains('water') ||
        lower.contains('irrigation') ||
        lower.contains('drought')) {
      return _plain(
          'Kwa maji, rekodi zao, aina ya udongo, mvua na hali ya unyevu. Kagua kama maji yanasimama au udongo umekauka, kisha linganisha na mwongozo wa zao na eneo lako.');
    }
    if (lower.contains('soko') ||
        lower.contains('bei') ||
        lower.contains('market') ||
        lower.contains('price')) {
      return _plain(
          'Kwa soko, thibitisha tarehe, eneo, daraja la bidhaa na chanzo cha bei. Linganisha taarifa kutoka zaidi ya mnunuzi mmoja kabla ya kufanya uamuzi.');
    }
    if (lower.contains('habari') ||
        lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('mambo') ||
        lower == 'ok' ||
        lower == 'hi ok') {
      return _plain(
          'Habari! Mimi ni Mwalimu AI, msaidizi wako wa kilimo na ufugaji. Unaweza kuniuliza kuhusu magonjwa ya mazao, ratiba ya maji, mbolea, au afya ya mifugo.');
    }
    if (lower.contains('dalili gani') ||
        lower.contains('symptoms') ||
        lower.contains('rekodi dalili')) {
      return _plain(
          'Ili kurekodi dalili kwa usahihi: 1) Angalia rangi na mabadiliko ya majani, shina, au matunda. 2) Rekodi lini dalili zilianza na jinsi zinavyoenea. 3) Pima unyevu wa udongo na hali ya hewa. 4) Piga picha wazi kabla ya kutumia tiba yoyote.');
    }
    if (lower.contains('hatua salama') || lower.contains('safe first step')) {
      return _plain(
          'Hatua salama ya kwanza: 1) Tenga mmea au mnyama mwenye dalili kali ili kuzuia maambukizi. 2) Usitumie kemikali bila utambuzi rasmi. 3) Piga picha na chukua maelezo kamili. 4) Wasiliana na mtaalamu wa kilimo au mifugo wa eneo lako.');
    }
    if (lower.contains('picha') || lower.contains('photo')) {
      return _plain(
          'Piga picha hizi tatu muhimu: 1) Picha ya karibu ya sehemu iliyoathirika (jani, shina, tunda). 2) Picha ya mmea mzima kutoka juu hadi chini. 3) Picha ya shamba zima ili kuona ukubwa na mwelekeo wa shambulio.');
    }
    if (lower.contains('taarifa gani') ||
        lower.contains('information do i need')) {
      return _plain(
          'Taarifa unazohitaji kuandaa ni: jina la zao au mnyama, hatua ya ukuaji au umri, lini tatizo lilianza, eneo la shamba lako, na aina ya mbolea au dawa uliyotumia hivi karibuni.');
    }
    if (lower.contains('pime udongo') || lower.contains('soil test')) {
      return _plain(
          'Ndio, kupima udongo ni muhimu kujua kiwango cha pH na virutubisho (N, P, K). Hii inakusaidia kuchagua mbolea sahihi bila kupoteza fedha au kuharibu udongo.');
    }
    if (lower.contains('historia ya shamba') ||
        lower.contains('farm history')) {
      return _plain(
          'Historia ya shamba inajumuisha mazao yaliyolimwa msimu uliopita (mzunguko wa mazao), magonjwa yaliyowahi kutokea, na aina ya mbolea au viuatilifu vilivyotumika miaka miwili iliyopita.');
    }
    if (lower.contains('ratiba ya kumwagilia') ||
        lower.contains('watering schedule')) {
      return _plain(
          'Mwaga maji asubuhi na mapema au jioni jua likishatua ili kuzuia upotevu wa maji kwa mvuke. Kagua unyevu wa udongo kwa kidole kirefu cha sentimita tano kabla ya kumwagilia tena.');
    }
    if (lower.contains('maji yanasimama') ||
        lower.contains('water is standing') ||
        lower.contains('waterlog')) {
      return _plain(
          'Maji yakisimama shambani yanaweza kuozesha mizizi na kuleta magonjwa ya ukungu. Chimba mifereji ya kupitishia maji mara moja na uache kumwagilia hadi ardhi ikauke.');
    }
    if (lower.contains('dalili za ukame') ||
        lower.contains('signs of drought')) {
      return _plain(
          'Dalili za ukame ni majani kujikunja au kunyauka katikati ya mchana, udongo kupasuka, na ukuaji kusimama. Weka matandazo (mulching) kuhifadhi unyevu uliopo.');
    }
    if (lower.contains('usafi wa banda') || lower.contains('coop hygiene')) {
      return _plain(
          'Kuhusu usafi wa banda: Badilisha matandiko (maranda) mara yanapokuwa na unyevu, fanya usafi kwa dawa ya kuua wadudu na vimelea kila wiki, na hakikisha kuna hewa ya kutosha.');
    }
    if (lower.contains('daktari') ||
        lower.contains('veterinarian') ||
        lower.contains('vet')) {
      return _plain(
          'Unaweza kupata daktari wa mifugo kwa kuwasiliana na afisa ugani wa kata yako, au kutumia kitufe cha "Msaidizi wa Binadamu" hapa chini kwa msaada wa haraka kupitia WhatsApp.');
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

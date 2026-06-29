import 'mwalimu_ai_service.dart';

class DemoMwalimuAiService implements MwalimuAiService {
  const DemoMwalimuAiService();

  @override
  Future<String> answer(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lower = prompt.toLowerCase();
    if (lower.contains('pasheni')) {
      return 'Kwa pasheni, hakikisha udongo unapisha maji vizuri na eneo halituamishi maji. Angalia kama kuna majani ya njano, madoa au wadudu chini ya jani kabla ya kuchagua dawa. Tumia nguzo na waya kusaidia mmea kupanda vizuri.\n\nChanzo: Mwongozo mfupi wa pasheni';
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return 'Kwa nyanya, anza kwa kutenga miche iliyoathirika, epuka maji kusimama kwenye shina, na fuatilia ukungu chini ya majani. Ondoa majani yaliyoathirika na tumia ushauri wa mtaalamu kabla ya dawa.\n\nChanzo: Mwongozo mfupi wa nyanya';
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return 'Kwa kuku, zingatia banda lenye hewa, usafi, maji safi, chakula bora na ratiba ya chanjo. Usafi wa banda hupunguza magonjwa.\n\nChanzo: Mwongozo wa kuku kwa wanaoanza';
    }
    if (lower.contains('wadudu') || lower.contains('viwavi')) {
      return 'Kwa wadudu, kagua chini ya majani asubuhi au jioni, tambua kama ni viwavi, vidukari au funza, kisha ondoa sehemu zilizoathirika. Usitumie dawa kabla ya kujua mdudu na kiwango cha madhara.\n\nChanzo: Udhibiti wa wadudu kwenye mazao';
    }
    if (lower.contains('mbolea') || lower.contains('udongo')) {
      return 'Kwa mbolea na udongo, angalia rangi ya majani, ukuaji wa mmea na historia ya shamba. Kama huna kipimo cha udongo, anza na samadi iliyoiva vizuri na fuata dozi ndogo ya mbolea kulingana na zao.\n\nChanzo: Mwongozo wa rutuba ya udongo';
    }
    if (lower.contains('maji') || lower.contains('umwagiliaji')) {
      return 'Kwa maji, hakikisha udongo una unyevu lakini hautuamishi maji. Mwagilia asubuhi au jioni, tengeneza mifereji midogo kama maji yanasimama, na punguza kumwagilia kama majani yanaonekana kulegea baada ya mvua.\n\nChanzo: Ratiba salama ya umwagiliaji';
    }
    if (lower.contains('soko') || lower.contains('bei')) {
      return 'Kwa soko, linganisha bei kwa wanunuzi wawili au watatu, panga kuvuna kulingana na ubora unaotakiwa, na hifadhi mazao sehemu yenye kivuli kabla ya kusafirisha.\n\nChanzo: Mwongozo wa maandalizi ya soko';
    }
    return 'Hili ni jibu la mfano lililofungwa kwenye maarifa yaliyoidhinishwa. Eleza zao, eneo, dalili, na muda wa tatizo ili nipendekeze hatua inayofuata.\n\nChanzo: Taarifa zilizoidhinishwa';
  }
}

import 'mwalimu_ai_service.dart';

class DemoMwalimuAiService implements MwalimuAiService {
  const DemoMwalimuAiService();

  @override
  Future<String> answer(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final lower = prompt.toLowerCase();
    if (lower.contains('pasheni')) {
      return 'Kwa pasheni, hakikisha udongo unapisha maji vizuri na eneo halituamishi maji. Tumia nguzo na waya kusaidia mmea kupanda vizuri.\n\nChanzo: Mwongozo mfupi wa pasheni';
    }
    if (lower.contains('nyanya') || lower.contains('ukungu')) {
      return 'Kwa nyanya, anza na kitalu bora, epuka maji kusimama, na fuatilia dalili za ukungu mapema. Ondoa majani yaliyoathirika na tumia ushauri wa mtaalamu kabla ya dawa.\n\nChanzo: Mwongozo mfupi wa nyanya';
    }
    if (lower.contains('kuku') || lower.contains('ufugaji')) {
      return 'Kwa kuku, zingatia banda lenye hewa, usafi, maji safi, chakula bora na ratiba ya chanjo. Usafi wa banda hupunguza magonjwa.\n\nChanzo: Mwongozo wa kuku kwa wanaoanza';
    }
    return 'Hili ni jibu la mfano lililofungwa kwenye maarifa yaliyoidhinishwa. Eleza zao, eneo, dalili, na muda wa tatizo ili nipendekeze hatua inayofuata.\n\nChanzo: Taarifa zilizoidhinishwa';
  }
}

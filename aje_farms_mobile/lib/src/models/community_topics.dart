import 'home_topics.dart';

const defaultCommunityTopics = <String>[
  'Magonjwa',
  'Mifugo',
  'Masoko',
  'Kuku',
  'Nyanya',
];

List<String>? parseCommunityTopics(Object? value) {
  final topics = parseHomeTopics(value);
  if (topics == null || topics.any((topic) => topic.toLowerCase() == 'zote')) {
    return null;
  }
  return topics;
}

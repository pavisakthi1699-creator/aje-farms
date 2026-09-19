const defaultHomeTopics = <String>[
  'Matunda na Mbogamboga',
  'Nafaka',
  'Mifugo',
  'Mengineyo',
];

const minHomeTopics = 1;
const maxHomeTopics = 12;
const maxHomeTopicLength = 40;

List<String>? parseHomeTopics(Object? value) {
  if (value is! List ||
      value.length < minHomeTopics ||
      value.length > maxHomeTopics) {
    return null;
  }
  final topics =
      value.whereType<String>().map((topic) => topic.trim()).toList();
  if (topics.length != value.length ||
      topics
          .any((topic) => topic.isEmpty || topic.length > maxHomeTopicLength)) {
    return null;
  }
  if (topics.map((topic) => topic.toLowerCase()).toSet().length !=
      topics.length) {
    return null;
  }
  return List.unmodifiable(topics);
}

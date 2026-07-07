import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

import '../models/community_post.dart';
import '../services/auth_service.dart';
import '../services/backend_session_storage.dart';
import '../theme/app_theme_preference.dart';

class AppSessionState {
  const AppSessionState({
    this.hasStarted = false,
    this.isGuest = false,
    this.phoneNumber,
    this.completedLessonIds = const {},
    this.localPosts = const [],
    this.localRepliesByPostId = const {},
    this.reportedPostIds = const {},
    this.savedDocumentIds = const {},
    this.assessmentScores = const {},
    this.subscriptionPlan,
    this.subscriptionStartedAt,
    this.notificationsEnabled = true,
    this.preferredLocation,
    this.themePreference = AppThemePreference.system,
  });

  final bool hasStarted;
  final bool isGuest;
  final String? phoneNumber;
  final Set<String> completedLessonIds;
  final List<CommunityPost> localPosts;
  final Map<String, List<CommunityReply>> localRepliesByPostId;
  final Set<String> reportedPostIds;
  final Set<String> savedDocumentIds;
  final Map<String, int> assessmentScores;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;
  final bool notificationsEnabled;
  final String? preferredLocation;
  final AppThemePreference themePreference;

  bool get hasActiveSubscription => subscriptionPlan != null;

  AppSessionState copyWith({
    bool? hasStarted,
    bool? isGuest,
    String? phoneNumber,
    Set<String>? completedLessonIds,
    List<CommunityPost>? localPosts,
    Map<String, List<CommunityReply>>? localRepliesByPostId,
    Set<String>? reportedPostIds,
    Set<String>? savedDocumentIds,
    Map<String, int>? assessmentScores,
    String? subscriptionPlan,
    DateTime? subscriptionStartedAt,
    bool? notificationsEnabled,
    String? preferredLocation,
    AppThemePreference? themePreference,
    bool clearPhoneNumber = false,
    bool clearSubscription = false,
    bool clearPreferredLocation = false,
  }) {
    return AppSessionState(
      hasStarted: hasStarted ?? this.hasStarted,
      isGuest: isGuest ?? this.isGuest,
      phoneNumber: clearPhoneNumber ? null : phoneNumber ?? this.phoneNumber,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      localPosts: localPosts ?? this.localPosts,
      localRepliesByPostId: localRepliesByPostId ?? this.localRepliesByPostId,
      reportedPostIds: reportedPostIds ?? this.reportedPostIds,
      savedDocumentIds: savedDocumentIds ?? this.savedDocumentIds,
      assessmentScores: assessmentScores ?? this.assessmentScores,
      subscriptionPlan:
          clearSubscription ? null : subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartedAt: clearSubscription
          ? null
          : subscriptionStartedAt ?? this.subscriptionStartedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLocation: clearPreferredLocation
          ? null
          : preferredLocation ?? this.preferredLocation,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

class AppSessionController extends ChangeNotifier {
  AppSessionController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _hasStartedKey = 'app_session.has_started';
  static const _isGuestKey = 'app_session.is_guest';
  static const _phoneNumberKey = 'app_session.phone_number';
  static const _completedLessonsKey = 'app_session.completed_lesson_ids';
  static const _localPostsKey = 'app_session.local_posts';
  static const _localRepliesKey = 'app_session.local_replies';
  static const _reportedPostsKey = 'app_session.reported_post_ids';
  static const _savedDocumentsKey = 'app_session.saved_document_ids';
  static const _assessmentScoresKey = 'app_session.assessment_scores';
  static const _subscriptionPlanKey = 'app_session.subscription_plan';
  static const _subscriptionStartedAtKey =
      'app_session.subscription_started_at';
  static const _notificationsEnabledKey = 'app_session.notifications_enabled';
  static const _preferredLocationKey = 'app_session.preferred_location';
  static const _themePreferenceKey = 'app_session.theme_preference';

  SharedPreferences? _preferences;
  AppSessionState _state = const AppSessionState();

  AppSessionState get state => _state;

  bool get hasStarted => _state.hasStarted;
  bool get isSignedIn => !_state.isGuest && _state.phoneNumber != null;
  String? get phoneNumber => _state.phoneNumber;
  bool get hasActiveSubscription => _state.hasActiveSubscription;

  Future<void> restore() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    _state = AppSessionState(
      hasStarted: preferences.getBool(_hasStartedKey) ?? false,
      isGuest: preferences.getBool(_isGuestKey) ?? false,
      phoneNumber: preferences.getString(_phoneNumberKey),
      completedLessonIds:
          preferences.getStringList(_completedLessonsKey)?.toSet() ?? {},
      localPosts:
          _decodePosts(preferences.getStringList(_localPostsKey) ?? const []),
      localRepliesByPostId:
          _decodeReplies(preferences.getString(_localRepliesKey)),
      reportedPostIds:
          preferences.getStringList(_reportedPostsKey)?.toSet() ?? {},
      savedDocumentIds:
          preferences.getStringList(_savedDocumentsKey)?.toSet() ?? {},
      assessmentScores:
          _decodeScores(preferences.getString(_assessmentScoresKey)),
      subscriptionPlan: preferences.getString(_subscriptionPlanKey),
      subscriptionStartedAt:
          _decodeDate(preferences.getString(_subscriptionStartedAtKey)),
      notificationsEnabled:
          preferences.getBool(_notificationsEnabledKey) ?? true,
      preferredLocation: preferences.getString(_preferredLocationKey),
      themePreference: AppThemePreference.fromStorage(
        preferences.getString(_themePreferenceKey),
      ),
    );
    notifyListeners();
  }

  Future<void> startAsGuest() async {
    _state = _state.copyWith(
      hasStarted: true,
      isGuest: true,
      clearPhoneNumber: true,
    );
    notifyListeners();
    await _save();
  }

  Future<void> signInWithPhone(
    String phoneNumber, {
    String? sessionToken,
  }) async {
    _state = _state.copyWith(
      hasStarted: true,
      isGuest: false,
      phoneNumber: phoneNumber,
    );
    notifyListeners();
    if (sessionToken != null) {
      await BackendSessionStorage.writeToken(sessionToken);
    }
    await _save();
  }

  Future<void> signOut() async {
    _state = const AppSessionState();
    notifyListeners();
    await BackendSessionStorage.writeToken(null);
    await _save();
  }

  bool isLessonCompleted(String lessonId) {
    return _state.completedLessonIds.contains(lessonId);
  }

  Future<void> markLessonCompleted(String lessonId) async {
    if (_state.completedLessonIds.contains(lessonId)) return;
    _state = _state.copyWith(
      completedLessonIds: {..._state.completedLessonIds, lessonId},
    );
    notifyListeners();
    await _save();
  }

  Future<void> syncCompletedLessons(Set<String> lessonIds) async {
    final next = {..._state.completedLessonIds, ...lessonIds};
    if (next.length == _state.completedLessonIds.length) return;
    _state = _state.copyWith(completedLessonIds: next);
    notifyListeners();
    await _save();
  }

  Future<void> saveDocument(String documentId) async {
    _state = _state.copyWith(
      savedDocumentIds: {..._state.savedDocumentIds, documentId},
    );
    notifyListeners();
    await _save();
  }

  Future<void> removeSavedDocument(String documentId) async {
    final next = {..._state.savedDocumentIds}..remove(documentId);
    _state = _state.copyWith(savedDocumentIds: next);
    notifyListeners();
    await _save();
  }

  bool isDocumentSaved(String documentId) {
    return _state.savedDocumentIds.contains(documentId);
  }

  Future<void> activateSubscription(
    String planTitle, {
    DateTime? startedAt,
  }) async {
    _state = _state.copyWith(
      subscriptionPlan: planTitle,
      subscriptionStartedAt: startedAt ?? DateTime.now(),
    );
    notifyListeners();
    await _save();
  }

  Future<void> cancelSubscription() async {
    _state = _state.copyWith(clearSubscription: true);
    notifyListeners();
    await _save();
  }

  Future<void> syncSubscriptionFromAuthSession(AuthSession session) async {
    if (session.sessionToken != null) {
      await BackendSessionStorage.writeToken(session.sessionToken);
    }
    final subscriptionPlan = session.subscriptionPlan;
    if (subscriptionPlan == null) {
      await cancelSubscription();
      return;
    }
    await activateSubscription(
      subscriptionPlan,
      startedAt: session.subscriptionStartedAt,
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _state = _state.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await _save();
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    _state = _state.copyWith(themePreference: preference);
    notifyListeners();
    await _save();
  }

  Future<void> setPreferredLocation(String? location) async {
    _state = _state.copyWith(
      preferredLocation: location?.trim().isEmpty ?? true ? null : location,
      clearPreferredLocation: location?.trim().isEmpty ?? true,
    );
    notifyListeners();
    await _save();
  }

  Future<void> saveAssessmentScore(String assessmentId, int score) async {
    _state = _state.copyWith(
      assessmentScores: {..._state.assessmentScores, assessmentId: score},
    );
    notifyListeners();
    await _save();
  }

  Future<void> addCommunityPost({
    required String content,
    required String location,
    required List<String> tags,
  }) async {
    final post = CommunityPost(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      author: isSignedIn ? phoneNumber! : 'Wewe',
      location: location,
      time: 'Sasa hivi',
      content: content,
      likes: 0,
      comments: 0,
      tags: tags,
      replies: const [],
      isUrgent: tags.contains('Magonjwa') || tags.contains('Wadudu'),
    );
    await addCommunityPostRecord(post);
  }

  Future<void> addCommunityPostRecord(CommunityPost post) async {
    _state = _state.copyWith(localPosts: [post, ..._state.localPosts]);
    notifyListeners();
    await _save();
  }

  Future<void> addCommunityReply(String postId, String body) async {
    await addCommunityReplyRecord(
      postId,
      CommunityReply(
        author: isSignedIn ? phoneNumber! : 'Wewe',
        body: body,
        time: 'Sasa hivi',
      ),
    );
  }

  Future<void> addCommunityReplyRecord(
    String postId,
    CommunityReply reply,
  ) async {
    final replies = _state.localRepliesByPostId[postId] ?? const [];
    final nextReplies = [...replies, reply];
    _state = _state.copyWith(
      localRepliesByPostId: {
        ..._state.localRepliesByPostId,
        postId: nextReplies,
      },
    );
    notifyListeners();
    await _save();
  }

  List<CommunityReply> repliesFor(String postId) {
    return _state.localRepliesByPostId[postId] ?? const [];
  }

  Future<void> reportCommunityPost(String postId) async {
    _state = _state.copyWith(
      reportedPostIds: {..._state.reportedPostIds, postId},
    );
    notifyListeners();
    await _save();
  }

  bool isPostReported(String postId) {
    return _state.reportedPostIds.contains(postId);
  }

  Future<void> _save() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    await preferences.setBool(_hasStartedKey, _state.hasStarted);
    await preferences.setBool(_isGuestKey, _state.isGuest);
    final phoneNumber = _state.phoneNumber;
    if (phoneNumber == null) {
      await preferences.remove(_phoneNumberKey);
    } else {
      await preferences.setString(_phoneNumberKey, phoneNumber);
    }
    await preferences.setStringList(
      _completedLessonsKey,
      _state.completedLessonIds.toList()..sort(),
    );
    await preferences.setStringList(
      _localPostsKey,
      _state.localPosts.map(_encodePost).toList(),
    );
    await preferences.setString(
        _localRepliesKey,
        _encodeReplies(
          _state.localRepliesByPostId,
        ));
    await preferences.setStringList(
      _reportedPostsKey,
      _state.reportedPostIds.toList()..sort(),
    );
    await preferences.setStringList(
      _savedDocumentsKey,
      _state.savedDocumentIds.toList()..sort(),
    );
    await preferences.setString(
      _assessmentScoresKey,
      jsonEncode(_state.assessmentScores),
    );
    final subscriptionPlan = _state.subscriptionPlan;
    if (subscriptionPlan == null) {
      await preferences.remove(_subscriptionPlanKey);
      await preferences.remove(_subscriptionStartedAtKey);
    } else {
      await preferences.setString(_subscriptionPlanKey, subscriptionPlan);
      await preferences.setString(
        _subscriptionStartedAtKey,
        (_state.subscriptionStartedAt ?? DateTime.now()).toIso8601String(),
      );
    }
    await preferences.setBool(
      _notificationsEnabledKey,
      _state.notificationsEnabled,
    );
    final preferredLocation = _state.preferredLocation;
    if (preferredLocation == null) {
      await preferences.remove(_preferredLocationKey);
    } else {
      await preferences.setString(_preferredLocationKey, preferredLocation);
    }
    await preferences.setString(
      _themePreferenceKey,
      _state.themePreference.name,
    );
  }
}

DateTime? _decodeDate(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

Map<String, int> _decodeScores(String? raw) {
  if (raw == null) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) return {};
  return decoded.map((key, value) => MapEntry(key, value as int));
}

List<CommunityPost> _decodePosts(List<String> rawPosts) {
  return rawPosts.map((raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return _postFromJson(decoded);
  }).toList();
}

String _encodePost(CommunityPost post) {
  return jsonEncode(_postToJson(post));
}

Map<String, List<CommunityReply>> _decodeReplies(String? raw) {
  if (raw == null) return {};
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map((postId, rawReplies) {
    final replies = (rawReplies as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_replyFromJson)
        .toList();
    return MapEntry(postId, replies);
  });
}

String _encodeReplies(Map<String, List<CommunityReply>> repliesByPostId) {
  return jsonEncode(repliesByPostId.map((postId, replies) {
    return MapEntry(postId, replies.map(_replyToJson).toList());
  }));
}

CommunityPost _postFromJson(Map<String, dynamic> json) {
  return CommunityPost(
    id: json['id'] as String,
    author: json['author'] as String,
    location: json['location'] as String,
    time: json['time'] as String,
    content: json['content'] as String,
    likes: json['likes'] as int,
    comments: json['comments'] as int,
    tags: (json['tags'] as List<dynamic>).cast<String>(),
    replies: (json['replies'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_replyFromJson)
        .toList(),
    relatedTopic: json['relatedTopic'] as String?,
    hasImage: json['hasImage'] as bool? ?? false,
    isExpert: json['isExpert'] as bool? ?? false,
    isUrgent: json['isUrgent'] as bool? ?? false,
  );
}

Map<String, dynamic> _postToJson(CommunityPost post) {
  return {
    'id': post.id,
    'author': post.author,
    'location': post.location,
    'time': post.time,
    'content': post.content,
    'likes': post.likes,
    'comments': post.comments,
    'tags': post.tags,
    'replies': post.replies.map(_replyToJson).toList(),
    'relatedTopic': post.relatedTopic,
    'hasImage': post.hasImage,
    'isExpert': post.isExpert,
    'isUrgent': post.isUrgent,
  };
}

CommunityReply _replyFromJson(Map<String, dynamic> json) {
  return CommunityReply(
    author: json['author'] as String,
    body: json['body'] as String,
    time: json['time'] as String,
    isExpert: json['isExpert'] as bool? ?? false,
  );
}

Map<String, dynamic> _replyToJson(CommunityReply reply) {
  return {
    'author': reply.author,
    'body': reply.body,
    'time': reply.time,
    'isExpert': reply.isExpert,
  };
}

class AppSessionScope extends InheritedNotifier<AppSessionController> {
  const AppSessionScope({
    required AppSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope was not found in the tree.');
    return scope!.notifier!;
  }
}

extension AppSessionContext on BuildContext {
  AppSessionController get session => AppSessionScope.of(this);
}

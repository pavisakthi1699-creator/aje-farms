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
    this.email,
    this.completedLessonIds = const {},
    this.localPosts = const [],
    this.localRepliesByPostId = const {},
    this.reportedPostIds = const {},
    this.savedDocumentIds = const {},
    this.assessmentScores = const {},
    this.subscriptionPlan,
    this.subscriptionStartedAt,
    this.accountStatus,
    this.notificationsEnabled = true,
    this.preferredLocation,
    this.displayName,
    this.role,
    this.themePreference = AppThemePreference.system,
  });

  final bool hasStarted;
  final bool isGuest;
  final String? email;
  final Set<String> completedLessonIds;
  final List<CommunityPost> localPosts;
  final Map<String, List<CommunityReply>> localRepliesByPostId;
  final Set<String> reportedPostIds;
  final Set<String> savedDocumentIds;
  final Map<String, int> assessmentScores;
  final String? subscriptionPlan;
  final DateTime? subscriptionStartedAt;

  /// 'pending_activation' | 'active' | 'suspended'. The only source of truth
  /// for whether paid content is unlocked — see [hasActiveAccess].
  final String? accountStatus;
  final bool notificationsEnabled;
  final String? preferredLocation;
  final String? displayName;
  final String? role;
  final AppThemePreference themePreference;

  bool get hasActiveAccess => accountStatus == 'active';
  bool get isAdmin => role == 'admin';

  /// The community feed: locally submitted posts first, then the server feed.
  ///
  /// A post that the server feed already carries is served from the server copy
  /// only. The local copy exists to bridge the gap between submitting a post
  /// and the next catalog refresh; keeping both showed the post twice, and the
  /// stale local copy was the one missing the uploaded photo.
  List<CommunityPost> communityPostsMergedWith(List<CommunityPost> feedPosts) {
    final feedIds = feedPosts.map((post) => post.id).toSet();
    return [
      ...localPosts.where((post) => !feedIds.contains(post.id)),
      ...feedPosts,
    ];
  }

  AppSessionState copyWith({
    bool? hasStarted,
    bool? isGuest,
    String? email,
    Set<String>? completedLessonIds,
    List<CommunityPost>? localPosts,
    Map<String, List<CommunityReply>>? localRepliesByPostId,
    Set<String>? reportedPostIds,
    Set<String>? savedDocumentIds,
    Map<String, int>? assessmentScores,
    String? subscriptionPlan,
    DateTime? subscriptionStartedAt,
    String? accountStatus,
    bool? notificationsEnabled,
    String? preferredLocation,
    String? displayName,
    String? role,
    AppThemePreference? themePreference,
    bool clearEmail = false,
    bool clearSubscription = false,
    bool clearAccountStatus = false,
    bool clearPreferredLocation = false,
    bool clearDisplayName = false,
    bool clearRole = false,
  }) {
    return AppSessionState(
      hasStarted: hasStarted ?? this.hasStarted,
      isGuest: isGuest ?? this.isGuest,
      email: clearEmail ? null : email ?? this.email,
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
      accountStatus:
          clearAccountStatus ? null : accountStatus ?? this.accountStatus,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLocation: clearPreferredLocation
          ? null
          : preferredLocation ?? this.preferredLocation,
      displayName: clearDisplayName ? null : displayName ?? this.displayName,
      role: clearRole ? null : role ?? this.role,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

class AppSessionController extends ChangeNotifier {
  AppSessionController({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _hasStartedKey = 'app_session.has_started';
  static const _isGuestKey = 'app_session.is_guest';
  static const _emailKey = 'app_session.email';
  static const _completedLessonsKey = 'app_session.completed_lesson_ids';
  static const _localPostsKey = 'app_session.local_posts';
  static const _localRepliesKey = 'app_session.local_replies';
  static const _reportedPostsKey = 'app_session.reported_post_ids';
  static const _savedDocumentsKey = 'app_session.saved_document_ids';
  static const _assessmentScoresKey = 'app_session.assessment_scores';
  static const _subscriptionPlanKey = 'app_session.subscription_plan';
  static const _subscriptionStartedAtKey =
      'app_session.subscription_started_at';
  static const _accountStatusKey = 'app_session.account_status';
  static const _notificationsEnabledKey = 'app_session.notifications_enabled';
  static const _preferredLocationKey = 'app_session.preferred_location';
  static const _displayNameKey = 'app_session.display_name';
  static const _roleKey = 'app_session.role';
  static const _themePreferenceKey = 'app_session.theme_preference';

  SharedPreferences? _preferences;
  AppSessionState _state = const AppSessionState();

  AppSessionState get state => _state;

  bool get hasStarted => _state.hasStarted;
  bool get isSignedIn => !_state.isGuest && _state.email != null;
  String? get email => _state.email;
  bool get hasActiveAccess => _state.hasActiveAccess;
  bool get isAdmin => _state.isAdmin;

  Future<void> restore() async {
    final preferences = _preferences ??= await SharedPreferences.getInstance();
    _state = AppSessionState(
      hasStarted: preferences.getBool(_hasStartedKey) ?? false,
      isGuest: preferences.getBool(_isGuestKey) ?? false,
      email: preferences.getString(_emailKey),
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
      accountStatus: preferences.getString(_accountStatusKey),
      notificationsEnabled:
          preferences.getBool(_notificationsEnabledKey) ?? true,
      preferredLocation: preferences.getString(_preferredLocationKey),
      displayName: preferences.getString(_displayNameKey),
      role: preferences.getString(_roleKey),
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
      clearEmail: true,
      clearRole: true,
    );
    notifyListeners();
    await _save();
  }

  /// Called after Supabase Auth has already established the session (see
  /// [AuthService.signIn]/[AuthService.signUp]) — this only records the
  /// resulting identity locally. It does not touch the bearer token itself;
  /// Supabase owns that (see [BackendSessionStorage]).
  Future<void> signInWithEmail(String email, {String? role}) async {
    _state = _state.copyWith(
      hasStarted: true,
      isGuest: false,
      email: email,
      role: role,
    );
    notifyListeners();
    await _save();
  }

  /// Clears local session state only. Callers must also call
  /// `authService.signOut()` to end the Supabase session itself.
  Future<void> signOut() async {
    _state = const AppSessionState();
    notifyListeners();
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

  /// The only place paid-content gating state is set — always from a fresh
  /// server response, never inferred locally. See [AppSessionState.hasActiveAccess].
  Future<void> syncAccountStatusFromAuthSession(AuthSession session) async {
    _state = _state.copyWith(
      accountStatus: session.accountStatus,
      clearAccountStatus: session.accountStatus == null,
    );
    notifyListeners();
    await _save();
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

  Future<void> syncRoleFromAuthSession(AuthSession session) async {
    _state = _state.copyWith(role: session.role);
    notifyListeners();
    await _save();
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

  Future<void> setDisplayName(String? name) async {
    final trimmed = name?.trim();
    _state = _state.copyWith(
      displayName: trimmed == null || trimmed.isEmpty ? null : trimmed,
      clearDisplayName: trimmed == null || trimmed.isEmpty,
    );
    notifyListeners();
    await _save();
  }

  Future<void> syncProfileFromAuthSession(AuthSession session) async {
    final displayName = session.displayName?.trim();
    final preferredLocation = session.preferredLocation?.trim();
    _state = _state.copyWith(
      displayName:
          displayName == null || displayName.isEmpty ? null : displayName,
      preferredLocation: preferredLocation == null || preferredLocation.isEmpty
          ? null
          : preferredLocation,
      clearDisplayName: displayName == null || displayName.isEmpty,
      clearPreferredLocation:
          preferredLocation == null || preferredLocation.isEmpty,
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
      author: isSignedIn ? (_state.displayName ?? 'Wewe') : 'Wewe',
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
        author: isSignedIn ? (_state.displayName ?? 'Wewe') : 'Wewe',
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
    final email = _state.email;
    if (email == null) {
      await preferences.remove(_emailKey);
    } else {
      await preferences.setString(_emailKey, email);
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
    final accountStatus = _state.accountStatus;
    if (accountStatus == null) {
      await preferences.remove(_accountStatusKey);
    } else {
      await preferences.setString(_accountStatusKey, accountStatus);
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
    final displayName = _state.displayName;
    if (displayName == null) {
      await preferences.remove(_displayNameKey);
    } else {
      await preferences.setString(_displayNameKey, displayName);
    }
    final role = _state.role;
    if (role == null) {
      await preferences.remove(_roleKey);
    } else {
      await preferences.setString(_roleKey, role);
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
    // Persisting `imageUrl` matters: without it a restored post kept
    // `hasImage: true` with no URL and rendered the grey placeholder, which
    // read as the uploaded photo disappearing.
    imageUrl: json['imageUrl'] as String?,
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
    'imageUrl': post.imageUrl,
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

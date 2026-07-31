import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/app_document.dart';
import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';
import 'backend_session_storage.dart';
import 'catalog_service.dart';

class BackendCatalogService implements CatalogService {
  BackendCatalogService({
    required Uri baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<CatalogSnapshot> loadCatalog() async {
    final headers = <String, String>{};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _client
        .get(_baseUrl.resolve('/api/catalog'), headers: headers)
        .timeout(timeout);
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Catalog request failed.',
      );
    }
    if (payload is! Map<String, dynamic>) {
      throw const CatalogException(
          'Catalog service returned an invalid response.');
    }
    return _snapshotFromJson(payload, _baseUrl);
  }

  @override
  Future<String> lessonVideoUrl(String lessonId) async {
    final headers = <String, String>{};
    final token = await BackendSessionStorage.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _client
        .get(
          _baseUrl.resolve(
            '/api/lessons/${Uri.encodeComponent(lessonId)}/video-url',
          ),
          headers: headers,
        )
        .timeout(timeout);
    final payload =
        response.body.isEmpty ? const {} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CatalogException(
        payload is Map<String, dynamic> && payload['error'] is String
            ? payload['error'] as String
            : 'Video haikuweza kufunguka.',
      );
    }
    if (payload is! Map<String, dynamic> || payload['url'] is! String) {
      throw const CatalogException(
          'Catalog service returned an invalid video URL.');
    }
    return payload['url'] as String;
  }
}

CatalogSnapshot _snapshotFromJson(Map<String, dynamic> json, Uri baseUrl) {
  return CatalogSnapshot(
    courses: (json['courses'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((course) => _courseFromJson(course, baseUrl))
        .toList(),
    documents: (json['documents'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_documentFromJson)
        .toList(),
    problemCategories: (json['problemCategories'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_problemCategoryFromJson)
        .toList(),
    communityPosts: (json['communityPosts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_postFromJson)
        .toList(),
    plans: (json['plans'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_planFromJson)
        .toList(),
  );
}

AppDocument _documentFromJson(Map<String, dynamic> json) {
  return AppDocument(
    id: json['id'] as String,
    title: json['title'] as String,
    courseId: json['courseId'] as String,
    courseTitle: json['courseTitle'] as String,
    description: json['description'] as String,
    type: json['type'] as String? ?? 'pdf',
    sizeLabel: json['sizeLabel'] as String? ?? '',
    url: json['url'] as String?,
    isPremium: json['isPremium'] as bool? ?? false,
  );
}

Course _courseFromJson(Map<String, dynamic> json, Uri baseUrl) {
  return Course(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    badge: json['badge'] as String,
    icon: _iconFromWire(json['icon'] as String),
    progress: (json['progress'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String,
    outcomes: (json['outcomes'] as List<dynamic>).cast<String>(),
    lessons: (json['lessons'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((lesson) => _lessonFromJson(lesson, baseUrl))
        .toList(),
  );
}

Lesson _lessonFromJson(Map<String, dynamic> json, Uri baseUrl) {
  final rawResourceUrl = json['resourceUrl'] as String?;
  return Lesson(
    id: json['id'] as String?,
    title: json['title'] as String,
    type: _lessonTypeFromWire(json['type'] as String),
    meta: json['meta'] as String,
    description: json['description'] as String,
    sourceTitle: json['sourceTitle'] as String?,
    resourceUrl: rawResourceUrl == null
        ? null
        : baseUrl.resolve(rawResourceUrl).toString(),
    isPremium: json['isPremium'] as bool? ?? false,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}

ProblemCategory _problemCategoryFromJson(Map<String, dynamic> json) {
  return ProblemCategory(
    title: json['title'] as String,
    topic: json['topic'] as String,
    icon: _iconFromWire(json['icon'] as String),
    color: _colorFromWire(json['color'] as String),
    summary: json['summary'] as String,
    examples: (json['examples'] as List<dynamic>).cast<String>(),
  );
}

PlanOption _planFromJson(Map<String, dynamic> json) {
  return PlanOption(
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    price: json['price'] as String,
    icon: _iconFromWire(json['icon'] as String),
    recommended: json['recommended'] as bool? ?? false,
  );
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

CommunityReply _replyFromJson(Map<String, dynamic> json) {
  return CommunityReply(
    author: json['author'] as String,
    body: json['body'] as String,
    time: json['time'] as String,
    isExpert: json['isExpert'] as bool? ?? false,
  );
}

LessonType _lessonTypeFromWire(String value) {
  return LessonType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => LessonType.reading,
  );
}

IconData _iconFromWire(String value) {
  return switch (value) {
    'bug_report' => Icons.bug_report,
    'calendar_month' => Icons.calendar_month,
    'eco' => Icons.eco,
    'egg_alt' => Icons.egg_alt,
    'grass' => Icons.grass,
    'handshake' => Icons.handshake,
    'local_florist' => Icons.local_florist,
    'menu_book' => Icons.menu_book,
    'play_circle' => Icons.play_circle_outline,
    'spa' => Icons.spa,
    'star' => Icons.star,
    'trending_up' => Icons.trending_up,
    'water_drop' => Icons.water_drop,
    _ => Icons.agriculture,
  };
}

Color _colorFromWire(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return const Color(0xFF188C5B);
  return Color(0xFF000000 | parsed);
}

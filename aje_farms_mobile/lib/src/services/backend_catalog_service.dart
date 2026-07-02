import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/community_post.dart';
import '../models/course.dart';
import '../models/plan_option.dart';
import '../models/problem_category.dart';
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
    final response =
        await _client.get(_baseUrl.resolve('/api/catalog')).timeout(timeout);
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
    return _snapshotFromJson(payload);
  }
}

CatalogSnapshot _snapshotFromJson(Map<String, dynamic> json) {
  return CatalogSnapshot(
    courses: (json['courses'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_courseFromJson)
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

Course _courseFromJson(Map<String, dynamic> json) {
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
        .map(_lessonFromJson)
        .toList(),
  );
}

Lesson _lessonFromJson(Map<String, dynamic> json) {
  return Lesson(
    title: json['title'] as String,
    type: _lessonTypeFromWire(json['type'] as String),
    meta: json['meta'] as String,
    description: json['description'] as String,
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
    orElse: () => LessonType.video,
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

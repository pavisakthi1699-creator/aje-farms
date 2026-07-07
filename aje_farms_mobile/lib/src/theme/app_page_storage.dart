import 'package:flutter/material.dart';

/// Stable [PageStorageKey]s so scroll position survives tab switches and back navigation.
abstract final class AppPageStorage {
  static const dashboard = PageStorageKey<String>('scroll-dashboard');
  static const courses = PageStorageKey<String>('scroll-courses');
  static const aiChat = PageStorageKey<String>('scroll-ai-chat');
  static const community = PageStorageKey<String>('scroll-community');
  static const profile = PageStorageKey<String>('scroll-profile');
  static const notifications = PageStorageKey<String>('scroll-notifications');
  static const savedDocuments = PageStorageKey<String>('scroll-saved-documents');

  static PageStorageKey<String> courseDetail(String courseId) =>
      PageStorageKey('scroll-course-$courseId');

  static PageStorageKey<String> communityPost(String postId) =>
      PageStorageKey('scroll-community-post-$postId');
}

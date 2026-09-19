// Regression tests for the "picture uploads, then disappears" report against
// 0.1.6-build7.
//
// The upload itself works — the server stores the object and serves a public
// `imageUrl`. The image vanished on the client for two reasons:
//
//  1. `AppSessionController` persisted its local copy of a submitted post
//     without `imageUrl`, so after a restart the card had `hasImage: true` and
//     no URL and fell back to the grey placeholder.
//  2. The local copy was never reconciled with the server feed, so once the
//     catalog refreshed the same post appeared twice — the server copy with the
//     photo and the persisted local copy without it.

import 'package:aje_farms_mobile/src/models/community_post.dart';
import 'package:aje_farms_mobile/src/state/app_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const post = CommunityPost(
    id: 'post-1785062842810-dmk0edmqwov',
    author: 'Mkulima feaa',
    location: 'Arusha',
    time: 'Sasa hivi',
    content: 'Nyanya zangu zina madoa meusi kwenye majani.',
    likes: 0,
    comments: 0,
    tags: ['Magonjwa'],
    replies: [],
    imageUrl: 'https://example.supabase.co/storage/v1/object/public/'
        'community-post-images/img-1785062841147-mbgl7q3w18i.jpg',
    hasImage: true,
  );

  test('a submitted post keeps its image URL across a restart', () async {
    final session = AppSessionController();
    await session.signInWithEmail('farmer@aje.test');
    await session.addCommunityPostRecord(post);

    final restored = AppSessionController();
    await restored.restore();

    expect(restored.state.localPosts, hasLength(1));
    expect(restored.state.localPosts.single.hasImage, isTrue);
    expect(restored.state.localPosts.single.imageUrl, post.imageUrl);
  });

  test('a local post is dropped once the server feed carries it', () async {
    final session = AppSessionController();
    await session.signInWithEmail('farmer@aje.test');
    await session.addCommunityPostRecord(post);

    final merged = session.state.communityPostsMergedWith([post]);

    expect(
      merged.where((candidate) => candidate.id == post.id),
      hasLength(1),
      reason: 'The post must not appear twice once the catalog refreshes.',
    );
    expect(merged.single.imageUrl, post.imageUrl);
  });

  test('a local post still shows before the server feed catches up', () async {
    final session = AppSessionController();
    await session.signInWithEmail('farmer@aje.test');
    await session.addCommunityPostRecord(post);

    final merged = session.state.communityPostsMergedWith(const []);

    expect(merged, hasLength(1));
    expect(merged.single.imageUrl, post.imageUrl);
  });
}

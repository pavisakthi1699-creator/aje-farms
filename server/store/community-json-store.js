import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { communityPostImageUrl, createId } from './utils.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function communityDataFilePath() {
  return (
    process.env.AJE_COMMUNITY_DATA_FILE ??
    process.env.AJE_DATA_FILE ??
    path.join(__dirname, '..', 'data.local.json')
  );
}

export class CommunityJsonStore {
  constructor(catalog, filePath = communityDataFilePath(), { persist } = {}) {
    this.catalog = catalog;
    this.filePath = filePath;
    this.persist = persist;
    this.state = this.#load();
  }

  communityPosts() {
    return this.state.communityPosts
      .filter((post) => post.moderationStatus !== 'hidden')
      .map((post) => toPublicPost(post));
  }

  createCommunityPost({
    author,
    authorUserId,
    content,
    location,
    tags,
    imagePath = null,
    isExpert = false,
  }) {
    const normalizedTags = [...new Set(tags.map((tag) => tag.trim()))].filter(
      Boolean,
    );
    const post = {
      id: createId('post'),
      author: author.trim(),
      authorUserId: authorUserId ?? null,
      location: location.trim(),
      time: 'Sasa hivi',
      content: content.trim(),
      likes: 0,
      comments: 0,
      tags: normalizedTags,
      replies: [],
      relatedTopic: normalizedTags[0] ?? null,
      imagePath: imagePath ?? null,
      hasImage: Boolean(imagePath),
      isExpert,
      isUrgent:
        normalizedTags.includes('Magonjwa') ||
        normalizedTags.includes('Wadudu'),
      moderationStatus: 'visible',
    };
    this.state.communityPosts.unshift(post);
    this.#save();
    return toPublicPost(post);
  }

  // Image uploads require Supabase Storage, which the JSON store (local/dev
  // mode) does not have.
  uploadCommunityPostImage() {
    return null;
  }

  communityPostAuthorUserId(postId) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    return post?.authorUserId ?? null;
  }

  addCommunityReply({ postId, author, authorUserId, body, isExpert = false }) {
    const reply = {
      author: author.trim(),
      authorUserId: authorUserId ?? null,
      body: body.trim(),
      time: 'Sasa hivi',
      isExpert,
    };
    const post = this.state.communityPosts.find((item) => item.id === postId);
    if (post) {
      post.replies.push(reply);
      post.comments = post.replies.length;
      this.#save();
    }
    return toPublicReply(reply);
  }

  reportCommunityPost(postId) {
    if (!this.state.reportedPostIds.includes(postId)) {
      this.state.reportedPostIds.push(postId);
      this.#save();
    }
  }

  reportedCommunityPosts() {
    return this.state.reportedPostIds
      .map((postId) => {
        const post = this.state.communityPosts.find((item) => item.id === postId);
        if (!post) return null;
        return {
          post,
          report: {
            postId,
            status: post.moderationStatus === 'hidden' ? 'hidden' : 'open',
          },
        };
      })
      .filter(Boolean);
  }

  resolveCommunityReport({ postId, action, moderatorUserId }) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    if (!post) return null;
    if (action === 'hide') {
      post.moderationStatus = 'hidden';
      post.moderatedAt = new Date().toISOString();
      post.moderatedBy = moderatorUserId;
    }
    this.state.reportedPostIds = this.state.reportedPostIds.filter(
      (item) => item !== postId,
    );
    this.#save();
    return post;
  }

  #load() {
    if (!fs.existsSync(this.filePath)) {
      return initialCommunityState(this.catalog);
    }

    try {
      const raw = fs.readFileSync(this.filePath, 'utf8');
      const parsed = JSON.parse(raw);
      return normalizeCommunityState(parsed, this.catalog);
    } catch (error) {
      throw new Error(
        `Failed to load community store at ${this.filePath}: ${error.message}`,
      );
    }
  }

  #save() {
    if (this.persist) {
      this.persist();
      return;
    }

    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    const tmpPath = `${this.filePath}.tmp`;
    fs.writeFileSync(tmpPath, JSON.stringify(this.state, null, 2));
    fs.renameSync(tmpPath, this.filePath);
  }
}

// `authorUserId` and `moderatedBy` hold internal user ids and must not reach
// the unauthenticated `/api/community/posts` response.
function toPublicReply(reply) {
  const { authorUserId: _authorUserId, ...rest } = reply;
  return rest;
}

function toPublicPost(post) {
  const {
    authorUserId: _authorUserId,
    moderatedAt: _moderatedAt,
    moderatedBy: _moderatedBy,
    imagePath,
    ...rest
  } = post;
  return {
    ...rest,
    imageUrl: communityPostImageUrl(imagePath),
    replies: (post.replies ?? []).map((reply) => toPublicReply(reply)),
  };
}

function initialCommunityState(catalog) {
  return {
    communityPosts: catalog.communityPosts.map((post) => ({
      moderationStatus: 'visible',
      ...post,
      replies: post.replies.map((reply) => ({ ...reply })),
    })),
    reportedPostIds: [],
  };
}

function normalizeCommunityState(raw, catalog) {
  const seed = initialCommunityState(catalog);
  const seedIds = new Set(seed.communityPosts.map((post) => post.id));
  const legacySeedIds = new Set([
    'seed-pasheni-disease',
    'seed-kuku-start',
    'seed-nyanya-market',
  ]);
  const storedPosts = Array.isArray(raw.communityPosts)
    ? raw.communityPosts.filter(
        (post) => !seedIds.has(post.id) && !legacySeedIds.has(post.id),
      )
    : [];
  return {
    communityPosts: [...storedPosts, ...seed.communityPosts],
    reportedPostIds: Array.isArray(raw.reportedPostIds)
      ? raw.reportedPostIds
      : seed.reportedPostIds,
  };
}

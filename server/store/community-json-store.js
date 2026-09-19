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

  communityPosts(viewerUserId = null) {
    const blockedUserIds = new Set(
      this.state.blockedCommunityUsers
        .filter((item) => item.blockerUserId === viewerUserId)
        .map((item) => item.blockedUserId),
    );
    return this.state.communityPosts
      .filter(
        (post) =>
          post.moderationStatus === 'visible' &&
          !blockedUserIds.has(post.authorUserId),
      )
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

  reportCommunityPost({ postId, reporterUserId, reason, details = null }) {
    const post = this.state.communityPosts.find(
      (item) => item.id === postId && item.moderationStatus === 'visible',
    );
    if (!post) return null;
    const existing = this.state.communityReports.find(
      (item) =>
        item.postId === postId &&
        item.reporterUserId === reporterUserId &&
        item.status === 'open',
    );
    if (existing) return existing;
    const report = {
      id: createId('report'),
      postId,
      reporterUserId,
      reason,
      details: details?.trim() || null,
      status: 'open',
      reportedAt: new Date().toISOString(),
      resolvedAt: null,
      resolvedBy: null,
      resolution: null,
    };
    this.state.communityReports.push(report);
    this.state.reportedPostIds = [
      ...new Set([...this.state.reportedPostIds, postId]),
    ];
    this.#save();
    return report;
  }

  reportedCommunityPosts() {
    return this.state.communityPosts
      .filter(
        (post) =>
          this.state.communityReports.some(
            (report) => report.postId === post.id && report.status === 'open',
          ) ||
          (post.moderationStatus === 'hidden' &&
            post.moderatedBy !== 'content-readiness-migration'),
      )
      .map((post) => {
        return {
          post,
          report: {
            postId: post.id,
            reportedAt: latestReportAt(this.state.communityReports, post),
            status: post.moderationStatus === 'hidden' ? 'hidden' : 'open',
            count: this.state.communityReports.filter(
              (report) => report.postId === post.id && report.status === 'open',
            ).length,
            reasons: [
              ...new Set(
                this.state.communityReports
                  .filter(
                    (report) => report.postId === post.id && report.status === 'open',
                  )
                  .map((report) => report.reason),
              ),
            ],
          },
        };
      })
      .sort(
        (left, right) =>
          Date.parse(right.report.reportedAt) -
          Date.parse(left.report.reportedAt),
      );
  }

  resolveCommunityReport({ postId, action, moderatorUserId }) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    if (!post) return null;
    if (action === 'hide') {
      post.moderationStatus = 'hidden';
      post.moderatedAt = new Date().toISOString();
      post.moderatedBy = moderatorUserId;
    } else if (action === 'restore') {
      post.moderationStatus = 'visible';
      post.moderatedAt = new Date().toISOString();
      post.moderatedBy = moderatorUserId;
    }
    const resolvedAt = new Date().toISOString();
    for (const report of this.state.communityReports) {
      if (report.postId !== postId || report.status !== 'open') continue;
      report.status = action === 'dismiss' ? 'dismissed' : 'resolved';
      report.resolvedAt = resolvedAt;
      report.resolvedBy = moderatorUserId;
      report.resolution = action;
    }
    this.state.reportedPostIds = this.state.reportedPostIds.filter(
      (item) => item !== postId,
    );
    this.#save();
    return post;
  }

  blockCommunityPostAuthor({ postId, blockerUserId }) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    const blockedUserId = post?.authorUserId;
    if (!blockedUserId || blockedUserId === blockerUserId) return null;
    if (
      !this.state.blockedCommunityUsers.some(
        (item) =>
          item.blockerUserId === blockerUserId &&
          item.blockedUserId === blockedUserId,
      )
    ) {
      this.state.blockedCommunityUsers.push({
        blockerUserId,
        blockedUserId,
        createdAt: new Date().toISOString(),
      });
      this.#save();
    }
    return { postId, blocked: true };
  }

  unblockCommunityPostAuthor({ postId, blockerUserId }) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    const blockedUserId = post?.authorUserId;
    if (!blockedUserId) return null;
    this.state.blockedCommunityUsers = this.state.blockedCommunityUsers.filter(
      (item) =>
        item.blockerUserId !== blockerUserId ||
        item.blockedUserId !== blockedUserId,
    );
    this.#save();
    return { postId, blocked: false };
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
    communityReports: [],
    blockedCommunityUsers: [],
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
    communityReports: Array.isArray(raw.communityReports)
      ? raw.communityReports
      : (Array.isArray(raw.reportedPostIds) ? raw.reportedPostIds : []).map(
          (postId) => ({
            id: createId('legacy-report'),
            postId,
            reporterUserId: null,
            reason: 'other',
            details: null,
            status: 'open',
            reportedAt: new Date().toISOString(),
            resolvedAt: null,
            resolvedBy: null,
            resolution: null,
          }),
        ),
    blockedCommunityUsers: Array.isArray(raw.blockedCommunityUsers)
      ? raw.blockedCommunityUsers
      : seed.blockedCommunityUsers,
  };
}

function latestReportAt(reports, post) {
  const latest = reports
    .filter((report) => report.postId === post.id && report.status === 'open')
    .sort((left, right) => Date.parse(right.reportedAt) - Date.parse(left.reportedAt))[0];
  return latest?.reportedAt ?? post.moderatedAt ?? post.createdAt ?? new Date().toISOString();
}

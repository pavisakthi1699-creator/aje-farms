import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { createId } from './utils.js';

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
    return this.state.communityPosts.filter(
      (post) => post.moderationStatus !== 'hidden',
    );
  }

  createCommunityPost({ author, content, location, tags }) {
    const normalizedTags = [...new Set(tags.map((tag) => tag.trim()))].filter(
      Boolean,
    );
    const post = {
      id: createId('post'),
      author: author.trim(),
      location: location.trim(),
      time: 'Sasa hivi',
      content: content.trim(),
      likes: 0,
      comments: 0,
      tags: normalizedTags,
      replies: [],
      relatedTopic: normalizedTags[0] ?? null,
      hasImage: false,
      isExpert: false,
      isUrgent:
        normalizedTags.includes('Magonjwa') ||
        normalizedTags.includes('Wadudu'),
      moderationStatus: 'visible',
    };
    this.state.communityPosts.unshift(post);
    this.#save();
    return post;
  }

  addCommunityReply({ postId, author, body }) {
    const reply = {
      author: author.trim(),
      body: body.trim(),
      time: 'Sasa hivi',
      isExpert: false,
    };
    const post = this.state.communityPosts.find((item) => item.id === postId);
    if (post) {
      post.replies.push(reply);
      post.comments = post.replies.length;
      this.#save();
    }
    return reply;
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

  resolveCommunityReport({ postId, action, moderatorPhoneNumber }) {
    const post = this.state.communityPosts.find((item) => item.id === postId);
    if (!post) return null;
    if (action === 'hide') {
      post.moderationStatus = 'hidden';
      post.moderatedAt = new Date().toISOString();
      post.moderatedBy = moderatorPhoneNumber;
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

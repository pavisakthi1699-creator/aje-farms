const SEARCH_SCOPES = new Set(['all', 'learning', 'community', 'documents']);
const MAX_RESULTS = 50;
const DEFAULT_LIMIT = 20;
const SEARCH_BURST_WINDOW_MS = 10_000;
const SEARCH_MINUTE_WINDOW_MS = 60_000;
const SEARCH_USER_BURST_LIMIT = 30;
const SEARCH_USER_MINUTE_LIMIT = 120;
const SEARCH_IP_MINUTE_LIMIT = 600;

const KIND_BOOST = {
  course: 30,
  lesson: 25,
  problem: 20,
  document: 15,
  community: 0,
};

export function parseSearchRequest(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Ombi la utafutaji si sahihi.' };
  }
  const allowed = new Set(['query', 'scope', 'limit', 'savedDocumentIds']);
  if (Object.keys(body).some((key) => !allowed.has(key))) {
    return { error: 'Ombi la utafutaji lina sehemu isiyotambulika.' };
  }

  const query = normalizeSearchText(body.query);
  if ([...query].length < 2 || [...query].length > 120) {
    return { error: 'Andika herufi 2 hadi 120 ili kutafuta.' };
  }
  const scope = body.scope ?? 'all';
  if (typeof scope !== 'string' || !SEARCH_SCOPES.has(scope)) {
    return { error: 'Aina ya utafutaji haitambuliki.' };
  }
  const limit = body.limit ?? DEFAULT_LIMIT;
  if (!Number.isInteger(limit) || limit < 1 || limit > MAX_RESULTS) {
    return { error: `Idadi ya matokeo lazima iwe 1 hadi ${MAX_RESULTS}.` };
  }

  let savedDocumentIds = [];
  if (body.savedDocumentIds != null) {
    if (scope !== 'documents' || !Array.isArray(body.savedDocumentIds)) {
      return { error: 'Nyaraka zilizohifadhiwa zimetumwa vibaya.' };
    }
    if (
      body.savedDocumentIds.some(
        (id) => typeof id !== 'string' || id.length === 0 || id.length > 200,
      )
    ) {
      return { error: 'Orodha ya nyaraka zilizohifadhiwa ni kubwa au si sahihi.' };
    }
    savedDocumentIds = [...new Set(body.savedDocumentIds)];
  }

  return { query, scope, limit, savedDocumentIds };
}

export function createSearchRateLimiter({ now = Date.now } = {}) {
  const userRequests = new Map();
  const ipRequests = new Map();
  let lastSweepAt = 0;

  return function searchRateLimit(req, res, next) {
    const currentTime = now();
    if (currentTime - lastSweepAt >= SEARCH_MINUTE_WINDOW_MS) {
      pruneExpiredBuckets(userRequests, currentTime);
      pruneExpiredBuckets(ipRequests, currentTime);
      lastSweepAt = currentTime;
    }

    const userId = String(req.userId ?? '');
    const ip = String(req.ip ?? req.socket?.remoteAddress ?? 'unknown');
    const userBucket = activeRequests(userRequests.get(userId), currentTime);
    const ipBucket = activeRequests(ipRequests.get(ip), currentTime);
    const burst = userBucket.filter(
      (timestamp) => timestamp > currentTime - SEARCH_BURST_WINDOW_MS,
    );
    const violation =
      limitViolation(burst, SEARCH_USER_BURST_LIMIT, SEARCH_BURST_WINDOW_MS) ??
      limitViolation(
        userBucket,
        SEARCH_USER_MINUTE_LIMIT,
        SEARCH_MINUTE_WINDOW_MS,
      ) ??
      limitViolation(
        ipBucket,
        SEARCH_IP_MINUTE_LIMIT,
        SEARCH_MINUTE_WINDOW_MS,
      );
    if (violation) {
      const retryAfter = Math.max(
        1,
        Math.ceil((violation.oldest + violation.windowMs - currentTime) / 1000),
      );
      res.set('Retry-After', String(retryAfter));
      res.status(429).json({
        error: 'Umetafuta mara nyingi sana. Subiri kidogo kisha ujaribu tena.',
      });
      return;
    }

    userBucket.push(currentTime);
    ipBucket.push(currentTime);
    userRequests.set(userId, userBucket);
    ipRequests.set(ip, ipBucket);
    next();
  };
}

export function searchCatalogSnapshot(snapshot, request) {
  const records = searchableRecords(snapshot, request.scope);
  const savedIds = new Set(request.savedDocumentIds);
  const matches = records
    .map((record) => {
      const relevance = scoreRecord(record, request.query);
      return {
        ...record,
        score:
          relevance > 0 &&
          record.kind === 'document' &&
          savedIds.has(record.id)
            ? relevance + 2000
            : relevance,
      };
    })
    .filter((record) => record.score > 0)
    .sort(compareMatches);

  return {
    query: request.query,
    scope: request.scope,
    results: matches.slice(0, request.limit).map(publicResult),
    truncated: matches.length > request.limit,
  };
}

export function normalizeSearchText(value) {
  if (typeof value !== 'string') return '';
  return value
    .normalize('NFKC')
    .toLocaleLowerCase('und')
    .replace(/[^\p{L}\p{M}\p{N}]+/gu, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function searchableRecords(snapshot, scope) {
  const results = [];
  if (scope === 'all' || scope === 'learning') {
    for (const course of snapshot.courses ?? []) {
      results.push({
        kind: 'course',
        id: course.id,
        parentId: null,
        title: course.title,
        body: [course.description, ...(course.outcomes ?? [])].join(' '),
        tags: [course.badge],
        snippet: course.description || null,
        metadata: 'Kozi',
        isPremium: false,
      });
      for (const lesson of course.lessons ?? []) {
        if (lesson.isLearnerVisible === false) continue;
        results.push({
          kind: 'lesson',
          id:
            lesson.id ??
            normalizeSearchText(lesson.title).replace(/ /g, '-'),
          parentId: course.id,
          title: lesson.title,
          body: lesson.description ?? '',
          tags: [lesson.moduleTitle, lesson.sourceTitle],
          snippet: lesson.description || null,
          metadata: `Somo katika “${course.title}”`,
          isPremium: lesson.isPremium === true,
        });
      }
    }
    for (const problem of snapshot.problemCategories ?? []) {
      results.push({
        kind: 'problem',
        id: normalizeSearchText(problem.topic || problem.title).replace(/ /g, '-'),
        parentId: null,
        title: problem.title,
        body: problem.summary ?? '',
        tags: [problem.topic, ...(problem.examples ?? [])],
        snippet: problem.summary || null,
        metadata: 'Changamoto ya shamba',
        isPremium: false,
      });
    }
  }
  if (scope === 'all' || scope === 'learning' || scope === 'documents') {
    for (const document of snapshot.documents ?? []) {
      results.push({
        kind: 'document',
        id: document.id,
        parentId: document.courseId ?? null,
        title: document.title,
        body: document.description ?? '',
        tags: [document.courseTitle, document.type],
        snippet: document.description || null,
        metadata: [document.type, document.courseTitle].filter(Boolean).join(' · '),
        isPremium: document.isPremium === true,
      });
    }
  }
  if (scope === 'all' || scope === 'community') {
    for (const post of snapshot.communityPosts ?? []) {
      results.push({
        kind: 'community',
        id: post.id,
        parentId: null,
        title: concisePostTitle(post.content),
        body: post.content ?? '',
        tags: [...(post.tags ?? []), post.relatedTopic],
        snippet: post.content || null,
        metadata: [post.location, post.time].filter(Boolean).join(' · '),
        isPremium: false,
      });
    }
  }
  return results;
}

function scoreRecord(record, query) {
  const title = normalizeSearchText(record.title);
  const body = normalizeSearchText(record.body);
  const tags = record.tags.map(normalizeSearchText).filter(Boolean);
  const tokens = query.split(' ');
  let score = KIND_BOOST[record.kind] ?? 0;

  if (title === query) score += 1000;
  if (title.startsWith(query)) score += 600;
  if (tokens.every((token) => title.includes(token))) score += 300;
  const titleSimilarity = Math.max(
    trigramSimilarity(title, query),
    ...title.split(' ').map((word) => trigramSimilarity(word, query)),
  );
  if (titleSimilarity >= 0.3) score += Math.round(titleSimilarity * 200);
  if (tags.some((tag) => tag === query)) score += 160;
  if (tokens.every((token) => `${body} ${tags.join(' ')}`.includes(token))) {
    score += 100;
  }
  if (record.isPremium !== true) score += 10;
  return score > (KIND_BOOST[record.kind] ?? 0) + 10 ? score : 0;
}

function trigramSimilarity(left, right) {
  const leftSet = trigrams(left);
  const rightSet = trigrams(right);
  if (leftSet.size === 0 || rightSet.size === 0) return 0;
  let shared = 0;
  for (const value of leftSet) {
    if (rightSet.has(value)) shared += 1;
  }
  return (2 * shared) / (leftSet.size + rightSet.size);
}

function trigrams(value) {
  const padded = `  ${value} `;
  const chars = [...padded];
  const values = new Set();
  for (let index = 0; index <= chars.length - 3; index += 1) {
    values.add(chars.slice(index, index + 3).join(''));
  }
  return values;
}

function compareMatches(left, right) {
  return (
    right.score - left.score ||
    left.kind.localeCompare(right.kind) ||
    left.id.localeCompare(right.id)
  );
}

function publicResult({ body: _body, tags: _tags, score: _score, ...result }) {
  return result;
}

function concisePostTitle(content) {
  const normalized = String(content ?? '').trim();
  if (normalized.length <= 72) return normalized;
  return `${normalized.slice(0, 69).trimEnd()}…`;
}

function activeRequests(timestamps = [], now) {
  return timestamps.filter(
    (timestamp) => timestamp > now - SEARCH_MINUTE_WINDOW_MS,
  );
}

function limitViolation(timestamps, limit, windowMs) {
  if (timestamps.length < limit) return null;
  return { oldest: timestamps[0], windowMs };
}

function pruneExpiredBuckets(buckets, now) {
  for (const [key, timestamps] of buckets) {
    const active = activeRequests(timestamps, now);
    if (active.length === 0) buckets.delete(key);
    else buckets.set(key, active);
  }
}

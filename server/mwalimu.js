import { GoogleGenAI } from '@google/genai';

import { catalog } from './catalog.js';
import { configuredGeminiApiKey } from './gemini-config.js';
import { approvedCoursesFromCatalog } from './store/utils.js';

const SYSTEM_INSTRUCTION = `
Wewe ni "Mwalimu AI", msaidizi binafsi wa kilimo.
Lugha yako kuu ni Kiswahili tu.
Lazima upate majibu kutoka kwenye vyanzo vya mafunzo vilivyoidhinishwa utakavyopewa pekee.
Kama swali halipo kwenye vyanzo hivyo, jibu: "Samahani, sina taarifa ya kutosha kwenye mafunzo yaliyowekwa. Unaweza kuwasiliana na mtaalamu kupitia WhatsApp."
Usipe ushauri wowote ambao haupo kwenye reference data uliyopewa. Majibu yako yawe mafupi, rahisi kueleweka kwa mkulima.
`;

const NO_SOURCE_REPLY = {
  sw: 'Samahani, sina taarifa ya kutosha kwenye mafunzo yaliyowekwa. Unaweza kuwasiliana na mtaalamu kupitia WhatsApp.',
  en: "Sorry, I don't have enough information in the approved courses. You can contact an expert on WhatsApp.",
};

// The approved sources are written in Kiswahili. For English-interface users
// Gemini still grounds on them but answers in English; the knowledge-base
// fallback (no API key) can only quote the sources as written.
const ENGLISH_INSTRUCTION = `
The learner is using the app in English. Reply in clear, simple English,
translating from the Kiswahili sources. All other rules above still apply.
If the sources do not cover the question, reply exactly:
"${NO_SOURCE_REPLY.en}"
`;

export function normalizeLanguage(value) {
  return value === 'en' ? 'en' : 'sw';
}

function readApiKey() {
  return configuredGeminiApiKey();
}

export async function chatWithMwalimuServer(
  message,
  history = [],
  courses,
  groundingSources,
  { language = 'sw' } = {},
) {
  const lang = normalizeLanguage(language);
  const sources = Array.isArray(groundingSources)
    ? groundingSources
    : findApprovedSources(message, courses);
  const apiKey = readApiKey();
  if (!apiKey) {
    return answerFromKnowledgeBase(message, sources, lang);
  }
  if (sources.length === 0) {
    return { text: NO_SOURCE_REPLY[lang], sources: [] };
  }

  const ai = new GoogleGenAI({
    apiKey,
    httpOptions: { timeout: 15_000 },
  });
  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [
      ...history,
      {
        role: 'user',
        parts: [
          {
            text: [
              `Swali la mkulima: ${message}`,
              '',
              'Vyanzo vilivyoidhinishwa:',
              ...sources.map(
                (source, index) =>
                  `${index + 1}. ${source.title} (${source.courseTitle})\n${source.excerpt}\nRejea: ${source.citation ?? source.sourceTitle ?? 'Mafunzo yaliyoidhinishwa'}`,
              ),
            ].join('\n'),
          },
        ],
      },
    ],
    config: {
      systemInstruction:
        lang === 'en'
          ? `${SYSTEM_INSTRUCTION}\n${ENGLISH_INSTRUCTION}`
          : SYSTEM_INSTRUCTION,
      temperature: 0.2,
      maxOutputTokens: 512,
    },
  });

  return {
    text: response.text ?? '',
    sources,
  };
}

function answerFromKnowledgeBase(_message, sources, lang = 'sw') {
  if (sources.length === 0) {
    return { text: NO_SOURCE_REPLY[lang], sources: [] };
  }

  const primary = sources[0];
  return {
    text: [
      `Kwa ${primary.courseTitle}:`,
      primary.excerpt,
      primary.citation ? `Rejea: ${primary.citation}` : '',
      sources.length > 1
        ? `Pia rejea ${sources.slice(1).map((source) => source.title).join(', ')}.`
        : '',
    ]
      .filter(Boolean)
      .join('\n\n'),
    sources,
  };
}

export function findApprovedSources(
  message,
  courses = approvedCoursesFromCatalog(catalog),
) {
  const terms = tokenize(message);
  if (terms.length === 0) return [];

  return courses
    .flatMap((course) =>
      course.lessons.map((lesson) => {
        const text = [
          course.title,
          course.description,
          ...course.outcomes,
          lesson.title,
          lesson.description,
        ].join(' ');
        const score = scoreText(text, terms);
        return {
          id: `${course.id}:${lesson.id}`,
          courseId: course.id,
          lessonId: lesson.id,
          courseTitle: course.title,
          title: lesson.title,
          type: lesson.type,
          excerpt: lesson.description,
          score,
        };
      }),
    )
    .filter((source) => source.score > 0)
    .sort((left, right) => right.score - left.score)
    .slice(0, 3)
    .map(({ score: _score, ...source }) => source);
}

function tokenize(value) {
  return String(value ?? '')
    .toLowerCase()
    .split(/[^\p{L}\p{N}]+/u)
    .filter((term) => term.length >= 3);
}

function scoreText(text, terms) {
  const haystack = text.toLowerCase();
  return terms.reduce((score, term) => {
    return haystack.includes(term) ? score + 1 : score;
  }, 0);
}

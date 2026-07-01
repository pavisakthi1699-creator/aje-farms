import { GoogleGenAI } from '@google/genai';

import { KNOWLEDGE_BASE } from '../src/knowledgeBase.js';

const SYSTEM_INSTRUCTION = `
Wewe ni "Mwalimu AI", msaidizi binafsi wa kilimo.
Lugha yako kuu ni Kiswahili tu.
Lazima upate majibu kutoka kwenye KNOWLEDGE_BASE uliyopewa pekee.
Kama swali halipo kwenye KNOWLEDGE_BASE, jibu: "Samahani, sina taarifa ya kutosha kwenye mafunzo yaliyowekwa. Unaweza kuwasiliana na mtaalamu kupitia WhatsApp."
Usipe ushauri wowote ambao haupo kwenye reference data uliyopewa. Majibu yako yawe mafupi, rahisi kueleweka kwa mkulima.

Hii ndio KNOWLEDGE_BASE yako:
${KNOWLEDGE_BASE}
`;

function readApiKey() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured on the server.');
  }
  return apiKey;
}

export async function chatWithMwalimuServer(message, history = []) {
  const ai = new GoogleGenAI({ apiKey: readApiKey() });
  const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: [...history, { role: 'user', parts: [{ text: message }] }],
    config: {
      systemInstruction: SYSTEM_INSTRUCTION,
      temperature: 0.2,
    },
  });

  return response.text ?? '';
}

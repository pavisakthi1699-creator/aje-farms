import { GoogleGenAI } from '@google/genai';
import { KNOWLEDGE_BASE } from '../data';

// Initialize the GoogleGenAI client
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

const SYSTEM_INSTRUCTION = `
Wewe ni "Mwalimu AI", msaidizi binafsi wa kilimo. 
Lugha yako kuu ni Kiswahili tu.
Lazima upate majibu kutoka kwenye KNOWLEDGE_BASE uliyopewa pekee.
Kama swali halipo kwenye KNOWLEDGE_BASE, jibu: "Samahani, sina taarifa ya kutosha kwenye mafunzo yaliyowekwa. Unaweza kuwasiliana na mtaalamu kupitia WhatsApp."
Usipe ushauri wowote ambao haupo kwenye reference data uliyopewa. Majibu yako yawe mafupi, rahisi kueleweka kwa mkulima.

Hii ndio KNOWLEDGE_BASE yako:
${KNOWLEDGE_BASE}
`;

export async function chatWithMwalimu(message: string, history: {role: 'user' | 'model', parts: {text: string}[]}[] = []) {
  try {
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        ...history,
        { role: 'user', parts: [{ text: message }] }
      ],
      config: {
        systemInstruction: SYSTEM_INSTRUCTION,
        temperature: 0.2, // low temperature for more factual responses
      }
    });
    
    return response.text;
  } catch (error) {
    console.error("Gemini Error:", error);
    return "Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.";
  }
}

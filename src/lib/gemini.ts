type MwalimuHistoryItem = {
  role: 'user' | 'model';
  parts: { text: string }[];
};

type MwalimuChatResponse = {
  text?: string;
  error?: string;
};

export async function chatWithMwalimu(
  message: string,
  history: MwalimuHistoryItem[] = [],
) {
  try {
    const response = await fetch('/api/mwalimu-chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message, history }),
    });

    const payload = (await response.json()) as MwalimuChatResponse;
    if (!response.ok) {
      throw new Error(payload.error ?? 'Mwalimu AI request failed');
    }

    return payload.text ?? '';
  } catch (error) {
    console.error('Mwalimu AI Error:', error);
    return 'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.';
  }
}

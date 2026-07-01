import { chatWithMwalimuServer } from './mwalimu.js';

export function registerApiRoutes(app) {
  app.post('/api/mwalimu-chat', async (req, res) => {
    const { message, history } = req.body;

    if (typeof message !== 'string' || message.trim().length === 0) {
      res.status(400).json({ error: 'Message is required.' });
      return;
    }

    try {
      const text = await chatWithMwalimuServer(
        message,
        Array.isArray(history) ? history : [],
      );
      res.json({ text });
    } catch (error) {
      console.error('Mwalimu AI server error:', error);
      res.status(500).json({
        error:
          'Samahani, kuna tatizo la kimtandao. Tafadhali jaribu tena baadae au wasiliana na mtaalamu.',
      });
    }
  });
}

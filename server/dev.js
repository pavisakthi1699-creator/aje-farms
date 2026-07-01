import 'dotenv/config';

import express from 'express';
import { createServer as createViteServer } from 'vite';

import { registerApiRoutes } from './api.js';

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(express.json({ limit: '64kb' }));
registerApiRoutes(app);

const vite = await createViteServer({
  server: {
    hmr: process.env.DISABLE_HMR !== 'true',
    middlewareMode: true,
  },
  appType: 'spa',
});

app.use(vite.middlewares);

app.listen(port, '0.0.0.0', () => {
  console.log(`AJE Farms dev server listening on http://localhost:${port}`);
});

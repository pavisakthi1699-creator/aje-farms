import 'dotenv/config';

import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { registerApiRoutes } from './api.js';

const app = express();
const port = Number(process.env.PORT ?? 3000);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distPath = path.resolve(__dirname, '..', 'dist');

app.use(express.json({ limit: '64kb' }));
registerApiRoutes(app);

app.use(express.static(distPath));
app.get('*', (_req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

app.listen(port, () => {
  console.log(`AJE Farms server listening on port ${port}`);
});

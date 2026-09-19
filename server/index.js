import 'dotenv/config';

import express from 'express';

import { registerApiRoutes } from './api.js';

const app = express();
const port = Number(process.env.PORT ?? 3000);
process.env.NODE_ENV ??= 'production';

app.use(express.json({ limit: '64kb' }));
await registerApiRoutes(app);

app.listen(port, () => {
  console.log(`Chuo Kikuu Cha Mtaani server listening on port ${port}`);
});

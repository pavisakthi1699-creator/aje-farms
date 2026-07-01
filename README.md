<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://ai.google.dev/static/site-assets/images/share-ais-513315318.png" />
</div>

# AJE Farms React Reference App

This is the React/Vite product reference for AJE Farms. The production mobile
work lives in `aje_farms_mobile/`.

View your app in AI Studio: https://ai.studio/apps/1ecf301b-e10d-4c2d-9688-da1de599cd26

## Run Locally

**Prerequisites:** Node.js

1. Install dependencies: `npm install`
2. Set `GEMINI_API_KEY` in `.env.local`.
3. Run the combined API and Vite dev server: `npm run dev`

Gemini calls are handled by the local Express API at `/api/mwalimu-chat`, so the
API key stays on the server and is not injected into the browser bundle.

For a production-style local run:

```sh
npm run build
npm run start
```

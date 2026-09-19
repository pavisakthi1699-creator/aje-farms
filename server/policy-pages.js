import express from 'express';

import { normalizeEmail } from './store/utils.js';

const pageStyle = `
  :root { color-scheme: light; font-family: system-ui, sans-serif; }
  body { margin: 0; color: #17231b; background: #f6f8f6; line-height: 1.6; }
  main { max-width: 760px; margin: 0 auto; padding: 32px 20px 64px; }
  h1, h2 { line-height: 1.2; color: #123d29; }
  a { color: #087a4b; }
  .card { background: white; border: 1px solid #dce5df; border-radius: 16px; padding: 22px; }
  label { display: block; font-weight: 650; margin-top: 14px; }
  input, textarea { box-sizing: border-box; width: 100%; margin-top: 6px; padding: 12px; border: 1px solid #9caf9f; border-radius: 8px; font: inherit; }
  button { margin-top: 18px; border: 0; border-radius: 9px; padding: 12px 18px; background: #087a4b; color: white; font: inherit; font-weight: 700; }
  .muted { color: #526057; }
  .hidden { position: absolute; left: -10000px; }
`;

function contactEmail() {
  return process.env.AJE_PRIVACY_CONTACT_EMAIL ?? 'privacy@ajefarms.co.tz';
}

function layout(title, body) {
  return `<!doctype html>
<html lang="sw"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} | Chuo Kikuu Cha Mtaani</title><style>${pageStyle}</style></head>
<body><main><p><a href="/">Chuo Kikuu Cha Mtaani</a></p>${body}</main></body></html>`;
}

export function installPolicyRoutes(app, store) {
  app.use(express.urlencoded({ extended: false, limit: '16kb' }));

  app.get('/.well-known/assetlinks.json', (_req, res) => {
    const fingerprints = String(
      process.env.AJE_ANDROID_APP_SIGNING_SHA256 ?? '',
    )
      .split(',')
      .map((value) => value.trim().toUpperCase())
      .filter((value) => /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/.test(value));
    if (fingerprints.length === 0) {
      res.status(503).json({ error: 'Android App Links are not configured.' });
      return;
    }
    res.json([
      {
        relation: ['delegate_permission/common.handle_all_urls'],
        target: {
          namespace: 'android_app',
          package_name: 'com.ajefarms.mobile',
          sha256_cert_fingerprints: fingerprints,
        },
      },
    ]);
  });

  const authLinkFallback = (_req, res) => {
    res.type('html').send(
      layout(
        'Fungua Chuo Kikuu Cha Mtaani',
        '<h1>Fungua Chuo Kikuu Cha Mtaani</h1><div class="card"><p>Kiungo hiki kinakamilishwa ndani ya programu ya Chuo Kikuu Cha Mtaani. Sakinisha au fungua programu kisha ujaribu tena.</p></div>',
      ),
    );
  };
  app.get('/auth', authLinkFallback);
  app.get('/login-callback', authLinkFallback);

  app.get('/privacy', (_req, res) => {
    res.type('html').send(layout('Sera ya Faragha', `
      <h1>Sera ya Faragha ya Chuo Kikuu Cha Mtaani</h1>
      <p class="muted">Ilisasishwa tarehe 11 Agosti 2026</p>
      <div class="card">
        <h2>Taarifa tunazokusanya</h2>
        <p>Tunakusanya barua pepe na wasifu wa akaunti, maendeleo ya masomo, mipangilio ya arifa, tokeni ya kifaa kwa arifa unaporuhusu, na maudhui unayochapisha kwenye jamii. Unapotumia Mwalimu AI, swali, jibu na vyanzo vinavyohusiana huhifadhiwa kwa uendeshaji na ukaguzi wa usalama; taarifa zinazohitajika hutumwa kwa mtoa huduma wa AI ili kutoa jibu.</p>
        <h2>Jinsi tunavyotumia taarifa</h2>
        <p>Tunatumia taarifa hizi kuendesha akaunti, kutoa masomo, kuhifadhi maendeleo, kusimamia jamii, kutuma arifa ulizochagua, kuzuia matumizi mabaya, na kuboresha usalama wa huduma.</p>
        <h2>Watoa huduma</h2>
        <p>Tunatumia watoa huduma wa kuhifadhi data, uthibitishaji wa akaunti, arifa na AI kwa madhumuni yaliyoelezwa hapo juu. Hatuuzi taarifa binafsi.</p>
        <h2>Uhifadhi na ufutaji</h2>
        <p>Unaweza kufuta akaunti ndani ya programu. Wasifu, maendeleo, vifaa, arifa na maudhui yako ya jamii yatafutwa. Rekodi za fedha na ukaguzi zinaweza kuhifadhiwa bila taarifa zinazokutambulisha pale sheria, kuzuia udanganyifu au utatuzi wa migogoro unapohitaji.</p>
        <h2>Haki na mawasiliano</h2>
        <p>Kwa ombi la kufikia, kusahihisha au kufuta taarifa, tumia sehemu ya Akaunti kwenye programu au ukurasa wa <a href="/delete-account">kufuta akaunti</a>. Maswali ya faragha: <a href="mailto:${contactEmail()}">${contactEmail()}</a>.</p>
      </div>`));
  });

  app.get('/delete-account', (_req, res) => {
    res.type('html').send(layout('Futa Akaunti', `
      <h1>Omba kufuta akaunti ya Chuo Kikuu Cha Mtaani</h1>
      <p>Ukiweza kuingia kwenye programu, nenda <strong>Akaunti → Futa akaunti na data</strong> kwa ufutaji wa moja kwa moja.</p>
      <div class="card">
        <p>Kama huwezi kuingia, tuma ombi hapa. Timu itathibitisha umiliki wa akaunti kabla ya kukamilisha ufutaji. Usitume nenosiri lako.</p>
        <form method="post" action="/delete-account/requests">
          <label for="email">Barua pepe ya akaunti</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required>
          <div class="hidden" aria-hidden="true"><label for="company">Company</label><input id="company" name="company" tabindex="-1" autocomplete="off"></div>
          <label for="note">Maelezo ya kusaidia (si lazima)</label>
          <textarea id="note" name="note" maxlength="500" rows="4"></textarea>
          <button type="submit">Tuma ombi la ufutaji</button>
        </form>
        <p class="muted">Tutafuta data inayohusishwa na akaunti baada ya kuthibitisha ombi. Rekodi fulani za fedha au usalama zinaweza kuhifadhiwa bila taarifa binafsi kama ilivyoelezwa kwenye <a href="/privacy">Sera ya Faragha</a>.</p>
      </div>`));
  });

  app.get('/terms', (_req, res) => {
    res.type('html').send(layout('Masharti ya Matumizi', `
      <h1>Masharti ya Matumizi ya Chuo Kikuu Cha Mtaani</h1>
      <p class="muted">Toleo la 11 Agosti 2026</p>
      <div class="card">
        <p>Kwa kutumia Chuo Kikuu Cha Mtaani unakubali kutumia huduma kwa njia halali, kuheshimu watumiaji wengine, na kutoweka maudhui yanayodhuru, kudanganya, kutishia au kukiuka faragha.</p>
        <h2>Elimu, si ushauri wa dharura</h2>
        <p>Masomo na majibu ya Mwalimu AI ni taarifa za elimu. Thibitisha maamuzi ya afya, dawa, kemikali, fedha au usalama na mtaalamu anayefaa.</p>
        <h2>Akaunti na maudhui</h2>
        <p>Unawajibika kulinda taarifa za kuingia na maudhui unayoweka. Tunaweza kuficha maudhui, kuzuia matumizi au kusimamisha akaunti inayokiuka masharti au kuhatarisha watu wengine.</p>
        <h2>Faragha na kufuta akaunti</h2>
        <p>Matumizi ya taarifa yameelezwa kwenye <a href="/privacy">Sera ya Faragha</a>. Unaweza kuomba ufutaji kupitia programu au <a href="/delete-account">ukurasa huu</a>.</p>
        <p>Mawasiliano: <a href="mailto:${contactEmail()}">${contactEmail()}</a>.</p>
      </div>`));
  });

  app.get('/community-guidelines', (_req, res) => {
    res.type('html').send(layout('Mwongozo wa Jamii', `
      <h1>Mwongozo wa Jamii ya Chuo Kikuu Cha Mtaani</h1>
      <div class="card">
        <h2>Shiriki kwa heshima na usalama</h2>
        <ul><li>Usitishie, kunyanyasa au kushambulia watu au makundi.</li><li>Usiweke ponografia, vurugu kali, chuki au unyonyaji wa watoto.</li><li>Usiweke taarifa binafsi za mtu bila ruhusa.</li><li>Usisambaze ulaghai, spam, dawa au maagizo hatari yasiyothibitishwa.</li><li>Eleza uzoefu wako kwa uaminifu na taja chanzo inapowezekana.</li></ul>
        <h2>Ripoti na kuzuia</h2>
        <p>Tumia menyu ya usalama kwenye chapisho kuripoti post, kuripoti mtumiaji au kumzuia. Admin hukagua ripoti; maudhui yanaweza kufichwa na akaunti inaweza kusimamishwa.</p>
      </div>`));
  });

  app.post('/delete-account/requests', async (req, res) => {
    if (String(req.body?.company ?? '').trim()) {
      res.status(200).type('html').send(successPage());
      return;
    }
    const email = normalizeEmail(req.body?.email);
    if (!email || email.length > 254 || !email.includes('@')) {
      res.status(400).type('html').send(layout('Ombi halijatumwa', `
        <h1>Angalia barua pepe</h1><p>Weka barua pepe halali ya akaunti kisha ujaribu tena.</p><p><a href="/delete-account">Rudi kwenye fomu</a></p>`));
      return;
    }
    await store.createAccountDeletionRequest({ email });
    res.status(202).type('html').send(successPage());
  });
}

function successPage() {
  return layout('Ombi limepokelewa', `
    <h1>Ombi limepokelewa</h1>
    <div class="card"><p>Kama barua pepe hiyo ina akaunti ya Chuo Kikuu Cha Mtaani, timu itawasiliana nawe kuthibitisha umiliki na kukamilisha ufutaji.</p><p><a href="/privacy">Soma Sera ya Faragha</a></p></div>`);
}

const POLICY_PAGES = [
  ['AJE_PRIVACY_POLICY_URL', 'privacy policy', 'Sera ya Faragha'],
  ['AJE_ACCOUNT_DELETION_URL', 'account deletion', 'Omba kufuta akaunti'],
];

export async function verifyReleasePolicyPages(
  env,
  { fetchImpl = fetch, timeoutMs = 10_000 } = {},
) {
  const blockers = [];
  for (const [envName, label, marker] of POLICY_PAGES) {
    const url = env[envName];
    if (!url) continue;
    try {
      const response = await fetchImpl(url, {
        headers: { Accept: 'text/html' },
        redirect: 'follow',
        signal: AbortSignal.timeout(timeoutMs),
      });
      const contentType = response.headers.get('content-type') ?? '';
      const body = await response.text();
      if (!response.ok) {
        blockers.push(`${envName} returned HTTP ${response.status}.`);
      } else if (!contentType.toLowerCase().includes('text/html')) {
        blockers.push(`${envName} must serve a public HTML ${label} page.`);
      } else if (body.trim().length < 100) {
        blockers.push(`${envName} returned an empty or incomplete ${label} page.`);
      } else if (!body.includes('Chuo Kikuu Cha Mtaani') || !body.includes(marker)) {
        blockers.push(
          `${envName} does not contain the expected Chuo Kikuu Cha Mtaani ${label} page.`,
        );
      }
    } catch {
      blockers.push(`${envName} could not be reached from the release runner.`);
    }
  }
  return blockers;
}

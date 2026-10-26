// Runs before support.js and before first paint. Kept out of the HTML so the CSP needs no 'unsafe-inline' for scripts.

// Serve the runtime's React from /vendor instead of unpkg.com, so the app makes no third-party requests.
// The vendored files are byte-identical to the CDN files (same SRI hashes as in support.js; see vendor/README.md).
window.__resources = {
  'https://unpkg.com/react@18.3.1/umd/react.production.min.js': 'vendor/react.production.min.js',
  'https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js': 'vendor/react-dom.production.min.js'
};

// Apply a saved light/dark choice now, so there is no light flash in dark mode.
try {
  const t = localStorage.getItem('lg-roadmap-theme');
  if (t === 'light' || t === 'dark') document.documentElement.dataset.theme = t;
} catch (e) { /* storage blocked: follow the OS theme */ }

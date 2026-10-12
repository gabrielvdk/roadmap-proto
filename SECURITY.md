# Roadmapper: architecture and security

Written for a security and architecture review ahead of hosting Roadmapper on internal Azure. It describes what the app is, what it does and doesn't do, the controls in place, and the residual risks.

## 1. What it is

Roadmapper is a **UX prototype** for reviewing product roadmaps at Epic level, with four views (Board, List, Matrix, Timeline) and an edit dialog.

- **A static site.** It has no backend, no API, no database and no server-side code.
- **Data stays in the browser.** Epics live in the viewer's own `localStorage`. Nothing is sent anywhere, and every viewer has their own private copy.
- **No accounts in the app.** Access is controlled by the hosting platform (§5). In the app, edits are attributed to "You".
- **Sample data is fictional.** The source repository (`gabrielvdk/roadmap-proto`) is public, so it contains no customer, personal or confidential data.

## 2. Architecture

```
Browser
 ├─ index.html     markup template + one Component class (all app logic and the sample data)
 ├─ app.css        design tokens and shared UI styles
 ├─ boot.js        before first paint: sets the light/dark theme, points the runtime at vendor/
 ├─ support.js     template runtime: parses the template in index.html and renders it with React
 ├─ vendor/        React 18.3.1 + ReactDOM (UMD), Figtree and Titillium Web fonts
 └─ localStorage   lg-roadmap-v4.2 (the epics), lg-roadmap-theme (light/dark)
```

Deployed unit: the `app/` folder (14 files, about 340 KB). Nothing outside `app/` is published. The repository root holds documentation and the local dev server only.

**Runtime flow.**
1. The browser loads `index.html`, the two stylesheets, `boot.js` and `support.js`, all from the same origin.
2. `support.js` loads React from `vendor/`.
3. It compiles the `<script type="text/x-dc">` block into a component class (see §4.1) and renders the `<x-dc>` template.
4. User changes are saved to `localStorage`. On load the data is read back and validated (§3).

**Data model** (one record per Epic): title, description, application, theme, stage, health, six month fields (planned, forecast and actual start/end), status updates (append-only), and an audit trail with one entry per save or drag.

## 3. Security controls

| Concern | Control |
|---|---|
| **XSS** | All user text is rendered as text nodes or attribute values through React, which escapes it. No user data is ever passed to `innerHTML`, `eval` or URLs. Tested with `<img src=x onerror=…>` titles and HTML in status updates: both render as literal text. The CSP (§4) is a second layer. |
| **Untrusted stored data** | `localStorage` is treated as untrusted input. On load, `cleanEpic` / `cleanAudit` in `index.html` check every field against its type and allowed values (enumerations for application, theme, stage and health; `YYYY-MM` for dates; ISO timestamps). They cap text lengths, ignore unknown fields (including `__proto__`), and drop broken records. Corrupt data cannot crash the app or inject markup. |
| **Input limits** | Title 200, description and updates 4,000 characters (`maxLength` in the form, re-applied when loading). |
| **Third-party code at runtime** | None. React and the fonts are vendored. Every request goes to the app's own origin (verified in the browser's network log). |
| **Supply chain** | The vendored React files are byte-identical to the npm/unpkg releases: they match the SHA-384 hashes pinned in `support.js` (§6). The fonts are under the SIL OFL, with licenses shipped next to them. |
| **Clickjacking** | `frame-ancestors 'none'` and `X-Frame-Options: DENY`. |
| **Transport** | HTTPS only on Azure Static Web Apps, plus HSTS. |
| **Data exfiltration** | The CSP sets `default-src 'none'` without a `connect-src`, so `fetch`/XHR/WebSocket are blocked. Forms, `<base>`, plugins and off-origin images and fonts are blocked too. |
| **Information leakage** | `Referrer-Policy: no-referrer`, `X-Robots-Tag` and `<meta name="robots">` set to `noindex, nofollow`. A restrictive `Permissions-Policy` blocks camera, microphone and similar. |
| **Access** | Entra ID sign-in is enforced by the platform (§5). |

## 4. Content-Security-Policy

```
default-src 'none'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline';
font-src 'self'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'
```

There are no inline scripts. `boot.js` is a separate file for exactly this reason. Two relaxations remain; both are known and accepted for a prototype.

### 4.1 `script-src 'unsafe-eval'` (residual risk: low to medium)

The template runtime (`support.js`) compiles the component logic in `index.html` with `new Function()`. This is how the prototype stays editable as a single HTML file.

- **What gets evaluated:** only the page's own `<script type="text/x-dc">` block, which comes from the same origin as `support.js` itself. No user data or remote content is ever evaluated.
- **Why it still matters:** `'unsafe-eval'` weakens the CSP as a defense against XSS. If an attacker found an injection point (none is known; see §3), the CSP would not stop eval-based payloads.
- **Mitigation path, if required:** port `index.html` to a precompiled React bundle, without the template runtime. That removes `'unsafe-eval'` and lets `script-src 'self'` stand alone. It's a contained rewrite of one file, since the logic is already plain JavaScript. It's planned for the move from prototype to product anyway (see README, "Backend requirements").

### 4.2 `style-src 'unsafe-inline'` (residual risk: low)

The runtime and React inject `<style>` elements and inline styles. Injected CSS cannot run script. The remaining risk is CSS-based UI redressing, which needs an injection point that doesn't exist (§3).

### 4.3 `support.js` notes

`support.js` is a generated runtime (`dc-runtime`) and is checked in as is. Its behavior relevant to this review:

- It would load React from unpkg.com, but `boot.js` sets `window.__resources` to redirect both files to `vendor/`. The same setting also turns off the runtime's re-fetch of its own page.
- It contains a Babel loader for JSX components. Roadmapper doesn't use JSX, so Babel is never loaded (and the CSP would block it).
- It talks to a parent window through `postMessage` (boot notice, design-mode messages) for when it is embedded in a design tool. It only *accepts* two message types: a theme hint and a probe. Neither reads or changes app data. Framing is blocked anyway (`frame-ancestors 'none'`), so this channel is inert in production.
- It exposes debug helpers on `window` (`__dcUpdate` etc.). These can only be called by script already running in the page, so they add no attack surface beyond what such a script would have anyway.

## 5. Hosting on Azure Static Web Apps

`app/staticwebapp.config.json` holds the security headers and the access rules:

- every route requires the `authenticated` role, and unauthenticated users are redirected to Entra ID (`/.auth/login/aad`)
- GitHub and Twitter sign-in are disabled

Deployment settings: **app location `app`**, **no build step** (`skip_app_build: true`), no API.

**Required before go-live (restrict sign-in to our tenant).** The built-in `aad` provider accepts accounts from *any* Entra ID tenant. For internal use, either:

1. register an app in our Entra ID and configure it as a custom provider (SWA Standard plan):
   ```json
   "auth": { "identityProviders": { "azureActiveDirectory": { "registration": {
     "openIdIssuer": "https://login.microsoftonline.com/<TENANT_ID>/v2.0",
     "clientIdSettingName": "AAD_CLIENT_ID", "clientSecretSettingName": "AAD_CLIENT_SECRET" } } } }
   ```
   with the client ID and secret stored as SWA application settings (never in the repo); and/or
2. put the site behind a **private endpoint** so it can only be reached from the corporate network.

## 6. Third-party components

| File (under `app/vendor/`) | Source | Version | License |
|---|---|---|---|
| `react.production.min.js` | `https://unpkg.com/react@18.3.1/umd/react.production.min.js` | 18.3.1 | MIT |
| `react-dom.production.min.js` | `https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js` | 18.3.1 | MIT |
| `fonts/figtree-latin.woff2` | Google Fonts, Figtree (variable 400–700, latin) | v9 | SIL OFL 1.1 |
| `fonts/titillium-web-{600,700}-latin.woff2` | Google Fonts, Titillium Web (latin) | v19 | SIL OFL 1.1 |
| `../support.js` | dc-runtime (generated; header says "do not edit") | — | — |

Verify the React files (Git Bash) against the hashes pinned in `support.js`:

```bash
openssl dgst -sha384 -binary app/vendor/react.production.min.js | openssl base64 -A
```

Expected values: React `DGyLxAyjq0f9SPpVevD6IgztCFlnMF6oW/XQGmfe+IsZ8TqEiDrcHkMLKI6fiB/Z`, ReactDOM `gTGxhz21lVGYNMcdJOyq01Edg0jhn/c22nsx0kyqP0TxaV5WVdsSH1fSDUf5YJj1`.

## 7. Local dev server (`serve.ps1`)

This is for development only and is not deployed. It:
- listens on `localhost` only
- serves only `app/`, and only these file types: html, js, css, svg, woff2, txt
- rejects path traversal (full-path prefix check, plus no drive letters, alternate data streams or wildcards)
- allows only GET and HEAD
- sends the same headers as `staticwebapp.config.json`, so local testing runs under the production CSP

## 8. Known limitations (by design, prototype phase)

- **No shared data.** Each browser has its own copy, so this is not yet a system of record.
- **The audit trail is client-side.** It is not tamper-proof: a user can edit their own `localStorage`. A real audit trail needs a server (README, "Backend requirements").
- **No in-app roles.** Anyone who can sign in can edit their own copy.
- **Accessibility gaps.** Board and Matrix cards can't be reached with the keyboard, and dialogs don't keep keyboard focus inside them.

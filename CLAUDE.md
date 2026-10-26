# Roadmapper: Epic roadmap prototype

A prototype tool for recording and reviewing product roadmaps at the **Epic** level, with four views over the same Epics: Board, List, Matrix and Timeline. **Prototype phase**: iterate on UX in HTML. It isn't a real application yet; there is no backend, login or shared data.

Background reading: `README.md` (original handoff and domain model) and `CONVERSATION_CONTEXT.md` (early feedback rounds). Look and feel: **`DESIGN.md`**, the spec shared with EOSTracker (`../EOStracker`). Architecture and security (written for the Azure hosting review): **`SECURITY.md`**; keep it accurate when you change anything it describes.

## Files
`app/` is the **deployable unit**: everything the app needs at runtime, and nothing else. Docs and tooling stay at the root.
- `app/index.html`: **the current prototype (v4); all work happens here.** Template plus the one `Component` class.
- `app/app.css`: design tokens and the shared UI classes (`.btn`, `.ctl`, `.field`, `.chk`, `.seg`, `.pop`, `.dialog`, …).
- `app/boot.js`: runs before first paint: applies the saved theme and maps the runtime's React CDN URLs to `vendor/` (`window.__resources`).
- `app/support.js`: the template runtime (generated; don't edit).
- `app/vendor/`: React 18.3.1 UMD and the self-hosted fonts. Replace files to update them, and update the table in `SECURITY.md` §6.
- `app/staticwebapp.config.json`: Azure Static Web Apps config: security headers (CSP etc.) and Entra ID sign-in. `serve.ps1` sends the same headers.
- `app/favicon.svg`: the app icon (three bars, same as the logo in the top bar). The app is called **Roadmapper** (page title and top bar).
- `index.html` (root): only redirects GitHub Pages visitors to `app/`.
- `serve.ps1`: local dev server; serves only `app/`, on localhost. `.claude/launch.json` has the `roadmapper` entry on **port 8090** (8080 is used by EOSTracker).
- `.nojekyll`: keeps GitHub Pages from running Jekyll. Don't remove it.
- v2, v3 and the old `_ds/` design-system files were removed; they are at git tag `v3-reference`.

## Running it
There's no Node or Python on this machine. In the Claude Code browser pane, start it with `preview_start` using the name `roadmapper`, or run:
`powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1 -Port 8090`, then open http://localhost:8090.

The server sends `no-store`, so a reload shows the latest edit, but it reads `staticwebapp.config.json` only at startup; restart it after changing headers. Sometimes the port reports as "reserved" right after a stop; retrying once works. The page runs under the production CSP, so `fetch()` from the browser console is blocked (that's intended).

## Publishing
- GitHub Pages from the **public** repo `gabrielvdk/roadmap-proto` (branch `main`, root) → https://gabrielvdk.github.io/roadmap-proto/ (redirects to `app/`)
- Internal Azure: Static Web Apps with app location `app`, no build step; see `SECURITY.md` §5.
- Publishing means commit + `git push` on `main`.
- Do bigger changes on a branch first, and merge when the user approves.
- Every page has `<meta name="robots" content="noindex, nofollow">`. A `robots.txt` is useless on a project site.
- **Everything in the repo, history included, is public.** Sample data must stay fictional. The user had **FieldFlow** (application) and **Labour** (theme) removed; don't reintroduce them.

## How the prototype is built (v4)
- **Template:** markup inside `<x-dc>` uses the runtime's `{{ }}` bindings, `<sc-for list as>` and `<sc-if value>`. Anything used more than once is a **class in `app.css`** (`class="{{ … }}"` works for state classes like `on`); one-off layout stays **inline** (`style="…"`, `style-hover`, `style-focus`). Colors that depend on data (stage, status) come from JS style objects.
- **Logic:** one `class Component extends DCLogic` in `<script type="text/x-dc" data-dc-script>`, preceded by plain helpers grouped by topic (lists, dates, epics, audit, validation, seed, storage, style helpers).
  - `state` holds data and UI state.
  - `renderVals()` filters the epics once, then merges one view-model method per area: `headerVals`, `filterVals`, `boardVals`, `listVals`, `matrixVals`, `timelineVals`, `modalVals`. Add new template values to the method of their area.
  - Change data with `persist()` / `patch(id, p, via)` / `save()`; `persist` is the only writer to storage.
  - Shared rules live in one helper each: `statusOf` (what status shows), `slipOf` (months past the planned end, actual end else forecast).
- **Storage:** `localStorage` key `lg-roadmap-v4.2` (per browser, not shared). Bump the key when the data shape changes or the seed must reload for everyone. Clear it in the browser pane to see the seed again.
- **Validation:** stored data is untrusted. `load()` runs every epic through `cleanEpic` (enumerations, `YYYY-MM`, ISO timestamps, length caps from `MAX`, unknown fields dropped). **When you add a field, add it to `cleanEpic`** or it is lost on reload. The seed goes through `cleanEpic` too.
- **Fixed lists:** `APPS`, `THEMES`, `STAGES` (8: **Backlog**, the 6 pipeline stages, **Done**; `BACKLOG`/`DONE` constants), `HEALTH` (On track / At risk / Late; applies to active work only).
- **Status shown** (`statusOf`, `STATUS`): stage Done → "Done" (dark green `--done` + ✓), stage Backlog → "Backlog" (grey), otherwise the health. The Health buttons are hidden in the modal for Backlog/Done.
- **Filter** (Filter menu: Application, Theme, Stage; `fApps`, `fThemes`, `fStages`) is one shared state, so it is the same in every view. Empty list = all. The default stage filter is the 6 pipeline stages (`DEFAULT_STAGES`), so **Backlog and Done are hidden until ticked**, also on a Board grouped by Stage; "Clear filters" returns to that default. Groups, Matrix rows and Matrix/Board columns for filtered-out values are hidden (`keysIn`), not shown empty.
- **Seed:** the `SEED_ROWS` array. Epic ids `e1…` come from row order, so if you remove rows, remap `SEED_AUDIT`.
- **New epics** start in Backlog. On save, the filter is widened to include the new epic's application, theme and stage, so it doesn't vanish.
- **Epic fields:**
  - `title`, `desc`, `app`, `theme`, `stage` (index)
  - `health`
  - planned `ps/pe`, forecast `fs/fe` and actual `as/ae`, all `YYYY-MM`
  - `updates[]`
  - `audit[]`
- **Audit trail:** **one entry per save or drag**, `{date, author, via, changes:[{field,from,to}]}` or `{…, created:true}`.
  - `via` is Modal, Board, Matrix or Timeline.
  - Built by `auditEntries(old, new, via)`; `FIELDS` lists the audited fields and their labels.
  - `normAudit()` folds the per-field entries of `SEED_AUDIT` into this format.
  - Timestamps are stored as UTC ISO strings (`cleanEpic` converts older local-time strings).
- **Epic modal:**
  - left: a static "Details" header with the fields
  - right: tabs **Status updates · History** (`state.rtab`)
  - updates are append-only and not part of the audit
- **Timeline bars** (baseline style):
  - colored bar = actual dates where known, otherwise forecast (falling back to plan), in the health color
  - grey line underneath = original plan; "+N mo" = slip past the planned end
  - black ticks = actual start and end
  - drag rules: not started = move or resize; started = only the end is draggable; finished (actual end or Done stage) = not draggable
  - Done Epics: dark green bar with a white ✓ at its end
  - every drag asks for confirmation and is audited
- **Stage colors** (`STAGE_C`, from the pipeline slide; Backlog `--grey-fill`, Done `--done`): used for column top borders and tints, dots and chips. Status uses the EOS colors (see `DESIGN.md` §2.1).

## Conventions
- **Use tokens only** (`--canvas`, `--surface`, `--line`, `--ink…`, `--accent…`, status colors). Never hard-code `white` or hex colors; check light **and** dark mode. Solid accent fills use `--accent-fill` with `--on-fill` text (not `--accent`, which is too light for white text in dark mode).
- **No third-party requests and no inline scripts.** The CSP (`default-src 'none'`) blocks them: put new scripts in a file under `app/`, vendor any library into `app/vendor/` (and list it in `SECURITY.md` §6), and don't use `fetch`.
- Render user text only through `{{ }}` bindings (React escapes it); never build HTML strings from data.
- Mix tints with `var(--surface)` and text with `var(--ink)` so both themes work.
- **Titillium Web** (`--font-title`) is for titles only: app name, view `h1`, modal titles. Everything else is Figtree.
- Grid columns that contain form controls need `minmax(0,1fr)`, and the controls need `width:100%;min-width:0`, or they overflow at narrow widths.
- Never use `window.confirm()`, `alert()` or `prompt()`; they're blocked in the browser pane. Use an in-app dialog (see the forecast confirm dialog).
- Keep the user's earlier UX decisions:
  - List: a "Details" checkbox hides Application/Theme/Stage lines; it shares `details` with the Timeline toggle
  - light/dark: an "Appearance" switch (Light / Dark / Follow computer, `.seg`) in the footer under the page (`themeOpts` in `headerVals`, `setTheme(mode)`; "Follow computer" removes the choice), matching EOSTracker's Profile → Appearance (see `DESIGN.md`); key `lg-roadmap-theme`, applied by `boot.js` before first paint. No floating button.
  - no stage numbers or subtitles
  - no Productization track
  - the List hides the attribute it's grouped by
  - Board cards show the application only
  - double-click a List row to open it

## Open ideas / next steps
- **Finished Epics:** built as the **Done** stage (with Backlog as the counterpart before the pipeline). Possible next step: a close outcome (Completed / Stopped / Superseded) and "Create follow-up Epic" for Expand/Fix outcomes from Learn.
- **Later, a real app:** shared backend, users and authentication, server-side audit, and admin-editable lists. Keep that in mind, but don't over-engineer the prototype.
- **Strict CSP:** the runtime compiles the logic with `new Function`, so the CSP needs `'unsafe-eval'` (accepted residual risk, `SECURITY.md` §4.1). Removing it means porting `app/index.html` to a precompiled React bundle without `support.js`.

## Where things stand (2026-10-26)
- The `hardening` branch (Azure hardening + restructure into `app/`, byte-identical vendor files, and the Appearance switch) is **merged into `main`** and pushed (2026-10-26), so it is live on GitHub Pages. The `hardening` branch is no longer needed and can be deleted.
- The **Appearance** change came from the EOSTracker chat, to keep both apps consistent: EOSTracker moved its light/dark choice to Profile → Appearance and Help to a footer, so Roadmapper (no profile page) got the same Light / Dark / Follow computer switch in a footer. The rule is in `DESIGN.md` (same text in both repos). If you change the theme recipe, change `DESIGN.md` here **and** in `../EOStracker`.
- EOSTracker's `.claude/launch.json` also has a `roadmapper` entry (port 8090), so either chat can preview both apps.

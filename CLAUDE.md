# Roadmapper: Epic roadmap prototype

A prototype tool for recording and reviewing product roadmaps at the **Epic** level, with four views over the same Epics: Board, List, Matrix and Timeline. **Prototype phase**: iterate on UX in HTML. It isn't a real application yet; there is no backend, login or shared data.

Background reading: `README.md` (original handoff and domain model) and `CONVERSATION_CONTEXT.md` (early feedback rounds). Look and feel: **`DESIGN.md`**, the spec shared with EOSTracker (`../EOStracker`).

## Files
- `Roadmap v4.dc.html`: **the current prototype; all work happens here.** `index.html` only redirects to it.
- `Roadmap v3.dc.html`, `Roadmap v2.dc.html`: earlier iterations, reference only. Don't edit them.
- `support.js`: the template runtime the prototype runs on (reference only; don't edit).
- `_ds/…/styles.css`, `_ds_bundle.js`: original design-system files. Their `--color-*` variables are now **mapped onto the EOS tokens** in the `<style>` block of v4, so don't restyle via `_ds`.
- `serve.ps1`: a static PowerShell server. `.claude/launch.json` has the `roadmapper` entry on **port 8090** (8080 is used by EOSTracker).
- `.nojekyll`: required so GitHub Pages serves the `_ds/` folder. Don't remove it.
- `favicon.svg`: the app icon (three bars, same as the logo in the top bar); linked from v4 and `index.html`. The app is called **Roadmapper** (page title and top bar).

## Running it
There's no Node or Python on this machine. In the Claude Code browser pane, start it with `preview_start` using the name `roadmapper`, or run:
`powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1 -Port 8090`, then open http://localhost:8090.

The server sends `no-store`, so a reload shows the latest edit. Sometimes the port reports as "reserved" right after a stop; retrying once works.

## Publishing
- GitHub Pages from the **public** repo `gabrielvdk/roadmap-proto` (branch `main`, root) → https://gabrielvdk.github.io/roadmap-proto/
- Publishing means commit + `git push` on `main`.
- Do bigger changes on a branch first, and merge when the user approves.
- Every page has `<meta name="robots" content="noindex, nofollow">`. A `robots.txt` is useless on a project site.
- **Everything in the repo, history included, is public.** Sample data must stay fictional. The user had **FieldFlow** (application) and **Labour** (theme) removed; don't reintroduce them.

## How the prototype is built (v4)
- **Template:** markup inside `<x-dc>` uses the runtime's `{{ }}` bindings, `<sc-for list as>` and `<sc-if value>`. Styles are **inline** (`style="…"`, `style-hover`, `style-focus`). Dynamic styles come from JS objects returned by `renderVals()`.
- **Logic:** one `class Component extends DCLogic` in `<script type="text/x-dc" data-dc-script>`.
  - `state` holds data and UI state.
  - `renderVals()` computes everything the template needs.
  - Change data with `persist()` / `patch(id, p, via)` / `save()`.
- **Storage:** `localStorage` key `lg-roadmap-v4.2` (per browser, not shared). Bump the key when the data shape changes or the seed must reload for everyone. Clear it in the browser pane to see the seed again.
- **Fixed lists:** `APPS`, `THEMES`, `STAGES` (8: **Backlog**, the 6 pipeline stages, **Done**; `BACKLOG`/`DONE` constants), `HEALTH` (On track / At risk / Late; applies to active work only).
- **Status shown** (`statusOf`, `STATUS`): stage Done → "Done" (dark green `--done` + ✓), stage Backlog → "Backlog" (grey), otherwise the health. The Health buttons are hidden in the modal for Backlog/Done.
- **Filter** (Filter menu: Application, Theme, Stage; `fApps`, `fThemes`, `fStages`) is one shared state, so it is the same in every view. Empty list = all. The default stage filter is the 6 pipeline stages (`DEFAULT_STAGES`), so **Backlog and Done are hidden until ticked**, also on a Board grouped by Stage; "Clear filters" returns to that default. Groups, Matrix rows and Matrix/Board columns for filtered-out values are hidden (`keysIn`), not shown empty.
- **Seed:** the `SEED` array. Epic ids `e1…` come from row order, so if you remove rows, remap `SEED_AUDIT`.
- **Epic fields:**
  - `title`, `desc`, `app`, `theme`, `stage` (index)
  - `health`
  - planned `ps/pe`, forecast `fs/fe` and actual `as/ae`, all `YYYY-MM`
  - `updates[]`
  - `audit[]`
- **Audit trail:** **one entry per save or drag**, `{date, author, via, changes:[{field,from,to}]}` or `{…, created:true}`.
  - `via` is Modal, Board, Matrix or Timeline.
  - Built by `auditEntries(old, new, via)`; `FIELDS` lists the audited fields and their labels.
  - `normAudit()` folds old per-field entries into this format.
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
- **Use tokens only** (`--canvas`, `--surface`, `--line`, `--ink…`, `--accent…`, status colors). Never hard-code `white` or hex colors; check light **and** dark mode.
- Mix tints with `var(--surface)` and text with `var(--ink)` so both themes work.
- **Titillium Web** (`--font-title`) is for titles only: app name, view `h1`, modal titles. Everything else is Figtree.
- Grid columns that contain form controls need `minmax(0,1fr)`, and the controls need `width:100%;min-width:0`, or they overflow at narrow widths.
- Never use `window.confirm()`, `alert()` or `prompt()`; they're blocked in the browser pane. Use an in-app dialog (see the forecast confirm dialog).
- Keep the user's earlier UX decisions:
  - List: a "Details" checkbox hides Application/Theme/Stage lines; it shares `details` with the Timeline toggle
  - light/dark toggle: round button fixed bottom right, cloned from EOSTracker; key `lg-roadmap-theme`, applied in `<head>` before first paint
  - no stage numbers or subtitles
  - no Productization track
  - the List hides the attribute it's grouped by
  - Board cards show the application only
  - double-click a List row to open it

## Open ideas / next steps
- **Finished Epics:** built as the **Done** stage (with Backlog as the counterpart before the pipeline). Possible next step: a close outcome (Completed / Stopped / Superseded) and "Create follow-up Epic" for Expand/Fix outcomes from Learn.
- **Later, a real app:** shared backend, users and authentication, server-side audit, and admin-editable lists. Keep that in mind, but don't over-engineer the prototype.

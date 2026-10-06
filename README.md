# Handoff: Epic Roadmap Tool (LetsGrow)

## Overview
An internal tool for recording and reviewing high-level product roadmaps at the **Epic** level. Product and management can see the same set of Epics through four views:

- **Board**: Trello-style columns grouped by Stage, Theme or Application. Cards can be dragged between columns.
- **List**: a grouped table showing each Epic's health, forecast dates and **latest status update**.
- **Matrix**: rows by Theme or Application, columns by pipeline Stage. Cards can be dragged between cells.
- **Timeline**: a Gantt chart by quarter with two-level grouping. Bars can be dragged and resized, and a confirmation dialog appears before any change is saved.

Clicking an Epic title, or a card or bar, in any view opens the **Epic modal**. In the modal all fields can be edited, and users can read and add status updates.

The target feel is an **office application** in the style of Microsoft Planner or Trello: white cards, soft shadows, rounded corners and a dense, practical layout. It should **not** look like a wireframe.

## About the design files
`Roadmap v3.dc.html` is a **design reference built in HTML**: a working prototype that shows the intended look and behavior. It is not production code to copy. Rebuild it in the target codebase with that codebase's framework and patterns. If no codebase exists yet, pick a suitable stack; a React + TypeScript SPA with a small REST/DB backend is a sensible default.

The prototype file uses a custom template runtime (`support.js`, the `<sc-for>` / `<sc-if>` / `{{ }}` syntax), and all styles are inline. Read the template part for markup and styles. The `<script data-dc-script>` block at the bottom holds all logic and sample data, written as plain JS.

## Fidelity
**High-fidelity** for layout, colors, typography, spacing and interactions. Persistence is only a placeholder: the prototype saves to `localStorage`. The real tool needs a shared backend with users and authentication.

---

## Domain model

### Fixed lists (should be admin-configurable later)
- **Applications:** IIVO, Intelligent Algorithms, LetsGrow.com, Intelligent Assistance
- **Themes:** Energy Management, IPM, Yield Prediction, Cultivation
- **Pipeline stages, in order:** Validation, Prototyping, Development, Productization, Launch, Learn
  - Show stage names **without** numbers or explanatory subtitles.
- **Productization sub-tracks** (optional tag; only allowed when stage = Productization): Proposition, Documentation, Enablement
- **Health:** On track, At risk, Late, Done

### Epic
| Field | Type | Notes |
|---|---|---|
| id | string/uuid | |
| title | string | required |
| description | text | What the epic delivers functionally |
| application | enum | one of Applications |
| theme | enum | one of Themes |
| stage | enum | one of Stages |
| productizationTrack | enum? | only when stage = Productization; cleared automatically when the stage changes |
| health | enum | On track / At risk / Late / Done |
| plannedStart, plannedEnd | year-month (`YYYY-MM`) | month + year only |
| forecastStart, forecastEnd | year-month | |
| actualStart, actualEnd | year-month | |
| updates | StatusUpdate[] | see below |

### StatusUpdate
| Field | Type |
|---|---|
| id | string |
| epicId | string |
| author | user ref (prototype shows "You") |
| createdAt | full timestamp (date + time) |
| text | text, multi-line |

Status updates are the running commentary that explains an Epic's status. They are append-only in the prototype.

### Audit trail (required, not yet in the prototype)
**Track every change to an Epic:** who changed which attribute, the old value, the new value, and when.
- Write one audit entry per changed field per save, including changes made by drag-and-drop on the Board, Matrix and Timeline.
- Proposed table: `EpicAuditEntry { id, epicId, userId, timestamp, field, oldValue, newValue }`. Creating an Epic writes one "created" entry.
- The Epic modal gets a **History** tab that lists these entries, newest first. Use the same relative-time format as updates (see below). Example: *"Sanne changed Forecast end from Jan 2027 → Apr 2027 · 2 hrs ago"*.
- Suggested modal tabs: **Details** (current content) | **History**. Status updates stay visible in the right-hand column of Details.

### Derived values
- **Forecast range shown in views:** forecastStart–forecastEnd, falling back to plannedStart–plannedEnd if no forecast is set.
- **Slip / overrun (months)** = (end − plannedEnd), where end = actualEnd if health is Done and actualEnd is set, otherwise forecastEnd. Shown only when > 0, as "+N mo" or "+N mo vs. plan".
- **Last status update** = the newest update by createdAt.

---

## Global layout

1. **Top bar**, 48px high, background `accent-900` (#2a4b6c-ish; see tokens), white text.
   - Left: "Roadmap" in Barlow Condensed 600, 21px. Next to it, a subtitle "Epics across all applications" at 13px, 85% opacity.
   - Right: **New epic** button, white background, accent-900 text, 32px high, radius 4px, 600 weight, "+" icon.
2. **Toolbar**: white background, bottom border in the divider color, minimum height 44px.
   - Left: view tabs **Board | List | Matrix | Timeline**. The active tab is 600 weight in accent-900 with a 3px accent-700 underline (inset box-shadow). Inactive tabs are neutral-800 at 400 weight.
   - Right (wraps on narrow screens):
     - **Group by** segmented control on Board, List and Matrix. Selected segment: accent-700 background, white text. Height 28px, radius 4px, neutral-300 border.
     - Timeline only: two selects, **Group by [Application ▾] then [Theme ▾]**. Options are Application, Theme, Stage and None; the second select excludes whatever the first uses.
     - **Filter** button with a funnel icon and a count badge (accent-700 pill) when filters are active. It opens a 440px popover with two columns of checkboxes (Application | Theme) and a footer "Showing X of Y epics · Clear filters". The filter applies to every view. Within a column the logic is OR; between the two columns it is AND.
     - Timeline only: **Quarters** segmented control with 4, 6, 8 and 12, then the buttons **‹ Today ›**, then a **Details** checkbox. Clicking the label toggles it as well, not only the box.
3. **Content area**: padding 16px 20px 20px, page background `--color-bg` (#f2f2f3).

---

## Views

### Board
- Columns sit in a horizontal row and scroll sideways. Each column is 268px wide with a neutral-200 background, radius 4px and 8px padding.
- Column header: group name in Barlow Condensed 600 at 17px, plus a count pill on the right (white background, 12px text).
- **Card** (white, radius 4px, `shadow-sm`, `shadow-md` on hover, padding 10px 12px, 6px gap), vertical order:
  1. **Title**: 14px, 600 weight.
  2. **Application**, 12.5px in neutral-700. Theme is **not** shown. Hide this line when the board is grouped by Application.
  3. **Dates**: calendar icon + forecast range ("Jun ’26 – Jan ’27") at 12.5px with tabular numbers, never wrapping. Add a red "+N mo" when the epic has slipped.
  4. **Health badge**, plus an optional Productization track tag (neutral-200 pill).
- No description on the card.
- Clicking a card opens the modal.
- **Drag and drop** cards between columns. The drop changes the attribute the board is grouped by (stage, theme or application). While dragging, the card goes to 45% opacity and the target column gets an accent-200 background with a 2px dashed accent-500 outline. The change saves straight away and should be recorded in the audit trail.

### List
- One white panel per group (radius 4px, `shadow-sm`). Header: group name in Barlow Condensed 600 at 18px plus "N epics".
- Grid columns: `minmax(220px,2fr) 120px 190px minmax(280px,4fr)`
  - **Epic**: title at 14.5px, 600 weight, as a clickable link (underlined and accent-700 on hover). Below it, Application and then Theme, each on its own line at 12.5px in neutral-700.
  - **Health**: badge.
  - **Forecast**: range, plus a slip line in red when slipped.
  - **Last status update**: full text, multi-line, 13.5px with line-height 1.45. Below it: "{relative time} · {author}", with a hover tooltip showing the full date and time.
- Column header row: uppercase 11.5px with letter-spacing 0.06em, on a neutral-100 background.
- **A single click on the title opens the modal. A double click anywhere on the row also opens it.**
- Row hover background: neutral-100.

### Matrix
- One white panel. Grid columns: `150px repeat(6, minmax(150px,1fr))`, minimum width 1050px, scrolls sideways.
- Header row: stage names only, in Barlow Condensed 600 at 16px, on neutral-100.
- Row labels: Theme or Application (toggle), 13.5px at 600 weight.
- Each cell holds compact items: 1px neutral-300 border, radius 4px, padding 4px 7px. Items are kept small so many fit on one screen:
  - Line 1: health dot (8px) + title at 12px, 600 weight.
  - Line 2: Application (or Theme, when rows are Applications), plus the track if set, at 11px in neutral-700.
  - Line 3: forecast range at 11px.
- **Drag items between cells.** The drop sets both the stage and the row attribute. The target cell gets an accent-100 highlight.
- A legend of health dots sits below the panel.

### Timeline (Gantt)
- One white panel with a horizontal scroll container. Horizontal trackpad scrolling must work, so use `overscroll-behavior-x: contain` to stop swipe-back navigation.
- The label column (270px) is **sticky** on the left. Group header rows are sticky as well, so their text stays visible while scrolling.
- **Range**: the canvas covers every epic's dates plus a buffer, rounded to whole quarters. The **Quarters** control (4/6/8/12) sets how many quarters fit in the visible width, which acts as zoom. It opens scrolled so today sits about 3 months from the left. ‹ and › scroll by one quarter (smooth); **Today** scrolls back. Changing zoom keeps the same date at the left edge.
- Header: quarter label ("Q3 2026", or "Q3 ’26" when narrow) and month initials below, shown only when a month is at least 18px wide. Vertical gridlines mark each quarter.
- **Two-level grouping** (default: Application, then Theme):
  - Level-1 header: 28px high, accent-100 background, Barlow Condensed 600 at 15.5px in accent-900, with a count.
  - Level-2 header: 24px high, neutral-100 background, 12.5px at 600 weight, indented 26px, with a count.
  - Epic rows are indented 14px per level.
- Epic row height: 36px with Details on, 26px with Details off. The label shows the title (13px, 600, ellipsis, clickable to open the modal). With **Details** on it also shows the subtitle "Application · Theme · Stage" at 11px.
- **Bar**, 14px high (12px compact), radius 3px:
  - Spans forecastStart to forecastEnd (falling back to planned). For a **Done** epic it spans actualStart to actualEnd.
  - The fill is the health background color with a border in the health border color.
  - **Elapsed part**: from actualStart to today (or to actualEnd), filled solid in the health's border color. In other words, the elapsed time takes the color of the epic's status.
  - **Overrun**: the part after plannedEnd is drawn with red hatching (135°, 1.5px lines every 5px) and a red "+N mo" label to the right. A Done epic stays **green** but still shows its overrun hatch, labelled "+N mo overrun".
- **Today line**: 2px, color `--color-text`, running the full height.
- **Interactions on bars:**
  - Click (moved under 3px): opens the modal.
  - Drag the body: moves forecastStart and forecastEnd together, snapping to whole months.
  - Drag the left or right edge (10px hit zones, `ew-resize` cursor): changes forecastStart or forecastEnd.
  - The bar previews live while dragging. On release a **confirmation dialog** opens: "Update forecast dates?", the epic title, Current: range, New: range, and the buttons **Cancel** / **Update forecast**. Nothing is saved without confirmation. Esc cancels.
  - Done epics cannot be dragged.
- Legend: the four health swatches (elapsed + remaining), the overrun hatch, the today line, and a hint: "Solid part = elapsed since actual start. Drag a bar or its edges to change the forecast."

---

## Epic modal
- Backdrop: text color at 40% opacity. Panel: white, max-width 960px, radius 4px, `shadow-lg`, 40px from the top, and the backdrop scrolls if needed. Clicking the backdrop or pressing Esc closes the modal (Esc first closes any open picker or dialog).
- **Header**: an editable title input styled as a heading (Barlow Condensed 600, 24px, borderless until hover or focus), and a × close button.
- **Body**: two columns (1.15fr | 1fr).
  - **Left (details):**
    - Description textarea, labelled "Description — what this epic delivers".
    - A 2×2 grid of selects: Application, Theme, Stage, Productization track (disabled unless the stage is Productization).
    - Health: four pill buttons. The selected one uses the health colors; Done has a ✓ icon.
    - Dates: a 3×2 grid (rows Planned / Forecast / Actual, columns Start / End). Each cell is a button showing "Mon YYYY" or "Select" that opens the **month picker**.
    - When forecastEnd is later than plannedEnd, a red line reads "Forecast end is N months later than planned".
  - **Right (status updates)**, on a neutral-100 background:
    - A textarea ("Write an update on progress, risks or decisions…") and an **Add update** button, disabled while empty. New updates are added at the top.
    - Update list, newest first, max height 380px with scrolling. Each update is a white card: avatar circle with initials (22px, accent-200/900), author, relative time (full timestamp in a tooltip), and the text.
- **Footer**: Cancel and **Save** (accent-700 fill). Field edits only take effect on Save. Adding an update saves immediately.
- **To add (from the audit trail requirement):** a **History** tab.

### Month picker (popover, 244px)
- Top row: ‹ | three years (the current year in the middle at first) | ›. The arrows move the years back or forward. The selected year is filled accent-700. The real current year is in bold accent-800 text.
- Below: a 4×3 grid of months (Jan…Dec). The selected month has an accent-100 fill and an accent-700 border.
- Click a year, then a month: the value is set and the **popover closes**. A "Clear" link empties the value. Clicking outside or pressing Esc closes it.

### Relative time format (updates and history)
- under 1 min: "just now"
- under 1 hr: "N min ago"
- under 24 hrs: "N hr(s) ago"
- under 7 days: "N day(s) ago"
- otherwise: the date, e.g. "3 Oct 2026"
- The tooltip always shows the full "3 Oct 2026, 08:40".

---

## Design tokens
The base is the **Industry** design system tokens (`styles.css` is included). Only the tokens are used. The wireframe/blueprint visual treatment of that system was dropped on purpose in favor of an office-app look.

- Fonts: **Barlow Condensed** (headings, 600) and **Barlow** (body), from Google Fonts.
- Page background `--color-bg` #f2f2f3, text `--color-text` #1d1f20, surfaces white.
- Accent (steel blue) base #5980a6, with a 100–900 ramp in `styles.css`. Steps used: 100 (tints/hover), 200, 500, 700 (primary buttons, selected), 800 (hover of primary), 900 (top bar, headings).
- Neutrals used: 100, 200, 300, 400, 600, 700, 800 from `styles.css`.
- Radius `--radius-md` / `--radius-lg` (about 4px). Shadows `--shadow-sm`, `--shadow-md`, `--shadow-lg`.
- **Health colors** (also on the Timeline):
  - On track: bg `accent-200`, text `accent-800`, border/solid `accent-500` (blue)
  - At risk: bg `oklch(0.93 0.07 75)`, text `oklch(0.46 0.11 60)`, border `oklch(0.72 0.14 65)` (orange)
  - Late: bg `oklch(0.92 0.05 25)`, text `oklch(0.47 0.15 25)`, border `oklch(0.6 0.16 25)` (red)
  - Done: bg `oklch(0.93 0.06 150)`, text `oklch(0.40 0.10 150)`, border `oklch(0.6 0.12 150)` (green), plus a ✓ icon on badges
  - Overrun hatch: `oklch(0.6 0.16 25)`
- Health badge: inline pill, 12px, 600 weight, padding 2px 9px, radius 10px.
- Icons: Lucide at stroke width 1.5 (calendar, plus, filter, check).

## State (client)
`view`, `boardBy`, `listBy`, `matrixBy`, `timelineGroup1`, `timelineGroup2`, `quarters` (4/6/8/12), `details` (bool), `filterApps[]`, `filterThemes[]`, `modalDraft`, `pickerState`, `dragState`, `pendingTimelineChange`. It is worth keeping view preferences per user, for example in localStorage.

## Backend requirements (not in the prototype)
- Shared multi-user storage with authentication, so updates and audit entries show real authors.
- Endpoints for Epics (CRUD), status updates (create/list), audit entries (list per epic, written server-side on every Epic change).
- Admin-editable lists of Applications, Themes and Stages.

## Files
- `Roadmap v3.dc.html`: the current prototype and source of truth for behavior. Open it in a browser next to `support.js` and `_ds/`.
- `support.js`: the prototype runtime (reference only).
- `_ds/.../styles.css`: design tokens.
- `Roadmap v2.dc.html`: the previous iteration (reference only).
- `CONVERSATION_CONTEXT.md`: the decisions and feedback history.

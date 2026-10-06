# Context & decision log

## Original ask
We need a tool to record our high-level roadmaps by tracking Epics, with multiple views: per theme, per application (IIVO, Intelligent Algorithms, LetsGrow.com, Intelligent Assistance), per pipeline stage, and as a Gantt chart per quarter. The data per Epic is minimal: title, short description, status/notes, application, theme, and planned, forecast and actual start/end dates (month + year).

## Answers to initial questions
- Six pipeline stages: Validation, Prototyping, Development, Productization, Launch, Learn.
- Productization sub-tracks (Proposition, Documentation, Enablement) shown as tags.
- Status = fixed health (On track / At risk / Late / Done) plus notes, later replaced by status updates.
- Themes: Energy Management, IPM, Yield Prediction, Cultivation.
- Gantt: forecast + actual bars, today marker, slip vs. plan highlight, grouping by theme/app.

## Feedback round 1 (v1 → v2)
- Board: no description on cards (details belong in the modal). Pastel status colors. No numbers before stage names. Card order: Title, category, dates, status.
- List: the description explains what the Epic delivers. Add **status updates**; the List shows the latest one. Columns: Epic (title + application + theme), Health, Forecast, Last status update.
- Matrix: no stage numbers or descriptions. Application and dates on their own rows, small font for density.
- Timeline: compact vertical spacing. 4/6/8/12 quarters. A Details checkbox to hide subtitles. Two-level grouping (e.g. Application, then Theme).
- Clicking an Epic title anywhere opens an editable modal with updates and an option to add one.
- Should feel like an office application (Planner/Trello), not a wireframe.

## Feedback round 2 (v2 → v3)
- Simpler month picker: 3 years with the current year in the middle, arrows, months below; picking a month closes it.
- Update timestamps include time, shown relatively ("2 hrs ago", "2 days ago", then the date).
- A filter by Application/Theme next to Group by.
- Board: draggable cards; show only Application on cards (no Theme).
- List: double-click anywhere on a row opens the modal; the title still opens it on single click.
- Matrix: drag items between stages.
- Timeline: On track = **blue** across the app, so green means Done. The elapsed part is colored by status. Done stays green but still shows overrun. Horizontal trackpad scrolling. Clicking a bar opens the modal. Dragging the bar or its edges asks for confirmation before saving. Clicking the "Details" label toggles it.

## Required for the full spec (from CLAUDE.md)
- **Full audit trail:** every change to an Epic is tracked (who edited which attributes, old → new value, when).
- The Epic modal gets a **History** tab listing that audit trail.

You are redesigning the floating panel UI of a study-helper userscript.

Read these local references first:

- ui-samples/sample-5-reimagined/moodboard/direction-3-nordic-calm.jpg (preferred direction)
- ui-samples/sample-5-reimagined/moodboard/direction-1-editorial.jpg
- ui-samples/sample-5-reimagined/moodboard/direction-2-studio-craft.jpg
- ui-samples/sample-5-reimagined/index.html (current hand-made attempt; improve on it, do not copy it)

Deliver exactly two files:

1. ui-samples/sample-6-agy/index.html
2. ui-samples/sample-6-agy/design-notes.md

Design requirements:

- Desktop-first, 1440x900 reference. Simulate the Chaoxing course page behind the panel.
- Floating drawer 420-480px wide on the right, plus a collapsed bubble state.
- Make your own mature design decisions; the Nordic Calm moodboard is a starting point, not a cage.
- Required UI regions: course/task context, video playback control, task timeline, quiz answering area, running log, settings layer, abnormal/blocked state.
- Realistic Chinese mock data for a Chaoxing course chapter, complete and internally consistent.
- Every control must work with vanilla JS: collapse/expand, tabs, play/pause, speed, switches, quiz choice, log clear, settings save, toast feedback.
- No external assets or CDN links. Inline SVG icons and CSS art only. No network fonts.
- Do not touch the main userscript.
- Keep the palette calm and the typography deliberate; avoid generic dashboard cards.

Write design-notes.md with the chosen direction, layout decisions, component inventory, states covered, and known limits.

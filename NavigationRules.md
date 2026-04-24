# Navigation Rules

This project keeps route and history behavior predictable by separating page navigation from ephemeral UI state.

## Core rules

- Use `context.go(...)` for top-level section switches (for example, `Community` <-> `Me`).
- Use `context.push(...)` for drill-down navigation (for example, feed -> thread).
- Use `context.pop()` to unwind pushed pages.
- Keep non-page UI (lightbox, modal-like overlays) out of the route tree when possible.

## Lightbox behavior

- Lightbox open/close is driven by `forumLightboxController`.
- `ForumShell` renders the overlay above shell content based on controller state.
- Web URL/history integration for lightbox lives in the history bridge:
  - `lightbox_history_bridge_web.dart`
  - `lightbox_history_bridge_stub.dart`
- Router pages stay responsible for page paths; lightbox bridge handles hash/history details.

## History policy

- Prioritize consistent and understandable behavior over perfectly emulating edge cases from large social apps.
- Avoid stacking top-level section history entries.
- Prefer one clear history step for drill-down pages.

## Import style

- Prefer `package:flutter_posts/...` imports for app source files.
- Avoid deep relative imports (`../../..`) to keep refactors easier and imports clearer.

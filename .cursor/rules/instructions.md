---
description: Project-wide architecture rules
globs: lib/**/*.dart
---

# Project Core Context
- **App Type:** Flutter Forum (Reddit-style, What To Expect-Leaning) for caregivers of people with disabilities.
- **Platforms:** iOS first, Android next. NEVER web/desktop (see `AGENTS.md`).
- **Architecture:** Feature-first with Repository Pattern.
- **UI Strategy:** Content-first responsive using `LayoutBuilder` — adapt to
  screen WIDTH (an iPad in landscape gets the wide layout), not to platform.
  Don't use `dart:html` or web-only packages, so the code stays iOS+Android portable.
- **Navigation:** `GoRouter` with deep-linking support.

## Key Instructions
- IMPORTANT: Comment the shit out of stuff, particularly blocks above functions
- When creating UI, always provide a `desktop` and (mocked) `mobile` path using the `ResponsiveLayout` template
- Use `context.push()` for navigation to keep the back-stack clean.
- Prefer `StatelessWidget` with `const` constructors for performance.
- Assume the user is an experienced C++/C# developer, be concise in explanations

## Layout Logic
- Desktop: 2/5/3 split (Sidebar/Feed/Resources) using `Expanded` and `flex`.
- Mobile: Single column `PostList`.
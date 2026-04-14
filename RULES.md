# RULES.md

## Examify Project Rules for Antigravity

You are working on **Examify**, an online examination and proctoring system.

Your job is to improve the codebase **without breaking the current app**.

These rules apply to **all tasks, refactors, fixes, and new features**.

---

## 1. Core Objective
- Preserve the current working functionality.
- Improve maintainability, readability, reusability, and production readiness.
- Make the **smallest safe change first**.
- Do not perform unnecessary rewrites.
- Do not change working logic unless there is a clear bug, security issue, duplication issue, or maintainability reason.

---

## 2. UI / Design Preservation Rules
- **Do not redesign the UI unless explicitly requested.**
- Keep the current colors, spacing, layout, icons, typography, navigation style, and overall visual appearance.
- Preserve the existing user experience for student and teacher dashboards.
- Refactors must be structural, not visual, unless a visual bug is being fixed.
- Shared widget extraction must keep the rendered output visually identical.

---

## 3. Responsive Design Rules
- **Do not break responsiveness.**
- The app must remain usable on:
  - mobile
  - tablet
  - laptop
  - desktop
- Preserve existing responsive behavior such as:
  - `MediaQuery`
  - `LayoutBuilder`
  - `Flexible`
  - `Expanded`
  - `Wrap`
  - responsive paddings and margins
  - drawer/sidebar behavior
- Do not introduce fixed widths or rigid layouts that can cause overflow on small screens.
- Avoid overflow, clipped text, broken alignment, and horizontal scrolling unless explicitly intended.
- Before finalizing any UI change, re-check small-screen behavior.
- If a refactor touches UI code, the output must remain responsive on mobile.

---

## 4. Safe Refactor Rules
- Prefer **incremental refactoring** over large rewrites.
- Refactor one concern at a time.
- Keep changes scoped to the requested task.
- Do not mix unrelated refactors in one pass.
- When extracting shared widgets or utilities:
  - keep feature-specific logic inside feature files
  - move only duplicated scaffolding, reusable UI, or shared helpers
- Do not remove code unless it is clearly dead, duplicated, or replaced safely.
- Do not rename files, classes, or providers unless necessary.
- Keep public interfaces stable when possible.

---

## 5. Flutter Architecture Rules
- Keep UI, business logic, state management, and API concerns separated as much as possible.
- Do not pass `WidgetRef` into plain service/action classes unless there is a very strong reason.
- Avoid mixing provider definitions and unrelated mutation/action helper classes in the same file.
- Prefer maintainable Riverpod patterns.
- Do not overengineer. Use the simplest clean structure that fits the current project.
- Preserve existing functionality while improving structure.

---

## 6. Strong Typing Rules
- Prefer strongly typed Dart models over raw `Map<String, dynamic>` and `dynamic`.
- Avoid `List<dynamic>` when a real model class can be created.
- Add `fromJson` / `toJson` methods where appropriate.
- Keep model fields aligned with the backend response format.
- Do not change backend payload format unless explicitly requested.
- When refactoring providers, return typed models where safely possible.

---

## 7. API / Auth Rules
- Do not hardcode production-sensitive values such as API base URLs, secrets, or tokens.
- Use environment-based configuration where appropriate, such as:
  - `const String.fromEnvironment(...)`
- Keep local development support intact.
- Avoid duplicate logout or navigation logic.
- Do not introduce router race conditions.
- Let auth state drive redirects when the router is already designed that way.
- Ensure token/session clearing happens cleanly and consistently.
- Preserve current login/logout behavior unless fixing a bug.

---

## 8. Backend / Laravel Rules
- Keep controllers thin where possible.
- Avoid stuffing business logic directly into controllers when it belongs in:
  - services
  - resources
  - model/query logic
- Preserve current API responses unless explicitly changing them.
- Do not break existing frontend expectations.
- Keep validation clear and consistent.

---

## 9. Duplication Rules
- Detect and remove duplication where safe.
- Extract only truly shared logic into:
  - widgets
  - helpers
  - utilities
  - services
  - constants
- Do not force abstraction too early.
- Keep role-specific behavior in role-specific files.
- Shared code must improve maintainability, not make the project harder to understand.

---

## 10. File and Folder Rules
- Follow the current project structure unless there is a strong reason to improve it.
- Put shared reusable Flutter UI under appropriate shared widget folders.
- Keep feature-specific code inside feature folders.
- Do not create unnecessary files.
- Keep naming clear, readable, and consistent.

---

## 11. Coding Style Rules
- Write clean, readable, production-safe code.
- Use clear variable, function, class, and file names.
- Avoid long bloated functions when they can be safely split.
- Remove obvious dead code, unused imports, and commented-out clutter only when safe.
- Keep comments useful and minimal.
- Do not add noise comments that restate the obvious.

---

## 12. Testing / Verification Rules
For every meaningful change, provide a short verification checklist.

Always mention what should be tested locally, such as:
- UI rendering
- mobile responsiveness
- dashboard navigation
- login/logout flow
- provider data loading
- API calls
- error states
- role-specific behavior

When changing UI code, always mention:
- mobile view
- tablet view
- desktop view

When changing auth or API code, always mention:
- login
- logout
- token persistence
- unauthorized handling
- redirect behavior

---

## 13. Output Rules for Antigravity
When asked to work on the codebase:
- Be specific and file-based.
- Do not give only high-level advice when actual code is requested.
- Generate the real code changes when asked.
- Explain what changed.
- Explain what stayed the same.
- Mention risks or regression points.
- Keep changes minimal, safe, and relevant.

---

## 14. Things You Must Not Do
- Do not redesign the app without permission.
- Do not break responsiveness.
- Do not replace working logic with a large rewrite.
- Do not introduce desktop-only layouts.
- Do not hardcode production URLs or secrets.
- Do not mix unrelated refactors in one response.
- Do not change backend response contracts unless explicitly requested.
- Do not remove functionality just to simplify code.
- Do not overabstract small pieces of code unnecessarily.

---

## 15. Preferred Refactor Order for This Project
When multiple issues exist, prefer this order unless the user says otherwise:

1. Remove major duplication safely
2. Harden API and auth flow
3. Replace weak typing with typed models
4. Clean up state management / provider structure
5. Improve backend controller/service/resource separation
6. Do smaller cleanup and consistency improvements

---

## 16. Final Standard
Every solution should aim for this result:
- same behavior
- same design
- same responsiveness
- cleaner structure
- less duplication
- safer production setup
- easier future maintenance


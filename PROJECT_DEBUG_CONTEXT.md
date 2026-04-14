# Examify Project Context for Antigravity

## Project Overview
This project is **Examify**, an online examination and classroom system with authentication, role-based access, assessments, and proctoring-related features.

### Main Stack
- **Frontend:** Flutter
- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Secure Local Storage:** FlutterSecureStorage
- **Routing:** GoRouter
- **Backend:** Laravel
- **Authentication:** Laravel Sanctum
- **Database:** MySQL

---

## Important Rule for This Project
Do **not** assume anything without tracing the code first.

When analyzing or fixing bugs:
1. Trace the exact call flow file by file
2. Identify the exact function causing the issue
3. Do not give generic advice only
4. Do not redesign the whole app unless explicitly asked
5. Prefer **minimal fixes**
6. Preserve current architecture as much as possible
7. If uncertain, say **"needs verification in code"**
8. Do not hallucinate files, functions, routes, or logic

---

## Authentication Flow
### Frontend files commonly involved
- `login_screen.dart`
- `auth_provider.dart`
- `api_client.dart`
- `token_interceptor.dart`
- `main.dart`

### Backend files commonly involved
- `routes/api.php`
- `AuthController.php`

### Current Auth Architecture
- Login is triggered from Flutter UI
- Auth state is handled in `auth_provider.dart`
- Dio sends requests to Laravel API
- Token is stored in `FlutterSecureStorage`
- Sanctum is used for protected backend routes
- App may restore login state on restart using stored token
- Router redirects users based on auth state and role

---

## Known Problem History
These issues have already happened before:
- Duplicate `/api/login`
- Duplicate `/api/logout`
- Duplicate `/api/user`
- Duplicate `/api/token/refresh`
- Duplicate `/api/classrooms`
- Router recreation causing duplicate screen mounts
- Auth restore running multiple times
- Manual navigation conflicting with router redirect
- Refresh token race conditions
- Logout only clearing local state before backend fix
- Refresh tokens previously stored in plaintext before hardening

When investigating duplicate requests, always inspect:
- UI event handlers
- provider/notifier lifecycle
- GoRouter recreation
- startup restore flow
- page mount/init fetch logic
- interceptor behavior

---

## Debugging Rules
When I ask you to fix a bug, follow this order:

### Step 1: Analyze first
For each relevant file, explain:
- filename
- purpose
- exact related function
- whether it can cause the bug
- whether the issue is confirmed or only possible

### Step 2: Patch only confirmed causes
Do not edit many files blindly.
Only patch files that are clearly part of the bug.

### Step 3: Keep fixes minimal
Do not do a full refactor unless I explicitly ask.

### Step 4: Output format
When asked for implementation, return:
1. root cause
2. exact affected files
3. minimal code fix
4. final updated code

---

## Preferred Response Style
- Be specific
- Be code-based
- Be conservative
- Do not overclaim
- Do not say "production-ready" unless fully verified
- If a claim is not proven, label it clearly

---

## Git Safety Rules
Before suggesting risky changes:
- prefer small commits
- prefer a new branch
- avoid force push unless clearly necessary
- explain conflict resolution carefully

---

## What I Need Help With Most
- Understanding vibe-coded project structure
- Tracing request flows
- Fixing duplicate requests
- Stabilizing authentication
- Reviewing frontend-backend interaction
- Making minimal safe fixes instead of large rewrites

---

## Instruction for Antigravity
When I ask a question about this project, use this file as reference first.

Do not jump directly to editing code unless I ask for implementation.

If I ask for bug fixing:
- trace the flow first
- identify the exact source
- avoid hallucinating
- give minimal changes only



Read ANTIGRAVITY_CONTEXT.md first. Follow its debugging rules and project constraints before analyzing or editing code.
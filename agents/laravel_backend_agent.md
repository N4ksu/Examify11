# ⚙️ Laravel Backend Agent — Examify

## Role
You are a **Senior Laravel/PHP Developer** working on **Examify**, a Google Classroom-like app with a built-in proctoring engine. You are responsible for the **entire backend**: REST API, database schema, authentication, proctoring logic, and audit trails.

Your counterpart is the **Flutter Frontend Agent** who consumes your APIs. Do NOT touch Flutter files. Your output is a complete, tested Laravel application.

---

## Project Context

**Examify** is an academic assessment platform with two user roles:
- **Teacher** — creates classrooms, posts announcements, creates exams/quizzes/activities, views results and   proctoring audit reports.
- **Student** — joins classrooms, takes proctored assessments, views scores.

**Stack:** PHP 8.2+, Laravel 11, MySQL, Laravel Sanctum (token auth with refresh), phpMyAdmin (dev DB UI).

---

## Project Setup

Create and scaffold at: `c:\Users\DOY\Examify\examify-backend\`

```bash
composer create-project laravel/laravel examify-backend
cd examify-backend
composer require laravel/sanctum
php artisan install:api
```

Configure `.env`:
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=examify_db
DB_USERNAME=root
DB_PASSWORD=
```

---

## Database Schema

Create these migrations in order:

### `users`
```
id, name, email, password, role (enum: teacher|student),
remember_token, timestamps
```

### `personal_access_tokens` (Sanctum default)
Add `expires_at (timestamp nullable)` and `refresh_token (string nullable)` columns.

### `classrooms`
```
id, teacher_id (FK users), name, description,
join_code (unique, 6-char), timestamps
```

### `classroom_students` (pivot)
```
id, classroom_id (FK), student_id (FK users), timestamps
```

### `assessments`
```
id, classroom_id (FK), title, description,
type (enum: exam|quiz|activity),
time_limit_minutes (int nullable),
is_published (boolean, default false),
max_violations (int, default 5),
warn_at_violations (int, default 3),
timestamps
```

### `questions`
```
id, assessment_id (FK), body (text), order (int), timestamps
```

### `options`
```
id, question_id (FK), body (string),
is_correct (boolean, default false), timestamps
```

### `student_attempts`
```
id, assessment_id (FK), student_id (FK users),
status (enum: in_progress|submitted|auto_submitted),
violation_count (int, default 0),
score (int nullable), started_at, submitted_at, timestamps
```

### `student_answers`
```
id, attempt_id (FK student_attempts),
question_id (FK), option_id (FK options nullable), timestamps
```

### `proctoring_logs`
```
id, attempt_id (FK student_attempts),
event_type (enum: alt_tab|app_background|window_blur|fullscreen_exit),
platform (string),         -- android|ios|windows|macos|web
device_info (string),      -- "Pixel 7 / Android 14" or "Chrome 121 / Win11"
ip_address (string),       -- captured from request()->ip()
violation_number (int),    -- nth violation for this attempt
timestamp (timestamp), timestamps
```

### `announcements`
```
id, classroom_id (FK), teacher_id (FK users),
title, body (text), timestamps
```

### `exam_consents`
```
id, assessment_id (FK), student_id (FK users),
ip_address (string), consented_at (timestamp), timestamps
```

---

## API Endpoints

All routes under `routes/api.php`. All protected routes use `auth:sanctum` middleware.

### Auth (Public)

**POST `/api/register`**
```json
Request: { "name": "", "email": "", "password": "", "role": "teacher|student" }
Response 201: { "user": {...}, "access_token": "", "refresh_token": "", "expires_at": "" }
```

**POST `/api/login`**
```json
Request: { "email": "", "password": "" }
Response 200: { "user": {...}, "access_token": "", "refresh_token": "", "expires_at": "" }
```
Token expires in 60 minutes. `expires_at` = `now()->addMinutes(60)`.

**POST `/api/token/refresh`** (Public)
```json
Request: { "refresh_token": "" }
Response 200: { "access_token": "", "refresh_token": "", "expires_at": "" }
Error 401: { "message": "Invalid or expired refresh token" }
```
On refresh: delete old token, issue new access + refresh token pair.

**POST `/api/logout`** (Auth)
Revoke current token.

---

### Classrooms (Auth)

**GET `/api/classrooms`**
- Teacher: returns classrooms they own.
- Student: returns classrooms they're enrolled in.

**POST `/api/classrooms`** (Teacher only)
```json
Request: { "name": "", "description": "" }
Response 201: { "classroom": { ..., "join_code": "ABC123" } }
```
Auto-generate a unique 6-character `join_code`.

**POST `/api/classrooms/{id}/join`** (Student only)
```json
Request: { "join_code": "ABC123" }
Response 200: { "message": "Joined successfully" }
```

**GET `/api/classrooms/{id}/students`** (Teacher only)
Returns list of enrolled students.

**GET `/api/classrooms/{id}/announcements`** (Auth)

**POST `/api/classrooms/{id}/announcements`** (Teacher only)
```json
Request: { "title": "", "body": "" }
```

---

### Assessments (Auth)

**GET `/api/classrooms/{id}/assessments`** (Auth)
- Teacher: all assessments for classroom.
- Student: only published assessments.

**POST `/api/classrooms/{id}/assessments`** (Teacher only)
```json
Request: {
  "title": "", "description": "", "type": "exam|quiz|activity",
  "time_limit_minutes": 60, "is_published": true,
  "questions": [
    { "body": "Question text", "options": [
      { "body": "Option A", "is_correct": false },
      { "body": "Option B", "is_correct": true }
    ]}
  ]
}
```

**GET `/api/assessments/{id}`** (Auth)
Returns assessment with all questions and options.
- For students: shuffle questions if `shuffle_questions = true`.

**POST `/api/assessments/{id}/consent`** (Student only)
```json
Request: {} // captures IP from request()->ip() server-side
Response 201: { "message": "Consent recorded" }
```
Upsert: one consent record per student per assessment.

**POST `/api/assessments/{id}/start`** (Student only)
```
- Check consent exists for this student → 403 if not
- Check no existing in_progress attempt → 409 if exists
- Create student_attempt with status=in_progress
Response 201: { "attempt_id": 1, "started_at": "" }
```

**POST `/api/attempts/{id}/submit`** (Student only)
```json
Request: { "answers": [ { "question_id": 1, "option_id": 3 }, ... ] }
```
- Save all answers.
- Auto-grade: count correct options, set `score`.
- Set `status = submitted`, `submitted_at = now()`.
- Response: `{ "score": 8, "total": 10 }`

---

### Proctoring (Auth + Student)

**POST `/api/attempts/{id}/proctor-event`**
```json
Request: {
  "event_type": "alt_tab|app_background|window_blur|fullscreen_exit",
  "platform": "android|ios|windows|macos|web",
  "device_info": "Pixel 7 / Android 14",
  "timestamp": "2026-02-23T20:45:00Z"
}
```

**Server logic — Violation Threshold (Feature 2):**
```php
$attempt->increment('violation_count');
$count = $attempt->violation_count;

// Log the event
ProctoringLog::create([
    'attempt_id'      => $attempt->id,
    'event_type'      => $request->event_type,
    'platform'        => $request->platform,
    'device_info'     => $request->device_info,
    'ip_address'      => $request->ip(),        // Audit Trail (Feature 3)
    'violation_number' => $count,
    'timestamp'       => $request->timestamp,
]);

// Threshold logic
if ($count >= $attempt->assessment->max_violations) {
    $attempt->update(['status' => 'auto_submitted', 'submitted_at' => now()]);
    return response()->json(['action' => 'auto_submitted']);
}

if ($count >= $attempt->assessment->warn_at_violations) {
    return response()->json(['action' => 'warn', 'violation_count' => $count]);
}

return response()->json(['action' => 'log', 'violation_count' => $count]);
```

---

### Results (Auth)

**GET `/api/attempts/{id}/result`** (Student — own attempt only)
```json
Response: {
  "score": 8, "total": 10, "percentage": 80,
  "status": "submitted",
  "answers": [ { "question": "...", "your_answer": "...", "correct_answer": "...", "is_correct": true } ]
}
```

**GET `/api/assessments/{id}/results`** (Teacher only)
```json
Response: [
  { "student": { "name": "", "email": "" }, "score": 8, "total": 10,
    "status": "submitted", "violation_count": 2, "submitted_at": "" }
]
```

**GET `/api/assessments/{id}/proctoring-report`** (Teacher only)
```json
Response: [
  {
    "student": { "name": "", "email": "" },
    "total_violations": 3,
    "logs": [
      { "event_type": "app_background", "platform": "android",
        "device_info": "Pixel 7 / Android 14", "ip_address": "192.168.1.5",
        "violation_number": 1, "timestamp": "2026-02-23T12:45:00Z" }
    ]
  }
]
```

---

## Policies & Middleware

- `TeacherOnly` middleware: `abort(403)` if `auth()->user()->role !== 'teacher'`
- `StudentOnly` middleware: same for student
- Model policies for ownership checks (student can only submit their own attempt)
- Rate limiting on `POST /api/token/refresh`: 10 req/min

---

## Tests to Write (`tests/Feature/`)

| File | Tests |
|------|-------|
| `AuthTest.php` | Register, Login, Token Refresh (valid + expired), Logout |
| `ClassroomTest.php` | Create, Join by code, invalid code, list classrooms |
| `AssessmentTest.php` | Create with questions, get, consent required before start |
| `ProctoringTest.php` | Log event, violation_count increments, warn at 3, auto-submit at 5 |
| `ResultTest.php` | Submit answers, auto-score, teacher views results |

Run: `php artisan test`

---

## Deliverables

1. Complete Laravel project with all migrations.
2. All API endpoints implemented and returning correct JSON.
3. Proctoring logic with threshold (warn at 3, auto-submit at 5).
4. Audit trail (IP, device, platform) in `proctoring_logs`.
5. Token refresh working with expiry.
6. Consent gate before exam start.
7. Feature tests passing for all modules.

---

## Notes & Constraints

- All timestamps stored in UTC.
- `ip_address` is always captured server-side via `$request->ip()` — never trust client-sent IP.
- `is_correct` auto-grading: match `option_id` to `options.is_correct = true`.
- Never expose `is_correct` in GET responses for students (only for teachers in result review).
- The `max_violations` and `warn_at_violations` are configurable per assessment (defaults: 5 and 3).

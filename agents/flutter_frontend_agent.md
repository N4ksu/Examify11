# 🎨 Flutter Frontend Agent — Examify

## Role
You are a **Senior Flutter/Dart Developer** working on **Examify**, a Google Classroom-like app with a built-in proctoring engine. You are responsible for the **entire Flutter frontend** across Android, iOS, Desktop (Windows/macOS/Linux), and Web.

Your counterpart is the **Laravel Backend Agent** who exposes REST APIs. You consume those APIs via `dio`. Do NOT modify the backend. If an API is missing, document it and flag it.

---

## Project Context

**Examify** is an academic assessment platform with two user roles:
- **Teacher** — creates classrooms, post announcements, creates exams/quizzes/activities, views results and proctoring reports.
- **Student** — joins classrooms, takes proctored assessments, views scores.

**Stack:** Flutter (Dart), Riverpod (state management), GoRouter (navigation), Dio (HTTP), device_info_plus, window_manager, flutter_windowmanager, shared_preferences, intl.

---

## Project Structure

Create the Flutter project at: `c:\Users\DOY\Examify\examify_flutter\`

```
lib/
├── main.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart          # Dio instance + base URL
│   │   └── token_interceptor.dart   # Silent token refresh interceptor
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── proctoring/
│       └── proctoring_service.dart  # Platform-adaptive proctoring engine
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard/
│   │   ├── teacher_dashboard.dart
│   │   └── student_dashboard.dart
│   ├── classroom/
│   │   ├── classroom_detail_screen.dart
│   │   ├── announcements_tab.dart
│   │   └── assessments_tab.dart
│   ├── assessment/
│   │   ├── create/
│   │   │   └── create_assessment_screen.dart
│   │   ├── consent/
│   │   │   └── consent_modal.dart
│   │   ├── take/
│   │   │   └── take_assessment_screen.dart
│   │   └── results/
│   │       ├── student_result_screen.dart
│   │       └── proctoring_report_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── shared/
    ├── models/          # User, Classroom, Assessment, Question, ProctoringLog
    ├── widgets/         # AppButton, AppCard, AppTextField, ViolationBanner
    └── providers/       # Riverpod providers
```

---

## Screens to Build

### Auth
- **LoginScreen** — email + password, calls `POST /api/login`, stores token via shared_preferences.
- **RegisterScreen** — name, email, password, role (Teacher/Student dropdown).

### Teacher
- **TeacherDashboard** — grid of classrooms, FAB to create classroom, sidebar nav on wide screens.
- **CreateAssessmentScreen** — dynamic question builder: add MCQ questions, set correct answer, set time limit, set type (Exam/Quiz/Activity).

### Student
- **StudentDashboard** — grid of joined classrooms, Join Classroom dialog (enter code).

### Shared
- **ClassroomDetailScreen** — tab bar: Announcements | Assessments. Teacher sees "Post Announcement" button. Student sees "Join" button only if not enrolled.
- **ConsentModal** — full-screen bottom sheet or dialog before exam starts.
- **TakeAssessmentScreen** - PROCTORED. Fullscreen. Question navigator. Timer. Submit button.
- **StudentResultScreen** — score, correct/incorrect per question.
- **ProctoringReportScreen** — table of violations: student name, event type, platform, device, IP, timestamp.

---

## Proctoring Engine (`proctoring_service.dart`)

```dart
/// Platform-adaptive proctoring. Call start() when exam begins, stop() on submit.
class ProctoringService with WidgetsBindingObserver {
  final int attemptId;
  int violationCount = 0;
  Function(ProctoringAction)? onViolation; // callback to UI

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) await _lockAndroid();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) await _lockDesktop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mobile: detect app going to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _reportViolation('app_background');
    }
  }

  Future<void> _lockAndroid() async {
    // flutter_windowmanager: FLAG_SECURE
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  Future<void> _lockDesktop() async {
    // window_manager: fullscreen + intercept focus loss
    await windowManager.setFullScreen(true);
    windowManager.addListener(/* focus listener */);
  }

  Future<void> _reportViolation(String eventType) async {
    violationCount++;
    final deviceInfo = await _getDeviceInfo();
    final response = await apiClient.post('/attempts/$attemptId/proctor-event', data: {
      'event_type': eventType,
      'platform': _getPlatformName(),
      'device_info': deviceInfo,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    final action = response.data['action'];
    if (action == 'warn') onViolation?.call(ProctoringAction.warn);
    if (action == 'auto_submitted') onViolation?.call(ProctoringAction.autoSubmitted);
  }
}

enum ProctoringAction { warn, finalWarn, autoSubmitted }
```

---

## Token Refresh Interceptor (`token_interceptor.dart`)

```dart
// On every request: check if stored token expires within 5 min
// If yes: call POST /api/token/refresh with refresh_token
// Store new access_token + expires_at
// If refresh fails (401): clear storage + redirect to LoginScreen
```

---

## Consent Modal Flow

```
Student taps assessment → ConsentModal appears
  Title: "📋 Exam Monitoring Notice"
  Body:  Lists what is monitored (focus, violations, auto-submit, IP)
  Checkbox: "I understand and agree to be monitored"
  [Cancel] → back to classroom
  [Start Exam →] → POST /api/assessments/{id}/consent → navigate to TakeAssessmentScreen
```

---

## Violation UI Banners

| Count | UI |
|-------|----|
| 1–2 | Amber toast: "⚠️ Warning: Focus loss detected" |
| 3 | Persistent red banner: "⚠️ FINAL WARNING — next violation auto-submits" |
| 5 | Full red overlay: "❌ Exam Auto-Submitted due to violations" → navigate to results |

---

## API Contract (consume from backend)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/login` | Auth |
| POST | `/api/register` | Auth |
| POST | `/api/token/refresh` | Token refresh |
| GET | `/api/classrooms` | List classrooms |
| POST | `/api/classrooms` | Create classroom |
| POST | `/api/classrooms/{id}/join` | Join classroom |
| GET | `/api/classrooms/{id}/announcements` | Get announcements |
| POST | `/api/classrooms/{id}/announcements` | Post announcement |
| GET | `/api/classrooms/{id}/assessments` | List assessments |
| POST | `/api/classrooms/{id}/assessments` | Create assessment |
| GET | `/api/assessments/{id}` | Get questions |
| POST | `/api/assessments/{id}/consent` | Record consent |
| POST | `/api/assessments/{id}/start` | Start attempt |
| POST | `/api/attempts/{id}/submit` | Submit answers |
| POST | `/api/attempts/{id}/proctor-event` | Log violation |
| GET | `/api/attempts/{id}/result` | Student result |
| GET | `/api/assessments/{id}/results` | All results (teacher) |
| GET | `/api/assessments/{id}/proctoring-report` | Audit report |

**Base URL (dev):** `http://127.0.0.1:8000/api`
**Auth header:** `Authorization: Bearer <token>`

---

## Design Requirements

- **Theme:** Dark navy + electric blue accent. Premium feel.
- **Typography:** Google Fonts — `Inter`.
- **Responsive:** Sidebar nav on screens > 800px wide. Bottom nav on mobile.
- **Animations:** Page transitions, card hover effects, violation banner slide-in.
- Use `LayoutBuilder` + `AdaptiveScaffold` pattern for responsive layouts.

---

## Deliverables

1. All screens listed above, functional and connected to API.
2. `ProctoringService` working on Android, iOS, Desktop.
3. Token refresh interceptor.
4. Consent modal persisted via API.
5. Responsive layout across phone, tablet, and desktop.
6. `pubspec.yaml` with all dependencies declared.

---

## Notes & Constraints

- Do NOT modify the Laravel backend. Flag missing endpoints.
- All sensitive operations must check `token` before calling API.
- Violation banners must not be dismissible by student — only teacher can clear.
- The exam screen must prevent back navigation (use `WillPopScope`/`PopScope`).

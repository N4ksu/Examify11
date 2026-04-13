import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

import 'core/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'shared/providers/auth_provider.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/teacher_dashboard.dart';
import 'features/dashboard/student_dashboard.dart';
import 'features/classroom/classroom_detail_screen.dart';
import 'features/assessment/create/create_assessment_screen.dart';
import 'features/assessment/consent/consent_modal.dart';
import 'features/assessment/take/take_assessment_screen.dart';
import 'features/assessment/results/student_result_screen.dart';
import 'features/assessment/results/proctoring_report_screen.dart';
import 'features/analytics/exam_analytics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/assessment/manage/manage_questions_screen.dart';
import 'features/assessment/review/review_assessment_screen.dart';
import 'shared/widgets/examify_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Premium Error Handling
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ExamifyErrorScreen(errorDetails: details);
  };

  /// Desktop window size
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1280, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Examify',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ExamifyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Selectively watch only auth status to prevent destructive router rebuilds
  // whenever temporary variables like `isLoading` toggle during requests.
  final isAuthenticated = ref.watch(authProvider.select((state) => state.isAuthenticated));
  final userRole = ref.watch(authProvider.select((state) => state.user?.role.name));

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthRoute =
          state.uri.path == '/' || state.uri.path == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/';

      if (isAuthenticated && isAuthRoute) {
        return userRole == 'teacher' ? '/teacher' : '/student';
      }

      // Role-based protection: Prevent students from accessing teacher routes and vice versa
      if (isAuthenticated) {
        if (state.uri.path.startsWith('/teacher') && userRole != 'teacher') {
          return '/student';
        }
        if (state.uri.path.startsWith('/student') && userRole != 'teacher') {
            // Note: If you are not a teacher, you stay in student routes. 
            // We could be more strict, but this handles the reported issue.
        }
        
        // Strict mapping: if you are a teacher, go to teacher. If student, go to student.
        if (state.uri.path == '/student' && userRole == 'teacher') {
            return '/teacher';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final registered = state.uri.queryParameters['registered'] == 'true';
          return LoginScreen(registered: registered);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/classroom/:id',
        builder: (context, state) =>
            ClassroomDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/classroom/:id/create-assessment',
        builder: (context, state) =>
            CreateAssessmentScreen(classroomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assessment/:id/consent',
        builder: (context, state) =>
            ConsentModal(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assessment/:id/take',
        builder: (context, state) => TakeAssessmentScreen(
          assessmentId: state.pathParameters['id']!,
          attemptId:
              int.tryParse(state.uri.queryParameters['attemptId'] ?? '') ?? 0,
          roomName: state.uri.queryParameters['roomName'],
        ),
      ),
      GoRoute(
        path: '/attempts/:id/result',
        builder: (context, state) => StudentResultScreen(
          assessmentId: '',
          attemptId: int.tryParse(state.pathParameters['id']!),
          result: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/assessment/:id/result',
        builder: (context, state) {
          final extra = state.extra;
          return StudentResultScreen(
            assessmentId: state.pathParameters['id']!,
            attemptId: extra is int ? extra : null,
            result: extra is Map<String, dynamic> ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/assessment/:id/reports',
        builder: (context, state) =>
            ProctoringReportScreen(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assessment/:id/analytics',
        builder: (context, state) =>
            ExamAnalyticsScreen(examId: state.pathParameters['id']!),
      ),
      GoRoute(
        path:
            '/classrooms/:classroomId/assessments/:assessmentId/manage-questions',
        builder: (context, state) => ManageQuestionsScreen(
          assessmentId: state.pathParameters['assessmentId']!,
          classroomId: state.pathParameters['classroomId']!,
        ),
      ),
      GoRoute(
        path:
            '/classrooms/:classroomId/assessments/:assessmentId/review',
        builder: (context, state) => ReviewAssessmentScreen(
          assessmentId: state.pathParameters['assessmentId']!,
          classroomId: state.pathParameters['classroomId']!,
        ),
      ),
      GoRoute(
        path: '/classrooms/:classroomId/assessments/:assessmentId/edit',
        builder: (context, state) => CreateAssessmentScreen(
          classroomId: state.pathParameters['classroomId']!,
          assessmentId: state.pathParameters['assessmentId'],
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

class ExamifyApp extends ConsumerStatefulWidget {
  const ExamifyApp({super.key});

  @override
  ConsumerState<ExamifyApp> createState() => _ExamifyAppState();
}

class _ExamifyAppState extends ConsumerState<ExamifyApp> {
  bool _assetsCached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsCached) {
      precacheImage(const AssetImage('assets/login_bg.webp'), context);
      precacheImage(const AssetImage('assets/cite_logo.webp'), context);
      precacheImage(const AssetImage('assets/jmc_logo.webp'), context);
      _assetsCached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Examify',

      /// Apply custom font to match the UI screenshot
      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(AppTheme.darkTheme.textTheme),
      ),

      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

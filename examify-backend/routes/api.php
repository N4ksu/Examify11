<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

use App\Http\Controllers\Api\ClassroomController;
use App\Http\Controllers\Api\AnnouncementController;

use App\Http\Controllers\Api\AssessmentController;
use App\Http\Controllers\Api\StudentAttemptController;
use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\CourseOutcomeController;
use App\Http\Controllers\Api\RetakeRequestController;

// Public Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/token/refresh', [AuthController::class, 'refresh'])
    ->middleware('throttle:10,1'); // 10 requests per minute

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Classrooms API
    Route::get('/classrooms', [ClassroomController::class, 'index']);
    Route::post('/classrooms', [ClassroomController::class, 'store'])->middleware('teacher');
    Route::get('/classrooms/{id}', [ClassroomController::class, 'show']);
    Route::patch('/classrooms/{id}', [ClassroomController::class, 'update'])->middleware('teacher');
    Route::delete('/classrooms/{id}', [ClassroomController::class, 'destroy'])->middleware('teacher');
    Route::post('/join', [ClassroomController::class, 'joinByCode'])->middleware('student');
    Route::get('/classrooms/{id}/students', [ClassroomController::class, 'students']);

    // Announcements API
    Route::get('/classrooms/{id}/announcements', [AnnouncementController::class, 'index']);
    Route::post('/classrooms/{id}/announcements', [AnnouncementController::class, 'store'])->middleware('teacher');
    Route::patch('/announcements/{id}', [AnnouncementController::class, 'update'])->middleware('teacher');
    Route::delete('/announcements/{id}', [AnnouncementController::class, 'destroy'])->middleware('teacher');

    // Course Outcomes API
    Route::get('/classrooms/{id}/course-outcomes', [CourseOutcomeController::class, 'index']);
    Route::post('/classrooms/{id}/course-outcomes', [CourseOutcomeController::class, 'store'])->middleware('teacher');
    Route::patch('/course-outcomes/{id}', [CourseOutcomeController::class, 'update'])->middleware('teacher');
    Route::delete('/course-outcomes/{id}', [CourseOutcomeController::class, 'destroy'])->middleware('teacher');

    // Assessments API
    Route::get('/classrooms/{id}/assessments', [AssessmentController::class, 'index']);
    Route::post('/classrooms/{id}/assessments', [AssessmentController::class, 'store'])->middleware('teacher');
    Route::get('/assessments/{id}', [AssessmentController::class, 'show']);
    Route::patch('/assessments/{id}', [AssessmentController::class, 'update'])->middleware('teacher');
    Route::delete('/assessments/{id}', [AssessmentController::class, 'destroy'])->middleware('teacher');
    Route::post('/assessments/{id}/consent', [AssessmentController::class, 'consent'])->middleware('student');
    Route::post('/assessments/{id}/start', [AssessmentController::class, 'start'])->middleware('student');
    Route::get('/assessments/{id}/my-attempt', [AssessmentController::class, 'myAttempt'])->middleware('student');

    // Retake requests
    Route::post('/assessments/{assessment}/retake-requests', [RetakeRequestController::class, 'store'])->middleware('student');
    Route::get('/assessments/{assessment}/my-retake-request', [RetakeRequestController::class, 'myRequest'])->middleware('student');
    Route::get('/assessments/{assessment}/used-retakes', [RetakeRequestController::class, 'usedRetakes'])->middleware('student');
    Route::get('/retake-requests/pending', [RetakeRequestController::class, 'teacherIndex'])->middleware('teacher');
    Route::post('/retake-requests/{id}/approve', [RetakeRequestController::class, 'approve'])->middleware('teacher');
    Route::post('/retake-requests/{id}/deny', [RetakeRequestController::class, 'deny'])->middleware('teacher');

    // Question management (teacher only)
    Route::get('/assessments/{assessment}/questions', [App\Http\Controllers\Api\QuestionController::class, 'index'])->middleware('teacher');
    Route::post('/assessments/{assessment}/questions', [App\Http\Controllers\Api\QuestionController::class, 'store'])->middleware('teacher');
    Route::put('/questions/{question}', [App\Http\Controllers\Api\QuestionController::class, 'update'])->middleware('teacher');
    Route::delete('/questions/{question}', [App\Http\Controllers\Api\QuestionController::class, 'destroy'])->middleware('teacher');

    // Attempts & Proctoring API
    Route::prefix('attempts')->group(function () {
        Route::post('/{attempt}/submit', [StudentAttemptController::class, 'submit'])->middleware(['student', 'valid.exam.session']);
        Route::post('/{attempt}/proctor-event', [StudentAttemptController::class, 'proctorEvent'])->middleware(['student', 'valid.exam.session']);
        Route::post('/{attempt}/save-answer', [StudentAttemptController::class, 'saveAnswer'])->middleware(['student', 'valid.exam.session']);
        Route::post('/{attempt}/proctor-snapshots', [StudentAttemptController::class, 'storeProctorSnapshot'])->middleware(['student', 'valid.exam.session']);
    });
    Route::post('/attempts/{id}/override-answer', [StudentAttemptController::class, 'overrideAnswer'])->middleware('teacher');
    Route::post('/start-exam/{id}', [AssessmentController::class, 'startExam'])->middleware('student');

    // Results API
    Route::get('/attempts/{id}/result', [\App\Http\Controllers\Api\ResultController::class, 'studentResult']);
    Route::get('/assessments/{id}/results', [\App\Http\Controllers\Api\ResultController::class, 'teacherResults'])->middleware('teacher');
    Route::get('/assessments/{id}/proctoring-report', [\App\Http\Controllers\Api\ResultController::class, 'proctoringReport'])->middleware('teacher');

    // Teacher Essentials
    Route::get('/analytics/exam/{id}', [AnalyticsController::class, 'getExamAnalytics'])->middleware('teacher');
    Route::get('/assessments/{id}/outcome-analytics', [AnalyticsController::class, 'getExamOutcomeAnalytics'])->middleware('teacher');
});

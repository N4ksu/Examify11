<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use App\Models\Assessment;
use App\Models\ExamConsent;
use App\Models\StudentAttempt;
use App\Models\RetakeRequest;
use Illuminate\Support\Facades\DB;

class AssessmentController extends Controller
{
    public function index(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);
        $user = $request->user();

        $query = $classroom->assessments()->with(['courseOutcome', 'questions']);
        if ($user->role === 'student') {
            if (!$classroom->students()->where('users.id', $user->id)->exists())
                abort(403);
            $query->where('is_published', true)
                ->with(['attempts' => function ($q) use ($user) {
                $q->where('student_id', $user->id)->latest();
            }]);
        }
        else {
            if ($classroom->teacher_id !== $user->id)
                abort(403);
        }

        return response()->json($query->get(), 200);
    }

    public function store(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:exam,quiz,activity',
            'time_limit_minutes' => 'nullable|integer',
            'is_published' => 'required|boolean',
            'max_violations' => 'sometimes|integer',
            'warn_at_violations' => 'sometimes|integer',
            'weight' => 'sometimes|numeric|min:0',
            'course_outcome_id' => 'nullable|integer|exists:course_outcomes,id',
            'show_score' => 'sometimes|boolean',
            'questions' => 'sometimes|array', // optional
            'questions.*.body' => 'required|string',
            'questions.*.type' => 'sometimes|string',
            'questions.*.points' => 'sometimes|integer',
            'questions.*.course_outcome_id' => 'nullable|integer|exists:course_outcomes,id',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.body' => 'required|string',
            'questions.*.options.*.is_correct' => 'required|boolean',
        ]);

        $assessment = null;
        DB::transaction(function () use ($validated, $classroom, &$assessment) {
            $assessment = $classroom->assessments()->create([
                'title' => $validated['title'],
                'description' => $validated['description'] ?? null,
                'type' => $validated['type'],
                'time_limit_minutes' => $validated['time_limit_minutes'] ?? null,
                'is_published' => $validated['is_published'],
                'max_violations' => $validated['max_violations'] ?? 5,
                'warn_at_violations' => $validated['warn_at_violations'] ?? 3,
                'weight' => $validated['weight'] ?? 0,
                'course_outcome_id' => $validated['course_outcome_id'] ?? null,
                'show_score' => $validated['show_score'] ?? true,
            ]);

            // Create questions only if provided (optional)
            if (isset($validated['questions'])) {
                foreach ($validated['questions'] as $qIndex => $qData) {
                    $question = $assessment->questions()->create([
                        'body' => $qData['body'],
                        'type' => $qData['type'] ?? 'multiple_choice',
                        'points' => $qData['points'] ?? 1,
                        'order' => $qIndex,
                        'course_outcome_id' => $qData['course_outcome_id'] ?? null,
                    ]);

                    foreach ($qData['options'] as $oData) {
                        $question->options()->create([
                            'body' => $oData['body'],
                            'is_correct' => $oData['is_correct'],
                        ]);
                    }
                }
            }
        });

        return response()->json($assessment->load('questions.options'), 201);
    }

    public function show(Request $request, $id)
    {
        $assessment = Assessment::with(['questions.options', 'courseOutcome'])->findOrFail($id);
        $user = $request->user();

        if ($user->role === 'student') {
            if (!$assessment->is_published)
                abort(403, 'Assessment not published');
            // Hide is_correct for students
            $assessment->questions->each(function ($question) {
                $question->options->makeHidden('is_correct');
                $question->setRelation('options', $question->options->shuffle()->values());
            });
            // Shuffle questions for students
            $assessment->setRelation('questions', $assessment->questions->shuffle());
        }

        return response()->json($assessment, 200);
    }

    public function consent(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        ExamConsent::updateOrCreate(
        ['assessment_id' => $assessment->id, 'student_id' => $request->user()->id],
        ['ip_address' => $request->ip(), 'consented_at' => now()]
        );

        return response()->json(['message' => 'Consent recorded'], 201);
    }

    public function start(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);
        $user = $request->user();

        $consent = ExamConsent::where('assessment_id', $assessment->id)
            ->where('exam_consents.student_id', $user->id)
            ->first();

        if (!$consent) {
            return response()->json(['message' => 'Consent required'], 403);
        }

        // Check for existing submitted attempt
        // Check for submitted attempt
        $submittedAttempt = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->finished()
            ->first();

        if ($submittedAttempt) {
            // Look for an approved retake request
            $approvedRequest = RetakeRequest::where('assessment_id', $assessment->id)
                ->where('student_id', $user->id)
                ->where('status', 'approved')
                ->latest()
                ->first();

            if (!$approvedRequest) {
                return response()->json(['message' => 'You have already taken this exam. Retakes require teacher approval.'], 403);
            }

            // Mark the request as 'used' to allow future requests
            $approvedRequest->update(['status' => 'used']);
        }

        // Check for in-progress attempt
        $inProgress = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->where('status', 'in_progress')
            ->first();

        if ($inProgress) {
            return response()->json(['message' => 'Attempt already in progress'], 409);
        }

        $attempt = StudentAttempt::create([
            'assessment_id' => $assessment->id,
            'student_id' => $user->id,
            'status' => 'in_progress',
            'started_at' => now(),
        ]);

        return response()->json([
            'attempt_id' => $attempt->id,
            'started_at' => $attempt->started_at->toIso8601String()
        ], 201);
    }

    public function myAttempt(Request $request, $id)
    {
        $user = $request->user();
        $attempt = StudentAttempt::where('assessment_id', $id)
            ->where('student_id', $user->id)
            ->latest()
            ->first();

        if (!$attempt) {
            return response()->json(null, 404);
        }

        return response()->json([
            'id' => $attempt->id,
            'status' => $attempt->status,
            'score' => $attempt->score,
            'submitted_at' => $attempt->submitted_at,
        ]);
    }

    public function update(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);
        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|in:exam,quiz,activity',
            'time_limit_minutes' => 'nullable|integer',
            'is_published' => 'sometimes|boolean',
            'max_violations' => 'sometimes|integer',
            'warn_at_violations' => 'sometimes|integer',
            'weight' => 'sometimes|numeric|min:0',
            'course_outcome_id' => 'nullable|integer|exists:course_outcomes,id',
            'show_score' => 'sometimes|boolean',
        ]);

        $assessment->update($validated);

        return response()->json($assessment->load(['courseOutcome', 'questions.options']), 200);
    }

    public function destroy(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $assessment->delete();

        return response()->json(['message' => 'Assessment deleted successfully'], 200);
    }

    public function startExam(Request $request, $id)
    {
        $user = $request->user();
        $roomName = "Examify_{$id}_{$user->id}";
        return response()->json(['room_name' => $roomName], 200);
    }
}

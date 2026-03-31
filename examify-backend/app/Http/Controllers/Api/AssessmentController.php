<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use App\Models\Assessment;
use App\Models\ExamConsent;
use App\Models\StudentAttempt;
use App\Models\RetakeRequest;
use App\Services\AssessmentService;
use App\Http\Requests\StoreAssessmentRequest;
use App\Http\Requests\UpdateAssessmentRequest;
use Illuminate\Support\Facades\DB;

class AssessmentController extends Controller
{
    protected $assessmentService;

    public function __construct(AssessmentService $assessmentService)
    {
        $this->assessmentService = $assessmentService;
    }

    public function index(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);
        $user = $request->user();

        $query = $classroom->assessments()->with(['courseOutcome', 'questions']);
        if ($user->role === 'student') {
            if (!$classroom->students()->where('users.id', $user->id)->exists())
                abort(403);
            $query = $query->where('is_published', true)
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

    public function store(StoreAssessmentRequest $request, $id)
    {
        $classroom = Classroom::where('id', $id)
            ->where('teacher_id', $request->user()->id)
            ->firstOrFail();

        $assessment = $this->assessmentService->createAssessment($request->validated(), $classroom);

        return response()->json($assessment, 201);
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
                $question->makeHidden(['weight', 'explanation']);
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
        
        try {
            $attempt = $this->assessmentService->startAttempt($assessment, $request->user(), $request->ip(), $request->userAgent());
            
            return response()->json([
                'attempt_id' => $attempt->id,
                'started_at' => $attempt->started_at->toIso8601String()
            ], 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], $e->getCode() ?: 400);
        }
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

    public function update(UpdateAssessmentRequest $request, $id)
    {
        $assessment = Assessment::findOrFail($id);
        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $assessment->update($request->validated());

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

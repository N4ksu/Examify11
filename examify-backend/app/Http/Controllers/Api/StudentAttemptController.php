<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\StudentAttempt;
use App\Models\ProctoringLog;
use App\Models\ProctoringSnapshot;
use App\Services\AssessmentService;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;
use App\Http\Requests\SubmitAttemptRequest;
use App\Http\Requests\ProctorEventRequest;
use App\Http\Requests\OverrideAnswerRequest;
use Illuminate\Support\Facades\DB;

class StudentAttemptController extends Controller
{
    protected $assessmentService;

    public function __construct(AssessmentService $assessmentService)
    {
        $this->assessmentService = $assessmentService;
    }

    public function submit(SubmitAttemptRequest $request, $id)
    {
        $attempt = StudentAttempt::with('assessment.questions.options')->findOrFail($id);
        $user = $request->user();

        // Authorization check: only the student who owns the attempt can submit
        if ($attempt->student_id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        try {
            $result = $this->assessmentService->submitAttempt($attempt, $request->input('answers'));
            return response()->json($result);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function saveAnswer(Request $request, $id)
    {
        $attempt = StudentAttempt::with('assessment.questions.options')->findOrFail($id);
        $user = $request->user();

        if ($attempt->student_id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($attempt->status !== 'in_progress') {
            return response()->json(['message' => 'Attempt no longer active'], 400);
        }

        try {
            $this->assessmentService->saveAnswers($attempt, $request->input('answers', []));
            return response()->json(['message' => 'Answers saved locally']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function storeProctorSnapshot(Request $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);

        $request->validate([
            'image_url' => 'required|url',
            'captured_at' => 'required|date',
        ]);

        $imageUrl = $request->input('image_url');
        $capturedAt = Carbon::parse($request->input('captured_at'));

        $snapshot = ProctoringSnapshot::create([
            'attempt_id' => $attempt->id,
            'image_path' => $imageUrl,
            'captured_at' => $capturedAt,
        ]);

        return response()->json(['message' => 'Snapshot saved successfully', 'snapshot' => $snapshot], 201);
    }

    public function proctorEvent(ProctorEventRequest $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);

        if ($attempt->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($attempt->status !== 'in_progress') {
            return response()->json(['message' => 'Attempt no longer active'], 400);
        }

        $result = $this->assessmentService->handleProctoringEvent($attempt, $request->validated(), $request->ip());

        return response()->json($result);
    }

    public function overrideAnswer(OverrideAnswerRequest $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);
        $user = $request->user();

        // Check if user is the teacher of this assessment
        if ($attempt->assessment->classroom->teacher_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $newScore = $this->assessmentService->applyOverride($attempt, $request->validated());

        return response()->json([
            'message' => 'Override applied successfully',
            'new_score' => $newScore
        ]);
    }
}

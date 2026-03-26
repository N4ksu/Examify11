<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\StudentAttempt;
use App\Models\ProctoringLog;
use App\Services\GradeCalculationService;
use Illuminate\Support\Facades\DB;

class StudentAttemptController extends Controller
{
    protected $gradeService;

    public function __construct(GradeCalculationService $gradeService)
    {
        $this->gradeService = $gradeService;
    }

    public function submit(Request $request, $id)
    {
        $attempt = StudentAttempt::with('assessment.questions.options')->findOrFail($id);
        $user = $request->user();

        // Authorization check: only the student who owns the attempt can submit
        if ($attempt->student_id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $answers = $request->input('answers', []);

        // Validate each answer
        foreach ($answers as $answer) {
            if (!isset($answer['question_id']) || (!isset($answer['option_id']) && !array_key_exists('text_response', $answer))) {
                return response()->json(['error' => 'Each answer must have question_id and either option_id or text_response'], 422);
            }
        }

        DB::transaction(function () use ($attempt, $answers) {
            // Group answers by question_id
            $grouped = collect($answers)->groupBy('question_id');

            foreach ($grouped as $questionId => $items) {
                $question = $attempt->assessment->questions->find($questionId);
                if (!$question) continue;

                if ($question->type === 'essay') {
                    $attempt->answers()->updateOrCreate(
                        ['question_id' => $questionId],
                        ['text_response' => $items[0]['text_response'] ?? '']
                    );
                    continue;
                }

                $selectedOptionIds = collect($items)->pluck('option_id')->unique()->filter()->values();

                // For single‑select questions, ensure at most one option selected
                if (in_array($question->type, ['multiple_choice', 'true_false']) && $selectedOptionIds->count() > 1) {
                    throw new \Exception("Multiple options selected for a single-select question.");
                }

                // Delete old answers for this question
                $attempt->answers()->where('question_id', $questionId)->delete();

                // Insert new answers with is_correct calculation
                foreach ($selectedOptionIds as $optionId) {
                    $selectedOption = $question->options->find($optionId);
                    $attempt->answers()->create([
                        'question_id' => $questionId,
                        'option_id' => $optionId,
                        'is_correct' => $selectedOption ? $selectedOption->is_correct : false,
                    ]);
                }
            }
        });

        // Recalculate score
        $score = $this->gradeService->calculateScore($attempt);
        $maxScore = $attempt->assessment->questions()->sum('points');
        $totalQuestions = $attempt->assessment->questions()->count();
        $percentage = $maxScore > 0 ? ($score / $maxScore) * 100 : 0;

        $attempt->score = $score;
        $attempt->status = 'submitted';
        $attempt->submitted_at = now();
        $attempt->save();

        return response()->json([
            'score' => $score,
            'max_score' => $maxScore,
            'total' => $totalQuestions,
            'percentage' => round($percentage, 2),
        ]);
    }

    public function proctorEvent(Request $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);

        if ($attempt->student_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($attempt->status !== 'in_progress') {
            return response()->json(['message' => 'Attempt no longer active'], 400);
        }

        $validated = $request->validate([
            'event_type' => 'required|in:alt_tab,app_background,window_blur,fullscreen_exit,window_resize,window_maximize,window_unmaximize,window_close_attempt',
            'platform' => 'required|string',
            'device_info' => 'required|string',
            'timestamp' => 'required|date',
            'remark' => 'nullable|string',
        ]);

        $attempt->increment('violation_count');
        $count = $attempt->violation_count;

        ProctoringLog::create([
            'attempt_id' => $attempt->id,
            'event_type' => $validated['event_type'],
            'platform' => $validated['platform'],
            'device_info' => $validated['device_info'],
            'ip_address' => $request->ip(),
            'violation_number' => $count,
            'remark' => $validated['remark'] ?? null,
            'timestamp' => \Carbon\Carbon::parse($validated['timestamp']),
        ]);

        $assessment = $attempt->assessment;

        if ($count >= $assessment->max_violations) {
            $attempt->update(['status' => 'auto_submitted', 'score' => 0, 'submitted_at' => now()]);
            return response()->json(['action' => 'auto_submitted']);
        }

        if ($count >= $assessment->warn_at_violations) {
            return response()->json(['action' => 'warn', 'violation_count' => $count]);
        }

    }

    public function overrideAnswer(Request $request, $id)
    {
        $attempt = StudentAttempt::findOrFail($id);
        $user = $request->user();

        // Check if user is the teacher of this assessment
        if ($attempt->assessment->classroom->teacher_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'question_id' => 'required|exists:questions,id',
            'teacher_override' => 'required|boolean', // true for correct, false for incorrect
        ]);

        // Update all answer rows for this question in this attempt
        $affected = $attempt->answers()
            ->where('question_id', $validated['question_id'])
            ->update(['teacher_override' => $validated['teacher_override']]);

        // If no answers exist (e.g. skipped question), create a dummy one to store the override
        if ($affected === 0) {
            $attempt->answers()->create([
                'question_id' => $validated['question_id'],
                'teacher_override' => $validated['teacher_override'],
            ]);
        }

        // Recalculate and update the attempt score
        $newScore = $this->gradeService->calculateScore($attempt);
        $attempt->update(['score' => $newScore]);

        return response()->json([
            'message' => 'Override applied successfully',
            'new_score' => $newScore
        ]);
    }
}

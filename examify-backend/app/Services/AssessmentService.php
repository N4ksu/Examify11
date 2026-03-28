<?php

namespace App\Services;

use App\Models\Assessment;
use App\Models\StudentAttempt;
use App\Models\ExamConsent;
use App\Models\RetakeRequest;
use App\Models\ProctoringLog;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class AssessmentService
{
    protected $gradeService;

    public function __construct(GradeCalculationService $gradeService)
    {
        $this->gradeService = $gradeService;
    }

    /**
     * Create a new assessment with questions and options.
     */
    public function createAssessment(array $data, $classroom)
    {
        return DB::transaction(function () use ($data, $classroom) {
            $assessment = $classroom->assessments()->create([
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'type' => $data['type'],
                'time_limit_minutes' => $data['time_limit_minutes'] ?? null,
                'is_published' => $data['is_published'],
                'max_violations' => $data['max_violations'] ?? 5,
                'warn_at_violations' => $data['warn_at_violations'] ?? 3,
                'weight' => $data['weight'] ?? 0,
                'course_outcome_id' => $data['course_outcome_id'] ?? null,
                'show_score' => $data['show_score'] ?? true,
            ]);

            if (isset($data['questions'])) {
                foreach ($data['questions'] as $qIndex => $qData) {
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

            return $assessment->load('questions.options');
        });
    }

    /**
     * Start a new attempt for a student.
     */
    public function startAttempt(Assessment $assessment, $user, $ip = null, $userAgent = null)
    {
        $consent = ExamConsent::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->first();

        if (!$consent) {
            throw new \Exception('Consent required', 403);
        }

        $submittedAttempt = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->finished()
            ->first();

        if ($submittedAttempt) {
            $approvedRequest = RetakeRequest::where('assessment_id', $assessment->id)
                ->where('student_id', $user->id)
                ->where('status', 'approved')
                ->latest()
                ->first();

            if (!$approvedRequest) {
                throw new \Exception('You have already taken this exam. Retakes require teacher approval.', 403);
            }

            $approvedRequest->update(['status' => 'used']);
        }

        $inProgress = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->where('status', 'in_progress')
            ->first();

        if ($inProgress) {
            throw new \Exception('Attempt already in progress', 409);
        }

        return StudentAttempt::create([
            'assessment_id' => $assessment->id,
            'student_id' => $user->id,
            'status' => 'in_progress',
            'started_at' => now(),
            'ip_address' => $ip,
            'user_agent' => $userAgent,
        ]);
    }

    /**
     * Submit a student attempt.
     */
    public function submitAttempt(StudentAttempt $attempt, array $answers)
    {
        $this->saveAnswers($attempt, $answers);

        // If attempt was already auto-submitted (e.g. due to violations), 
        // preserve that status and the penalty score (usually 0).
        if ($attempt->status === 'auto_submitted') {
            return [
                'score' => $attempt->score,
                'max_score' => $attempt->assessment->questions()->sum('points'),
                'total' => $attempt->assessment->questions()->count(),
                'status' => 'auto_submitted'
            ];
        }

        $score = $this->gradeService->calculateScore($attempt);
        $maxScore = $attempt->assessment->questions()->sum('points');
        $totalQuestions = $attempt->assessment->questions()->count();
        $percentage = $maxScore > 0 ? ($score / $maxScore) * 100 : 0;

        $attempt->score = $score;
        $attempt->status = 'submitted';
        $attempt->submitted_at = now();
        $attempt->save();

        return [
            'score' => $score,
            'max_score' => $maxScore,
            'total' => $totalQuestions,
            'percentage' => round($percentage, 2),
        ];
    }

    /**
     * Save answers without submitting.
     */
    public function saveAnswers(StudentAttempt $attempt, array $answers)
    {
        DB::transaction(function () use ($attempt, $answers) {
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

                if (in_array($question->type, ['multiple_choice', 'true_false']) && $selectedOptionIds->count() > 1) {
                    throw new \Exception("Multiple options selected for a single-select question.");
                }

                $existingAnswer = $attempt->answers()->where('question_id', $questionId)->first();
                $clientTimestamp = $items[0]['client_timestamp'] ?? null;
                
                if ($existingAnswer && $existingAnswer->client_timestamp && $clientTimestamp) {
                    $existingTime = Carbon::parse($existingAnswer->client_timestamp);
                    $incomingTime = Carbon::parse($clientTimestamp);
                    
                    if ($existingTime->gt($incomingTime)) {
                        continue; // Skip saving because server already has a newer answer
                    }
                }

                $attempt->answers()->where('question_id', $questionId)->delete();

                foreach ($selectedOptionIds as $optionId) {
                    $selectedOption = $question->options->find($optionId);
                    $attempt->answers()->create([
                        'question_id' => $questionId,
                        'option_id' => $optionId,
                        'is_correct' => $selectedOption ? $selectedOption->is_correct : false,
                        'client_timestamp' => $clientTimestamp ? Carbon::parse($clientTimestamp) : now(),
                    ]);
                }
            }
        });
    }

    /**
     * Handle proctoring event.
     */
    public function handleProctoringEvent(StudentAttempt $attempt, array $data, $ip)
    {
        $attempt->increment('violation_count');
        $count = $attempt->violation_count;

        ProctoringLog::create([
            'attempt_id' => $attempt->id,
            'event_type' => $data['event_type'],
            'platform' => $data['platform'],
            'device_info' => $data['device_info'],
            'ip_address' => $ip,
            'violation_number' => $count,
            'remark' => $data['remark'] ?? null,
            'timestamp' => Carbon::parse($data['timestamp']),
        ]);

        $assessment = $attempt->assessment;

        if ($count >= $assessment->max_violations) {
            $attempt->update(['status' => 'auto_submitted', 'score' => 0, 'submitted_at' => now()]);
            return ['action' => 'auto_submitted'];
        }

        if ($count >= $assessment->warn_at_violations) {
            return ['action' => 'warn', 'violation_count' => $count];
        }

        return ['action' => 'none', 'violation_count' => $count];
    }

    /**
     * Apply teacher override.
     */
    public function applyOverride(StudentAttempt $attempt, array $data)
    {
        $affected = $attempt->answers()
            ->where('question_id', $data['question_id'])
            ->update(['teacher_override' => $data['teacher_override']]);

        if ($affected === 0) {
            $attempt->answers()->create([
                'question_id' => $data['question_id'],
                'teacher_override' => $data['teacher_override'],
            ]);
        }

        $newScore = $this->gradeService->calculateScore($attempt);
        $attempt->update(['score' => $newScore]);

        return $newScore;
    }
}

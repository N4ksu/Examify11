<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\StudentAttempt;
use App\Models\Assessment;
use App\Models\User;

class ResultController extends Controller
{
    public function studentResult(Request $request, $id)
    {
        $attempt = StudentAttempt::with(['assessment.questions.options', 'answers'])
            ->findOrFail($id);

        if ($attempt->student_id !== $request->user()->id) {
            abort(403);
        }

        $showScore = $attempt->assessment->show_score;
        $totalPossible = 0;

        $questionsResults = $attempt->assessment->questions->map(function ($question) use ($attempt, &$totalPossible) {
            $totalPossible += $question->points;
            $studentAnswers = $attempt->answers->where('question_id', $question->id);
            $selectedOptionIds = $studentAnswers->pluck('option_id')->toArray();
            
            $pointsEarned = 0;
            $isCorrect = false;
            $responseBody = "";

            if ($question->type === 'essay') {
                $responseBody = $studentAnswers->first()->text_response ?? "No answer";
                // Essay is awaiting grading, don't show correct/incorrect
            } else {
                // Determine response text
                $selectedOptions = $question->options->whereIn('id', $selectedOptionIds);
                $responseBody = $selectedOptions->pluck('body')->join(', ') ?: "No answer";

                // Calculate points (replicate GradeCalculationService logic)
                if ($question->type === 'multiple_select') {
                    $correctOptionIds = $question->options->where('is_correct', true)->pluck('id')->toArray();
                    
                    if ($question->scoring_method === 'partial') {
                        $correctSelected = count(array_intersect($selectedOptionIds, $correctOptionIds));
                        $totalCorrect = count($correctOptionIds);
                        if ($totalCorrect > 0) {
                            $pointsEarned = ($question->points * $correctSelected) / $totalCorrect;
                        }
                        $isCorrect = ($pointsEarned == $question->points);
                    } else {
                        if (count($selectedOptionIds) == count($correctOptionIds) &&
                            empty(array_diff($selectedOptionIds, $correctOptionIds))) {
                            $pointsEarned = $question->points;
                            $isCorrect = true;
                        }
                    }
                } else {
                    // Single select
                    if (count($selectedOptionIds) == 1) {
                        $option = $question->options->find($selectedOptionIds[0]);
                        if ($option && $option->is_correct) {
                            $pointsEarned = $question->points;
                            $isCorrect = true;
                        }
                    }
                }
            }

            return [
                'id' => $question->id,
                'body' => $question->body,
                'type' => $question->type,
                'student_response' => $responseBody,
                'is_correct' => $isCorrect,
                'points_earned' => round($pointsEarned, 2),
                'max_points' => $question->points,
            ];
        });

        return response()->json([
            'score' => $showScore ? $attempt->score : null,
            'total' => $totalPossible,
            'percentage' => $showScore ? round(($attempt->score / ($totalPossible ?: 1)) * 100, 2) : null,
            'show_score' => $showScore,
            'status' => $attempt->status,
            'questions_results' => $showScore ? $questionsResults : [],
        ], 200);
    }

    public function teacherResults(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $totalQuestions = $assessment->questions()->count();

        $results = StudentAttempt::where('assessment_id', $id)
            ->with('student:id,name,email')
            ->get()
            ->map(function ($attempt) use ($totalQuestions) {
                return [
                    'student' => $attempt->student,
                    'score' => $attempt->score,
                    'total' => $totalQuestions,
                    'status' => $attempt->status,
                    'violation_count' => $attempt->violation_count,
                    'submitted_at' => $attempt->submitted_at ? $attempt->submitted_at->toIso8601String() : null,
                ];
            });

        return response()->json($results, 200);
    }

    public function proctoringReport(Request $request, $id)
    {
        $assessment = Assessment::findOrFail($id);

        if ($assessment->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $reports = StudentAttempt::where('assessment_id', $id)
            ->with([
                'student:id,name,email',
                'proctoringLogs' => function ($query) {
                    $query->orderBy('violation_number', 'asc');
                }
            ])
            ->get()
            ->map(function ($attempt) {
                return [
                    'student' => $attempt->student,
                    'total_violations' => $attempt->violation_count,
                    'logs' => $attempt->proctoringLogs->map(function ($log) {
                        return [
                            'event_type' => $log->event_type,
                            'platform' => $log->platform,
                            'device_info' => $log->device_info,
                            'ip_address' => $log->ip_address,
                            'violation_number' => $log->violation_number,
                            'timestamp' => $log->timestamp->toIso8601String(),
                        ];
                    }),
                ];
            });

        return response()->json($reports, 200);
    }
}

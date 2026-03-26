<?php

namespace App\Services;

use App\Models\Classroom;
use App\Models\User;
use App\Models\StudentAttempt;

class GradeCalculationService
{
    public function calculateScore(StudentAttempt $attempt)
    {
        $total = 0;
        $assessment = $attempt->assessment;
        $questions = $assessment->questions()->with('options')->get();

        foreach ($questions as $question) {
            $points = $question->points;
            
            // Check for teacher override first
            $answerRows = $attempt->answers()->where('question_id', $question->id)->get();
            $overrideRow = $answerRows->whereNotNull('teacher_override')->first();
            
            if ($overrideRow !== null) {
                if ($overrideRow->teacher_override) {
                    $total += $points;
                }
                continue;
            }

            $selectedOptionIds = $answerRows->pluck('option_id')->toArray();

            if ($question->type == 'multiple_select') {
                $correctOptionIds = $question->options
                    ->where('is_correct', true)
                    ->pluck('id')
                    ->toArray();

                if ($question->scoring_method === 'partial') {
                    // Partial scoring: each correct selection gives (points / total_correct)
                    // No penalty for incorrect selections.
                    $correctSelected = count(array_intersect($selectedOptionIds, $correctOptionIds));
                    $totalCorrect = count($correctOptionIds);
                    if ($totalCorrect > 0) {
                        $score = ($points * $correctSelected) / $totalCorrect;
                        $total += $score;
                    }
                } else {
                    // Exact match (default)
                    if (count($selectedOptionIds) == count($correctOptionIds) &&
                        empty(array_diff($selectedOptionIds, $correctOptionIds))) {
                        $total += $points;
                    }
                }
            } else if ($question->type !== 'essay') {
                // Single-select (multiple_choice, true_false)
                if (count($selectedOptionIds) == 1) {
                    $selectedOption = $question->options->find($selectedOptionIds[0]);
                    if ($selectedOption && $selectedOption->is_correct) {
                        $total += $points;
                    }
                }
            }
        }
        return $total;
    }

    public function calculateWeightedAverage(Classroom $classroom, User $student)
    {
        $assessments = $classroom->assessments()->where('is_published', true)->get();

        if ($assessments->isEmpty()) {
            return 0;
        }

        $totalWeightedScore = 0;
        $totalWeight = 0;

        foreach ($assessments as $assessment) {
            $attempt = StudentAttempt::where('assessment_id', $assessment->id)
                ->where('student_attempts.student_id', $student->id)
                ->finished()
                ->latest()
                ->first();

            $score = $attempt ? $attempt->score : 0;
            // Assuming score is a percentage or needs to be normalized
            // For now, let's assume assessment max score is 100 or handle accordingly

            $weight = $assessment->weight ?? 0;
            $totalWeightedScore += ($score * $weight);
            $totalWeight += $weight;
        }

        return $totalWeight > 0 ? ($totalWeightedScore / $totalWeight) : 0;
    }
}

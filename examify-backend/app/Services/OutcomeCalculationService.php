<?php

namespace App\Services;

use App\Models\Classroom;
use App\Models\User;
use App\Models\CourseOutcome;
use App\Models\StudentAttempt;
use App\Models\Assessment;

class OutcomeCalculationService
{
    /**
     * Calculate per-outcome scores for a given classroom and student.
     *
     * Returns an associative array keyed by outcome code (or ID fallback) with
     * numeric scores (0–100) representing the student's mastery for each outcome.
     */
    public function calculateOutcomeScores(Classroom $classroom, User $student): array
    {
        $outcomes = CourseOutcome::where('classroom_id', $classroom->id)->get();

        if ($outcomes->isEmpty()) {
            return [];
        }

        $results = [];

        foreach ($outcomes as $outcome) {
            $assessments = Assessment::where('course_outcome_id', $outcome->id)->where('is_published', true)->get();

            if ($assessments->isEmpty()) {
                continue;
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

                $assessmentWeight = $assessment->weight ?? 100;
                $outcomeWeightWithinAssessment = 100; // Pivot removed, assume full weight

                $effectiveWeight = ($assessmentWeight * $outcomeWeightWithinAssessment) / 100;

                $totalWeightedScore += ($score * ($effectiveWeight / 100));
                $totalWeight += $effectiveWeight;
            }

            if ($totalWeight <= 0) {
                continue;
            }

            $average = $totalWeightedScore / ($totalWeight / 100);

            $key = $outcome->code ?: (string) $outcome->id;
            $results[$key] = round((double) $average, 1);
        }

        return $results;
    }
}


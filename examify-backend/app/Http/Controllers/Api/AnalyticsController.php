<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Assessment;
use App\Models\StudentAttempt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function getExamAnalytics($id)
    {
        $assessment = Assessment::findOrFail($id);

        $attempts = StudentAttempt::where('assessment_id', $id)
            ->finished()
            ->latest()
            ->get()
            ->unique('student_id');

        if ($attempts->isEmpty()) {
            return response()->json([
                'average_score' => 0,
                'highest_score' => 0,
                'lowest_score' => 0,
                'distribution' => [],
            ]);
        }

        $average = $attempts->avg('score');
        $highest = $attempts->max('score');
        $lowest = $attempts->min('score');

        // Frequency distribution (histogram data)
        $distribution = $attempts->groupBy(function ($item) {
            return floor($item->score / 10) * 10;
        })->map->count();

        // Fix: join with student_answers and options
        $questionPerformance = DB::table('questions')
            ->where('questions.assessment_id', $id)
            ->leftJoin('student_answers', 'questions.id', '=', 'student_answers.question_id')
            ->leftJoin('options', 'student_answers.option_id', '=', 'options.id')
            ->select(
                'questions.id',
                'questions.body as text',
                DB::raw('SUM(CASE WHEN options.is_correct = 1 THEN 1 ELSE 0 END) as correct_count'),
                DB::raw('SUM(CASE WHEN options.is_correct = 0 THEN 1 ELSE 0 END) as incorrect_count')
            )
            ->groupBy('questions.id', 'questions.body')
            ->get();

        return response()->json([
            'classroom_id' => $assessment->classroom_id,
            'average_score' => round($average, 2),
            'highest_score' => $highest,
            'lowest_score' => $lowest,
            'score_distribution' => $distribution,
            'question_performance' => $questionPerformance,
        ]);
    }

    public function getExamOutcomeAnalytics($assessmentId)
    {
        $assessment = Assessment::findOrFail($assessmentId);

        // 1. Get raw queries for breakdown
        $results = DB::table('course_outcomes')
            ->where('course_outcomes.classroom_id', $assessment->classroom_id) // ensures we only track outcomes relevant here
            ->leftJoin('questions', function($join) use ($assessmentId) {
                 $join->on('course_outcomes.id', '=', 'questions.course_outcome_id')
                      ->where('questions.assessment_id', '=', $assessmentId);
            })
            ->leftJoin('student_attempts', function ($join) use ($assessmentId) {
                $join->on('questions.assessment_id', '=', 'student_attempts.assessment_id')
                     ->whereIn('student_attempts.status', ['submitted', 'auto_submitted']);
            })
            ->leftJoin('student_answers', function ($join) {
                $join->on('student_attempts.id', '=', 'student_answers.attempt_id')
                     ->on('questions.id', '=', 'student_answers.question_id');
            })
            ->leftJoin('options', 'student_answers.option_id', '=', 'options.id')
            ->select(
                'course_outcomes.id',
                'course_outcomes.code',
                'course_outcomes.description',
                DB::raw('SUM(CASE WHEN student_attempts.id IS NOT NULL THEN questions.points ELSE 0 END) as possible_points'),
                DB::raw('SUM(CASE WHEN options.is_correct = 1 THEN questions.points ELSE 0 END) as earned_points')
            )
            ->groupBy('course_outcomes.id', 'course_outcomes.code', 'course_outcomes.description')
            ->get();

        $totalEarned = 0;
        $totalPossible = 0;
        $lowestMastery = 100.0;
        $lowestCoCode = null;
        $lowestCoId = null;

        // 2. Format breakdown and calculate overall
        $breakdown = $results->map(function ($item) use (&$totalEarned, &$totalPossible, &$lowestMastery, &$lowestCoCode, &$lowestCoId) {
            $possible = (int) $item->possible_points;
            $earned = (int) $item->earned_points;
            $mastery = $possible > 0 ? ($earned / $possible) * 100 : 0;

            $totalEarned += $earned;
            $totalPossible += $possible;

            if ($possible > 0 && $mastery < $lowestMastery) {
                $lowestMastery = $mastery;
                $lowestCoCode = $item->code;
                $lowestCoId = $item->id;
            }

            return [
                'id' => $item->id,
                'code' => $item->code,
                'description' => $item->description,
                'possible_points' => $possible,
                'earned_points' => $earned,
                'mastery_percentage' => round($mastery, 1),
            ];
        });

        // 3. Find struggling students for the weakest CO
        $strugglingStudents = [];
        if ($lowestCoId !== null) {
            // Find students who scored lowest on this specific CO in this exam
            $strugglingStudents = DB::table('users')
                ->join('student_attempts', 'users.id', '=', 'student_attempts.student_id')
                ->join('student_answers', 'student_attempts.id', '=', 'student_answers.attempt_id')
                ->join('questions', 'student_answers.question_id', '=', 'questions.id')
                ->leftJoin('options', 'student_answers.option_id', '=', 'options.id')
                ->where('student_attempts.assessment_id', $assessmentId)
                ->whereIn('student_attempts.status', ['submitted', 'auto_submitted'])
                ->where('questions.course_outcome_id', $lowestCoId)
                ->select(
                    'users.id',
                    'users.name',
                    DB::raw('SUM(questions.points) as possible_points'),
                    DB::raw('SUM(CASE WHEN options.is_correct = 1 THEN questions.points ELSE 0 END) as earned_points')
                )
                ->groupBy('users.id', 'users.name')
                ->orderByRaw('(SUM(CASE WHEN options.is_correct = 1 THEN questions.points ELSE 0 END) / SUM(questions.points)) ASC')
                ->limit(5)
                ->get()
                ->map(function($student) {
                    $possible = (int) $student->possible_points;
                    $earned = (int) $student->earned_points;
                    return [
                        'id' => $student->id,
                        'name' => $student->name,
                        'mastery_percentage' => $possible > 0 ? round(($earned / $possible) * 100, 1) : 0
                    ];
                });
        }

        $overallMastery = $totalPossible > 0 ? ($totalEarned / $totalPossible) * 100 : 0;

        return response()->json([
            'overall_mastery' => round($overallMastery, 1),
            'lowest_co' => $lowestCoCode,
            'breakdown' => $breakdown,
            'struggling_students' => $strugglingStudents
        ]);
    }
}

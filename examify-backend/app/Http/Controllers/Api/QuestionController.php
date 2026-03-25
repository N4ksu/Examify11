<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Assessment;
use App\Models\Question;
use Illuminate\Support\Facades\DB;

class QuestionController extends Controller
{
    // List all questions for an assessment
    public function index(Assessment $assessment)
    {
        // Optional: check teacher authorization
        $this->authorizeTeacher($assessment);

        $questions = $assessment->questions()->with('options')->orderBy('order')->get();
        return response()->json($questions);
    }

    // Store a new question (and its options if MCQ/TF)
    public function store(Request $request, Assessment $assessment)
    {
        $this->authorizeTeacher($assessment);

        $validated = $request->validate([
            'body' => 'required|string',
            'type' => 'required|in:multiple_choice,true_false,essay,multiple_select',
            'points' => 'required|integer|min:1',
            'scoring_method' => 'sometimes|in:exact,partial',
            'options' => 'array|required_if:type,multiple_choice,true_false,multiple_select',
            'options.*.body' => 'required|string',
            'options.*.is_correct' => 'required|boolean',
        ]);

        $question = null;
        DB::transaction(function () use ($assessment, $validated, &$question) {
            $question = $assessment->questions()->create([
                'body' => $validated['body'],
                'type' => $validated['type'],
                'points' => $validated['points'],
                'scoring_method' => $validated['scoring_method'] ?? 'exact',
                'order' => $assessment->questions()->max('order') + 1,
            ]);

            if (in_array($validated['type'], ['multiple_choice', 'true_false', 'multiple_select'])) {
                foreach ($validated['options'] as $option) {
                    $question->options()->create($option);
                }
            }
        });

        return response()->json($question->load('options'), 201);
    }

    // Update an existing question (including its options)
    public function update(Request $request, Question $question)
    {
        $this->authorizeTeacher($question->assessment);

        $validated = $request->validate([
            'body' => 'sometimes|string',
            'type' => 'sometimes|in:multiple_choice,true_false,essay,multiple_select',
            'points' => 'sometimes|integer|min:1',
            'scoring_method' => 'sometimes|in:exact,partial',
            'options' => 'array|required_if:type,multiple_choice,true_false,multiple_select',
            'options.*.id' => 'nullable|exists:options,id',
            'options.*.body' => 'required|string',
            'options.*.is_correct' => 'required|boolean',
        ]);

        DB::transaction(function () use ($question, $validated) {
            $question->update($validated);

            if (isset($validated['options'])) {
                // Simple: delete all old options and recreate
                $question->options()->delete();
                foreach ($validated['options'] as $option) {
                    $question->options()->create([
                        'body' => $option['body'],
                        'is_correct' => $option['is_correct'],
                    ]);
                }
            }
        });

        return response()->json($question->load('options'));
    }

    // Delete a question (cascade will delete options)
    public function destroy(Question $question)
    {
        $this->authorizeTeacher($question->assessment);
        $question->delete();
        return response()->json(['message' => 'Deleted'], 200);
    }

    // Helper to check teacher authorization
    private function authorizeTeacher($assessment)
    {
        $user = request()->user();
        if ($user->role !== 'teacher' || $assessment->classroom->teacher_id !== $user->id) {
            abort(403, 'Unauthorized');
        }
    }
}
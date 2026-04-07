<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAssessmentRequest extends FormRequest
{
    public function authorize()
    {
        return true; // Controller handles classroom/teacher check
    }

    public function rules()
    {
        return [
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
            'questions' => 'sometimes|array',
            'questions.*.body' => 'required|string',
            'questions.*.type' => 'sometimes|string',
            'questions.*.points' => 'sometimes|integer',
            'questions.*.course_outcome_id' => 'nullable|integer|exists:course_outcomes,id',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.options.*.body' => 'required|string',
            'questions.*.options.*.is_correct' => 'required|boolean',
        ];
    }
}

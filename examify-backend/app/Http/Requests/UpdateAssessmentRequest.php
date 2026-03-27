<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAssessmentRequest extends FormRequest
{
    public function authorize()
    {
        return true; 
    }

    public function rules()
    {
        return [
            'title' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
            'type' => 'sometimes|in:exam,quiz,activity',
            'time_limit_minutes' => 'nullable|integer',
            'is_published' => 'sometimes|boolean',
            'max_violations' => 'sometimes|integer',
            'warn_at_violations' => 'sometimes|integer',
            'weight' => 'sometimes|numeric|min:0',
            'course_outcome_id' => 'nullable|integer|exists:course_outcomes,id',
            'show_score' => 'sometimes|boolean',
        ];
    }
}

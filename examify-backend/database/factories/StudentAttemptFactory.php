<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\StudentAttempt>
 */
class StudentAttemptFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'assessment_id' => \App\Models\Assessment::factory(),
            'student_id' => \App\Models\User::factory(),
            'status' => 'in_progress',
            'violation_count' => 0,
            'score' => 0,
            'started_at' => now(),
        ];
    }
}

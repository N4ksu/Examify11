<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Assessment;
use App\Models\Question;
use App\Models\Option;

class QuestionDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $assessments = Assessment::all();

        foreach ($assessments as $assessment) {
            // Add some questions to each assessment
            $q1 = Question::updateOrCreate(
                ['assessment_id' => $assessment->id, 'body' => 'What is the capital of France?'],
                ['type' => 'multiple_choice', 'points' => 10]
            );

            Option::updateOrCreate(['question_id' => $q1->id, 'body' => 'Paris'], ['is_correct' => true]);
            Option::updateOrCreate(['question_id' => $q1->id, 'body' => 'London'], ['is_correct' => false]);
            Option::updateOrCreate(['question_id' => $q1->id, 'body' => 'Berlin'], ['is_correct' => false]);

            $q2 = Question::updateOrCreate(
                ['assessment_id' => $assessment->id, 'body' => 'Which planet is known as the Red Planet?'],
                ['type' => 'multiple_choice', 'points' => 10]
            );

            Option::updateOrCreate(['question_id' => $q2->id, 'body' => 'Mars'], ['is_correct' => true]);
            Option::updateOrCreate(['question_id' => $q2->id, 'body' => 'Venus'], ['is_correct' => false]);
            Option::updateOrCreate(['question_id' => $q2->id, 'body' => 'Jupiter'], ['is_correct' => false]);
        }
    }
}

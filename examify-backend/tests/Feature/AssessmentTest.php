<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Classroom;
use App\Models\Assessment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssessmentTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_can_create_assessment_with_questions()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        $classroom = Classroom::factory()->create(['teacher_id' => $teacher->id]);

        $response = $this->actingAs($teacher)
            ->postJson("/api/classrooms/{$classroom->id}/assessments", [
                'title' => 'Biology Quiz',
                'type' => 'quiz',
                'is_published' => true,
                'questions' => [
                    [
                        'body' => 'What is the powerhouse of the cell?',
                        'options' => [
                            ['body' => 'Nucleus', 'is_correct' => false],
                            ['body' => 'Mitochondria', 'is_correct' => true],
                        ]
                    ]
                ]
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('assessments', ['title' => 'Biology Quiz']);
        $this->assertDatabaseHas('questions', ['body' => 'What is the powerhouse of the cell?']);
        $this->assertDatabaseHas('options', ['body' => 'Mitochondria', 'is_correct' => true]);
    }

    public function test_student_can_consent_to_assessment()
    {
        $student = User::factory()->create(['role' => 'student']);
        $assessment = Assessment::factory()->create(['is_published' => true]);

        $response = $this->actingAs($student)
            ->postJson("/api/assessments/{$assessment->id}/consent");

        $response->assertStatus(201);
        $this->assertDatabaseHas('exam_consents', [
            'assessment_id' => $assessment->id,
            'student_id' => $student->id
        ]);
    }

    public function test_student_can_start_attempt_after_consent()
    {
        $student = User::factory()->create(['role' => 'student']);
        $assessment = Assessment::factory()->create(['is_published' => true]);

        // Give consent first
        $this->actingAs($student)->postJson("/api/assessments/{$assessment->id}/consent");

        $response = $this->actingAs($student)
            ->postJson("/api/assessments/{$assessment->id}/start");

        $response->assertStatus(201)
            ->assertJsonStructure(['attempt_id', 'started_at']);

        $this->assertDatabaseHas('student_attempts', [
            'assessment_id' => $assessment->id,
            'student_id' => $student->id,
            'status' => 'in_progress'
        ]);
    }

    public function test_student_only_sees_published_assessments()
    {
        $student = User::factory()->create(['role' => 'student']);
        $classroom = Classroom::factory()->create();
        $classroom->students()->attach($student->id);

        Assessment::factory()->create([
            'classroom_id' => $classroom->id,
            'title' => 'Published Exam',
            'is_published' => true,
        ]);

        Assessment::factory()->create([
            'classroom_id' => $classroom->id,
            'title' => 'Unpublished Exam',
            'is_published' => false,
        ]);

        $response = $this->actingAs($student)
            ->getJson("/api/classrooms/{$classroom->id}/assessments");

        $response->assertStatus(200)
            ->assertJsonCount(1)
            ->assertJsonFragment(['title' => 'Published Exam'])
            ->assertJsonMissing(['title' => 'Unpublished Exam']);
    }
}

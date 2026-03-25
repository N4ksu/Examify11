<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Assessment;
use App\Models\StudentAttempt;
use App\Models\ProctoringLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ResultTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_view_own_result()
    {
        $student = User::factory()->create(['role' => 'student']);
        $assessment = Assessment::factory()->create();
        $attempt = StudentAttempt::factory()->create([
            'assessment_id' => $assessment->id,
            'student_id' => $student->id,
            'status' => 'submitted',
            'score' => 5
        ]);

        $response = $this->actingAs($student)
            ->getJson("/api/attempts/{$attempt->id}/result");

        $response->assertStatus(200)
            ->assertJsonPath('score', 5);
    }

    public function test_teacher_can_view_assessment_results()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        $classroom = \App\Models\Classroom::factory()->create(['teacher_id' => $teacher->id]);
        $assessment = Assessment::factory()->create(['classroom_id' => $classroom->id]);

        StudentAttempt::factory()->count(2)->create([
            'assessment_id' => $assessment->id,
            'status' => 'submitted'
        ]);

        $response = $this->actingAs($teacher)
            ->getJson("/api/assessments/{$assessment->id}/results");

        $response->assertStatus(200)->assertJsonCount(2);
    }

    public function test_teacher_can_view_proctoring_report()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        $classroom = \App\Models\Classroom::factory()->create(['teacher_id' => $teacher->id]);
        $assessment = Assessment::factory()->create(['classroom_id' => $classroom->id]);
        $attempt = StudentAttempt::factory()->create(['assessment_id' => $assessment->id]);

        ProctoringLog::create([
            'attempt_id' => $attempt->id,
            'event_type' => 'alt_tab',
            'platform' => 'windows',
            'device_info' => 'Chrome',
            'ip_address' => '127.0.0.1',
            'violation_number' => 1,
            'timestamp' => now()
        ]);

        $response = $this->actingAs($teacher)
            ->getJson("/api/assessments/{$assessment->id}/proctoring-report");

        $response->assertStatus(200);
        $this->assertCount(1, $response->json()[0]['logs']);
    }
}

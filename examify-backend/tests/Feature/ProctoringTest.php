<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Assessment;
use App\Models\StudentAttempt;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProctoringTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_log_proctoring_event()
    {
        $student = User::factory()->create(['role' => 'student']);
        $attempt = StudentAttempt::factory()->create([
            'student_id' => $student->id,
            'status' => 'in_progress'
        ]);

        $response = $this->actingAs($student)
            ->postJson("/api/attempts/{$attempt->id}/proctor-event", [
                'event_type' => 'alt_tab',
                'platform' => 'windows',
                'device_info' => 'Chrome on Windows 10',
                'timestamp' => now()->toIso8601String(),
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('proctoring_logs', [
            'attempt_id' => $attempt->id,
            'event_type' => 'alt_tab'
        ]);

        $this->assertEquals(1, $attempt->refresh()->violation_count);
    }

    public function test_auto_submission_on_max_violations()
    {
        $student = User::factory()->create(['role' => 'student']);
        $assessment = Assessment::factory()->create(['max_violations' => 2]);
        $attempt = StudentAttempt::factory()->create([
            'assessment_id' => $assessment->id,
            'student_id' => $student->id,
            'status' => 'in_progress',
            'violation_count' => 1
        ]);

        $response = $this->actingAs($student)
            ->postJson("/api/attempts/{$attempt->id}/proctor-event", [
                'event_type' => 'alt_tab',
                'platform' => 'windows',
                'device_info' => 'Chrome on Windows 10',
                'timestamp' => now()->toIso8601String(),
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('action', 'auto_submitted');

        $this->assertEquals('auto_submitted', $attempt->refresh()->status);
    }
}

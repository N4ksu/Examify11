<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Classroom;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClassroomTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_can_create_classroom()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);

        $response = $this->actingAs($teacher)
            ->postJson('/api/classrooms', [
                'name' => 'Math 101',
                'description' => 'Algebra and Geometry',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('classroom.name', 'Math 101');

        $this->assertDatabaseHas('classrooms', ['name' => 'Math 101']);
    }

    public function test_student_can_join_classroom()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        $student = User::factory()->create(['role' => 'student']);
        $classroom = Classroom::factory()->create([
            'teacher_id' => $teacher->id,
            'join_code' => 'JOINME'
        ]);

        $response = $this->actingAs($student)
            ->postJson("/api/join", [
                'join_code' => 'joinme' // Case insensitive test
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('classroom_students', [
            'classroom_id' => $classroom->id,
            'student_id' => $student->id
        ]);
    }

    public function test_teacher_can_list_their_classrooms()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        Classroom::factory()->count(3)->create(['teacher_id' => $teacher->id]);

        $response = $this->actingAs($teacher)->getJson('/api/classrooms');

        $response->assertStatus(200)->assertJsonCount(3);
    }

    public function test_student_can_list_their_joined_classrooms()
    {
        $teacher = User::factory()->create(['role' => 'teacher']);
        // Give the student a school student_id that is NOT their database id
        $student = User::factory()->create([
            'role' => 'student',
            'student_id' => 'STUDENT-123'
        ]);
        
        $classroom1 = Classroom::factory()->create(['teacher_id' => $teacher->id]);
        $classroom2 = Classroom::factory()->create(['teacher_id' => $teacher->id]);
        $classroom3 = Classroom::factory()->create(['teacher_id' => $teacher->id]);

        $classroom1->students()->attach($student->id);
        $classroom2->students()->attach($student->id);

        $response = $this->actingAs($student)->getJson('/api/classrooms');

        $response->assertStatus(200)
            ->assertJsonCount(2)
            ->assertJsonFragment(['id' => $classroom1->id])
            ->assertJsonFragment(['id' => $classroom2->id])
            ->assertJsonMissing(['id' => $classroom3->id]);
    }
}

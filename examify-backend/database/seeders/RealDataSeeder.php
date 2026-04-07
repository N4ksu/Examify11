<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Classroom;
use App\Models\Assessment;
use App\Models\StudentAttempt;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class RealDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create or get Teacher
        $teacher = User::updateOrCreate(
            ['email' => 'teacher1@gmail.com'],
            [
                'name' => 'Teacher One',
                'password' => Hash::make('password'),
                'role' => 'teacher',
            ]
        );

        // 2. Create Classroom
        $classroom = Classroom::updateOrCreate(
            ['name' => '2325', 'teacher_id' => $teacher->id],
            [
                'description' => '123123',
                'join_code' => 'PGDKXR', // As seen in screenshot
            ]
        );

        // 3. Create Students
        $students = [
            [
                'name' => 'Juan Dela Cruz',
                'email' => 'juan@example.com',
                'student_id' => '2024-001',
                'section' => '1A',
            ],
            [
                'name' => 'Maria Clara',
                'email' => 'maria@example.com',
                'student_id' => '2024-002',
                'section' => '1A',
            ],
        ];

        foreach ($students as $studentData) {
            $student = User::updateOrCreate(
                ['email' => $studentData['email']],
                [
                    'name' => $studentData['name'],
                    'student_id' => $studentData['student_id'],
                    'section' => $studentData['section'],
                    'role' => 'student',
                    'password' => Hash::make('password'),
                ]
            );

            // Enroll in classroom
            $classroom->students()->syncWithoutDetaching([$student->id]);
        }

        // 4. Create Assessments
        $midterm = Assessment::updateOrCreate(
            ['classroom_id' => $classroom->id, 'title' => 'Midterm'],
            [
                'type' => 'exam',
                'weight' => 40,
                'is_published' => true,
                'time_limit_minutes' => 60,
            ]
        );

        $finals = Assessment::updateOrCreate(
            ['classroom_id' => $classroom->id, 'title' => 'Finals'],
            [
                'type' => 'exam',
                'weight' => 60,
                'is_published' => true,
                'time_limit_minutes' => 60,
            ]
        );

        // 5. Create Attempts (Scores)
        $scores = [
            'juan@example.com' => ['Midterm' => 85, 'Finals' => 90],
            'maria@example.com' => ['Midterm' => 92, 'Finals' => 88],
        ];

        foreach ($scores as $email => $data) {
            $user = User::where('email', $email)->first();

            // Midterm
            StudentAttempt::updateOrCreate(
                ['assessment_id' => $midterm->id, 'student_id' => $user->id],
                ['score' => $data['Midterm'], 'status' => 'submitted']
            );

            // Finals
            StudentAttempt::updateOrCreate(
                ['assessment_id' => $finals->id, 'student_id' => $user->id],
                ['score' => $data['Finals'], 'status' => 'submitted']
            );
        }
    }
}

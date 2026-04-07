<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\SkipsEmptyRows;

class StudentImport implements ToModel, WithHeadingRow, SkipsEmptyRows
{
    protected $classroomId;

    public function __construct($classroomId = null)
    {
        $this->classroomId = $classroomId;
    }

    /**
     * @param array $row
     *
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function model(array $row)
    {
        // Flexible Mapping
        $name = $row['name'] ?? $row['full_name'] ?? $row['student_name'] ?? $row['user_name'] ?? null;
        $email = $row['email'] ?? $row['email_address'] ?? $row['user_email'] ?? null;
        $studentId = $row['student_id'] ?? $row['id_number'] ?? $row['id'] ?? null;
        $section = $row['section'] ?? $row['class_section'] ?? null;

        if (!$email || !$name) {
            return null; // Skip if mandatory fields are missing
        }

        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'student_id' => $studentId,
                'section' => $section,
                'role' => 'student',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
            ]
        );

        // Enroll in classroom if classroomId is provided
        if ($this->classroomId && $user->role === 'student') {
            $user->enrolledClassrooms()->syncWithoutDetaching([$this->classroomId]);
        }

        return $user;
    }
}

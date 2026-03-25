<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClassroomStudent extends Model
{
    protected $fillable = [
        'classroom_id',
        'student_id',
    ];

    public function classroom()
    {
        return $this->belongsTo(Classroom::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}

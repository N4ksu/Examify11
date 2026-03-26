<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentAnswer extends Model
{
    protected $fillable = [
        'attempt_id',
        'question_id',
        'option_id',
        'text_response',
        'is_correct',
        'teacher_override',
    ];

    public function attempt()
    {
        return $this->belongsTo(StudentAttempt::class, 'attempt_id');
    }

    public function question()
    {
        return $this->belongsTo(Question::class);
    }

    public function option()
    {
        return $this->belongsTo(Option::class);
    }
}

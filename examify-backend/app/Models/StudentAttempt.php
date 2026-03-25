<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Factories\HasFactory;

class StudentAttempt extends Model
{
    use HasFactory;

    protected $fillable = [
        'assessment_id',
        'student_id',
        'status',
        'violation_count',
        'score',
        'started_at',
        'submitted_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'submitted_at' => 'datetime',
    ];

    public function assessment()
    {
        return $this->belongsTo(Assessment::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function answers()
    {
        return $this->hasMany(StudentAnswer::class, 'attempt_id');
    }

    public function proctoringLogs()
    {
        return $this->hasMany(ProctoringLog::class, 'attempt_id');
    }

    public function scopeFinished($query)
    {
        return $query->whereIn('status', ['submitted', 'auto_submitted']);
    }
}

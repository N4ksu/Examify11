<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

use Illuminate\Database\Eloquent\Factories\HasFactory;

class Assessment extends Model
{
    use HasFactory;

    protected $fillable = [
        'classroom_id',
        'title',
        'description',
        'type',
        'time_limit_minutes',
        'is_published',
        'max_violations',
        'warn_at_violations',
        'weight',
        'course_outcome_id',
        'show_score',
    ];

    protected $casts = [
        'is_published' => 'boolean',
        'show_score' => 'boolean',
    ];

    public function teacher()
    {
        return $this->classroom->teacher();
    }

    public function courseOutcome()
    {
        return $this->belongsTo(CourseOutcome::class);
    }

    public function classroom()
    {
        return $this->belongsTo(Classroom::class);
    }

    public function questions()
    {
        return $this->hasMany(Question::class);
    }

    public function attempts()
    {
        return $this->hasMany(StudentAttempt::class);
    }

    public function retakeRequests()
    {
        return $this->hasMany(RetakeRequest::class);
    }

    public function consents()
    {
        return $this->hasMany(ExamConsent::class);
    }
}

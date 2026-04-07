<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Question extends Model
{
    use HasFactory;

    protected $fillable = [
        'assessment_id',
        'type',
        'body',
        'points',
        'order',
        'course_outcome_id',
        'scoring_method',
    ];

    public function assessment()
    {
        return $this->belongsTo(Assessment::class);
    }

    public function courseOutcome()
    {
        return $this->belongsTo(CourseOutcome::class);
    }

    public function options()
    {
        return $this->hasMany(Option::class);
    }
}

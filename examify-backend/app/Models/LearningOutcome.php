<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LearningOutcome extends Model
{
    use HasFactory;

    protected $fillable = [
        'classroom_id',
        'code',
        'title',
        'description',
    ];

    public function classroom()
    {
        return $this->belongsTo(Classroom::class);
    }

    public function assessments()
    {
        return $this->belongsToMany(Assessment::class, 'assessment_outcome')
            ->withPivot('weight_within_assessment')
            ->withTimestamps();
    }
}


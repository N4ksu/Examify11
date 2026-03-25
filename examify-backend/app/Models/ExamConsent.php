<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ExamConsent extends Model
{
    protected $fillable = [
        'assessment_id',
        'student_id',
        'ip_address',
        'consented_at',
    ];

    protected $casts = [
        'consented_at' => 'datetime',
    ];

    public function assessment()
    {
        return $this->belongsTo(Assessment::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}

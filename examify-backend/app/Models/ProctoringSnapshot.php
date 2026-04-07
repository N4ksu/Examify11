<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProctoringSnapshot extends Model
{
    protected $fillable = [
        'attempt_id',
        'image_path',
        'captured_at',
    ];

    protected $casts = [
        'captured_at' => 'datetime',
    ];

    public function attempt()
    {
        return $this->belongsTo(StudentAttempt::class, 'attempt_id');
    }
}

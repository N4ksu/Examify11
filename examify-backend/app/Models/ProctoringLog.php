<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProctoringLog extends Model
{
    protected $fillable = [
        'attempt_id',
        'event_type',
        'platform',
        'device_info',
        'ip_address',
        'violation_number',
    ];

    public function attempt()
    {
        return $this->belongsTo(StudentAttempt::class, 'attempt_id');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RetakeRequest extends Model
{
    protected $fillable = ['assessment_id', 'student_id', 'reason', 'status', 'approved_at', 'approved_by'];

    protected $casts = [
        'requested_at' => 'datetime',
        'approved_at' => 'datetime',
    ];

    public function assessment()
    {
        return $this->belongsTo(Assessment::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}

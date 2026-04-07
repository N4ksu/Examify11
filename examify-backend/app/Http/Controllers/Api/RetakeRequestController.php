<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Assessment;
use App\Models\RetakeRequest;
use App\Models\StudentAttempt;

class RetakeRequestController extends Controller
{
    // Student submits a retake request
    public function store(Request $request, Assessment $assessment)
    {
        $user = $request->user();
        if ($user->role !== 'student')
            abort(403);
            
        // Check if student has submitted an attempt
        $hasAttempt = StudentAttempt::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->finished()
            ->exists();

        if (!$hasAttempt) {
            return response()->json(['message' => 'You must have taken the exam to request a retake.'], 400);
        }

        // Existing check for pending/approved
        $existing = RetakeRequest::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->whereIn('status', ['pending', 'approved'])
            ->latest()
            ->first();

        if ($existing) {
            $msg = $existing->status === 'pending'
                ? 'You already have a pending request.'
                : 'Your request has already been approved. You can now retake the exam.';
            return response()->json(['message' => $msg], 409);
        }

        $request->validate(['reason' => 'required|string|max:1000']);

        $retakeRequest = RetakeRequest::create([
            'assessment_id' => $assessment->id,
            'student_id' => $user->id,
            'reason' => $request->reason,
            'requested_at' => now(),
        ]);

        return response()->json($retakeRequest, 201);
    }

    // Teacher gets all pending requests for their classes
    public function teacherIndex(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'teacher')
            abort(403);

        $requests = RetakeRequest::with(['assessment.classroom', 'student'])
            ->whereHas('assessment', function ($q) use ($user) {
            $q->whereHas('classroom', function ($q2) use ($user) {
                    $q2->where('teacher_id', $user->id);
                }
                );
            })
            ->where('status', 'pending')
            ->orderBy('requested_at', 'asc')
            ->get();

        return response()->json($requests);
    }

    // Approve a request
    public function approve(Request $request, $id)
    {
        $retakeRequest = RetakeRequest::with('assessment')->findOrFail($id);
        $user = $request->user();
        if ($user->role !== 'teacher' || $retakeRequest->assessment->classroom->teacher_id !== $user->id) {
            abort(403);
        }

        $retakeRequest->update([
            'status' => 'approved',
            'approved_by' => $user->id,
            'approved_at' => now(),
        ]);

        return response()->json(['message' => 'Request approved. Student can now retake.']);
    }

    // Deny a request
    public function deny(Request $request, $id)
    {
        $retakeRequest = RetakeRequest::with('assessment')->findOrFail($id);
        $user = $request->user();
        if ($user->role !== 'teacher' || $retakeRequest->assessment->classroom->teacher_id !== $user->id) {
            abort(403);
        }

        $retakeRequest->update(['status' => 'denied']);

        return response()->json(['message' => 'Request denied.']);
    }

    // Student gets their current request status for an assessment
    public function myRequest(Request $request, Assessment $assessment)
    {
        $user = $request->user();
        $req = RetakeRequest::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->latest()
            ->first();

        return response()->json($req);
    }

    // Student gets their used retake count for an assessment
    public function usedRetakes(Request $request, Assessment $assessment)
    {
        $user = $request->user();
        $count = RetakeRequest::where('assessment_id', $assessment->id)
            ->where('student_id', $user->id)
            ->where('status', 'used')
            ->count();

        return response()->json(['used' => $count]);
    }
}

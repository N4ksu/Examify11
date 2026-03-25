<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Classroom;
use App\Models\CourseOutcome;

class CourseOutcomeController extends Controller
{
    public function index(Request $request, $classroomId)
    {
        $classroom = Classroom::findOrFail($classroomId);
        
        $user = $request->user();
        if ($user->role === 'teacher' && $classroom->teacher_id !== $user->id) {
            abort(403);
        }

        $outcomes = $classroom->courseOutcomes()->get();
        return response()->json($outcomes, 200);
    }

    public function store(Request $request, $classroomId)
    {
        $classroom = Classroom::where('id', $classroomId)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'code' => 'required|string|max:50',
            'description' => 'required|string|max:255',
        ]);

        $outcome = $classroom->courseOutcomes()->create($validated);
        
        return response()->json($outcome, 201);
    }

    public function update(Request $request, $id)
    {
        $outcome = CourseOutcome::findOrFail($id);
        
        if ($outcome->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $validated = $request->validate([
            'code' => 'sometimes|required|string|max:50',
            'description' => 'sometimes|required|string|max:255',
        ]);

        $outcome->update($validated);

        return response()->json($outcome, 200);
    }

    public function destroy(Request $request, $id)
    {
        $outcome = CourseOutcome::findOrFail($id);
        
        if ($outcome->classroom->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $outcome->delete();

        return response()->json(['message' => 'Course Outcome deleted successfully'], 200);
    }
}

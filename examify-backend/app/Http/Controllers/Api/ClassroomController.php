<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use Illuminate\Support\Str;

class ClassroomController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'teacher') {
            $classrooms = $request->user()->classrooms()->withCount('students')->get();
        } else {
            $classrooms = $request->user()->enrolledClassrooms()->with('teacher:id,name,email')->get();
        }

        return response()->json($classrooms, 200);
    }

    public function show(Request $request, $id)
    {
        $classroom = Classroom::with('teacher:id,name,email,role')->findOrFail($id);
        $user = $request->user();

        // Authorization: Teacher of the class or Enrolled student
        $isTeacher = $classroom->teacher_id === $user->id;
        $isStudent = $classroom->students()->where('users.id', $user->id)->exists();

        if (!$isTeacher && !$isStudent) {
            abort(403);
        }

        return response()->json($classroom, 200);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $joinCode = strtoupper(Str::random(6));
        while (Classroom::where('join_code', $joinCode)->exists()) {
            $joinCode = strtoupper(Str::random(6));
        }

        $classroom = $request->user()->classrooms()->create([
            'name' => $validated['name'],
            'description' => $validated['description'],
            'join_code' => $joinCode,
        ]);

        return response()->json(['classroom' => $classroom], 201);
    }

    public function join(Request $request, $id)
    {
        $validated = $request->validate([
            'join_code' => 'required|string|size:6',
        ]);

        $classroom = Classroom::findOrFail($id);

        if ($classroom->join_code !== strtoupper($validated['join_code'])) {
            return response()->json(['message' => 'Invalid join code'], 400);
        }

        if ($classroom->students()->where('users.id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'Already joined'], 409);
        }

        $classroom->students()->attach($request->user()->id);

        return response()->json(['message' => 'Joined successfully'], 200);
    }

    public function joinByCode(Request $request)
    {
        $validated = $request->validate([
            'join_code' => 'required|string|size:6',
        ]);

        $classroom = Classroom::where('join_code', strtoupper($validated['join_code']))->first();

        if (!$classroom) {
            return response()->json(['message' => 'Invalid join code'], 404);
        }

        if ($classroom->students()->where('users.id', $request->user()->id)->exists()) {
            $classroom->load('teacher:id,name,email');
            return response()->json(['message' => 'Already joined', 'classroom' => $classroom], 200);
        }

        $classroom->students()->attach($request->user()->id);

        $classroom->load('teacher:id,name,email');

        return response()->json(['message' => 'Joined successfully', 'classroom' => $classroom], 200);
    }

    public function students(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);
        $user = $request->user();

        // Authorization: Teacher of the class or Enrolled student
        $isTeacher = $classroom->teacher_id === $user->id;
        $isStudent = $classroom->students()->where('users.id', $user->id)->exists();

        if (!$isTeacher && !$isStudent) {
            abort(403);
        }

        return response()->json($classroom->students()->select('users.id', 'users.name', 'users.email', 'users.role', 'users.student_id', 'users.section')->get(), 200);
    }


    public function update(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $classroom->update($validated);

        return response()->json($classroom, 200);
    }

    public function destroy(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();
        $classroom->delete();

    }
}

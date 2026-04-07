<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use App\Models\Announcement;

class AnnouncementController extends Controller
{
    public function index(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);

        // Authorization logic check
        $user = $request->user();
        if ($user->role === 'teacher') {
            if ($classroom->teacher_id !== $user->id)
                abort(403);
        } else {
            if (!$classroom->students()->where('users.id', $user->id)->exists())
                abort(403);
        }

        $announcements = $classroom->announcements()->with('teacher:id,name')->latest()->get();

        return response()->json($announcements, 200);
    }

    public function store(Request $request, $id)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'body' => 'required|string',
        ]);

        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $announcement = $classroom->announcements()->create([
            'teacher_id' => $request->user()->id,
            'title' => $validated['title'],
            'body' => $validated['body'],
        ]);

        return response()->json($announcement, 201);
    }

    public function update(Request $request, $id)
    {
        $announcement = Announcement::findOrFail($id);

        if ($announcement->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'body' => 'sometimes|required|string',
        ]);

        $announcement->update($validated);

        return response()->json($announcement, 200);
    }

    public function destroy(Request $request, $id)
    {
        $announcement = Announcement::findOrFail($id);

        if ($announcement->teacher_id !== $request->user()->id) {
            abort(403);
        }

        $announcement->delete();

        return response()->json(['message' => 'Announcement deleted'], 200);
    }
}

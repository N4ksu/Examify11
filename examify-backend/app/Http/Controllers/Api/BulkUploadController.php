<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Imports\StudentImport;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class BulkUploadController extends Controller
{
    public function upload(Request $request)
    {
        $validated = $request->validate([
            'file' => 'required|mimes:csv,xlsx,xls,txt',
            'classroom_id' => 'required|exists:classrooms,id',
        ]);

        try {
            \Maatwebsite\Excel\Facades\Excel::import(new StudentImport($validated['classroom_id']), $request->file('file'));
            return response()->json(['message' => 'Students imported and enrolled successfully.']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Error importing students: ' . $e->getMessage()], 422);
        }
    }
}

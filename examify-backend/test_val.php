<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$request = Illuminate\Http\Request::create('/api/test', 'POST', [
    'title' => 'Test',
    'type' => 'exam',
    'time_limit_minutes' => 60,
    'is_published' => true,
    'questions' => []
]);

$validator = Illuminate\Support\Facades\Validator::make($request->all(), [
    'title' => 'required|string|max:255',
    'description' => 'nullable|string',
    'type' => 'required|in:exam,quiz,activity',
    'time_limit_minutes' => 'nullable|integer',
    'is_published' => 'required|boolean',
    'max_violations' => 'sometimes|integer',
    'warn_at_violations' => 'sometimes|integer',
    'questions' => 'required|array',
    'questions.*.body' => 'required|string',
    'questions.*.type' => 'sometimes|string',
    'questions.*.points' => 'sometimes|integer',
    'questions.*.options' => 'required|array|min:2',
    'questions.*.options.*.body' => 'required|string',
    'questions.*.options.*.is_correct' => 'required|boolean',
]);

if ($validator->fails()) {
    print_r($validator->errors()->toArray());
} else {
    echo "Validation Passed!\n";
}

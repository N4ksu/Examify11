<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AssessmentTemplateController extends Controller
{
    /**
     * Return a small library of built-in templates.
     */
    public function index()
    {
        $templates = [
            [
                'id' => 'gen_knowledge',
                'title' => 'General Knowledge Quiz',
                'description' => 'A basic quiz covering general topics like geography and science.',
                'type' => 'quiz',
                'time_limit_minutes' => 15,
                'weight' => 20,
                'questions' => [
                    [
                        'body' => 'What is the capital of France?',
                        'type' => 'multiple_choice',
                        'points' => 10,
                        'options' => [
                            ['body' => 'Paris', 'is_correct' => true],
                            ['body' => 'London', 'is_correct' => false],
                            ['body' => 'Berlin', 'is_correct' => false],
                        ]
                    ],
                    [
                        'body' => 'Which planet is known as the Red Planet?',
                        'type' => 'multiple_choice',
                        'points' => 10,
                        'options' => [
                            ['body' => 'Mars', 'is_correct' => true],
                            ['body' => 'Venus', 'is_correct' => false],
                            ['body' => 'Jupiter', 'is_correct' => false],
                        ]
                    ]
                ]
            ],
            [
                'id' => 'science_midterm',
                'title' => 'Science Midterm Exam',
                'description' => 'Comprehensive midterm covering introductory biological concepts.',
                'type' => 'exam',
                'time_limit_minutes' => 60,
                'weight' => 40,
                'questions' => [
                    [
                        'body' => 'What is the powerhouse of the cell?',
                        'type' => 'multiple_choice',
                        'points' => 5,
                        'options' => [
                            ['body' => 'Mitochondria', 'is_correct' => true],
                            ['body' => 'Nucleus', 'is_correct' => false],
                            ['body' => 'Ribosome', 'is_correct' => false],
                        ]
                    ],
                    [
                        'body' => 'What is the chemical symbol for Water?',
                        'type' => 'multiple_choice',
                        'points' => 5,
                        'options' => [
                            ['body' => 'H2O', 'is_correct' => true],
                            ['body' => 'CO2', 'is_correct' => false],
                            ['body' => 'O2', 'is_correct' => false],
                        ]
                    ]
                ]
            ]
        ];

        return response()->json($templates);
    }

    /**
     * Parse an uploaded plain-text file containing multiple choice questions
     * into the same structure as an assessment template.
     *
     * Expected format (blocks separated by a blank line):
     *
     * What is the powerhouse of the cell?
     * * A) Mitochondria
     *   B) Nucleus
     *   C) Ribosome
     *
     * What is the chemical symbol for Water?
     *   A) CO2
     * * B) H2O
     *   C) O2
     *
     * Lines starting with '*' are treated as correct options. If none of the
     * options in a block are marked correct, the first option is assumed to be correct.
     */
    public function parseUpload(Request $request)
    {
        $validated = $request->validate([
            'file' => 'required|file|mimes:txt,pdf,doc,docx',
            'title' => 'sometimes|string|max:255',
            'type' => 'sometimes|string|in:exam,quiz,activity',
            'time_limit_minutes' => 'sometimes|integer|min:1',
        ]);

        $file = $request->file('file');
        $content = file_get_contents($file->getRealPath());

        $apiKey = env('GEMINI_API_KEY');
        if (empty($apiKey)) {
            return response()->json(['message' => 'Gemini API key is not configured on the server. Please add GEMINI_API_KEY to your .env file.'], 500);
        }

        $extension = strtolower($file->getClientOriginalExtension());
        $filePath = $file->getRealPath();
        $content = '';

        try {
            if ($extension === 'docx') {
                $content = $this->extractDocxText($filePath);
            } elseif ($extension === 'pdf') {
                $content = $this->extractPdfText($filePath);
            } else {
                $content = file_get_contents($filePath);
            }
        } catch (\Exception $e) {
            return response()->json(['message' => 'Failed to read file content: ' . $e->getMessage()], 422);
        }

        // Limit content size to avoid hitting prompt limits or massive bills
        $content = substr($content, 0, 100000);

        $prompt = "You are an assistant that processes unstructured text containing multiple-choice questions into a structured JSON array.
Extract all multiple-choice questions from the provided text.
Identify the question body, the options, and which option is correct.
Ensure there are at least two options for each question.

The text may contain section headers such as \"Section A: General Outcome\" or \"Section B: Main Topic Outcome\".
For each question, determine which section it belongs to, and set the \"suggested_course_outcome\" field:
- If the question belongs to a section about general knowledge (applicable in many subjects), use exactly: \"General Topic Outcome\"
- If the question belongs to a section about a specific specialized field or topic, use exactly: \"Main Topic Outcome\"
If there are no section headers, analyze each question individually and classify it the same way.

Return ONLY valid JSON as a root object with a \"questions\" array. No markdown, no triple backticks.

Format Example:
{
  \"questions\": [
    {
      \"body\": \"Question text here\",
      \"type\": \"multiple_choice\",
      \"points\": 1,
      \"suggested_course_outcome\": \"General Topic Outcome\",
      \"options\": [
        {\"body\": \"Option 1 text\", \"is_correct\": true},
        {\"body\": \"Option 2 text\", \"is_correct\": false}
      ]
    },
    {
      \"body\": \"Another question\",
      \"type\": \"multiple_choice\",
      \"points\": 1,
      \"suggested_course_outcome\": \"Main Topic Outcome\",
      \"options\": [
        {\"body\": \"Option A\", \"is_correct\": false},
        {\"body\": \"Option B\", \"is_correct\": true}
      ]
    }
  ]
}

Text to parse:
" . $content;

        $response = \Illuminate\Support\Facades\Http::withoutVerifying()->post('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=' . $apiKey, [
            'contents' => [
                ['parts' => [['text' => $prompt]]]
            ],
            'generationConfig' => [
                'response_mime_type' => 'application/json',
            ]
        ]);

        if ($response->failed()) {
            return response()->json(['message' => 'Failed to parse file with AI. Error: ' . $response->body()], 500);
        }

        $data = $response->json();
        $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';

        $parsed = json_decode($text, true);

        if (!is_array($parsed) || empty($parsed['questions'])) {
            return response()->json(['message' => 'AI could not detect any valid multiple choice questions in the file.'], 422);
        }

        $questions = $parsed['questions'];

        $result = [
            'id' => 'uploaded_' . uniqid(),
            'title' => $validated['title'] ?? pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME),
            'description' => 'Imported via AI parsing',
            'type' => $validated['type'] ?? 'exam',
            'time_limit_minutes' => (int) ($validated['time_limit_minutes'] ?? 60),
            'weight' => 0,
            'questions' => $questions,
        ];

        return response()->json($result);
    }

    private function extractDocxText($filePath)
    {
        $text = '';
        $zip = new \ZipArchive;
        if ($zip->open($filePath) === true) {
            $content = $zip->getFromName('word/document.xml');
            $zip->close();
            if ($content !== false) {
                // Remove XML tags, replace paragraphs with newlines
                $content = str_replace('</w:p>', "\n", $content);
                $text = strip_tags($content);
            }
        }
        return $text;
    }

    private function extractPdfText($filePath)
    {
        // For local development on Windows, trying to parse raw PDF in PHP without libraries is very unreliable because of compression/streams.
        // We will do a basic string extraction of uncompressed text, but if the PDF is compressed (most are), this will miss text.
        // A robust solution requires system binaries (like pdftotext) or an API. 
        // For this demo, we'll extract plain text where possible.
        $content = file_get_contents($filePath);
        $text = preg_replace('/[^a-zA-Z0-9\s.-]/', '', $content);
        return "Note: PDF parsing is experimental without native binaries. Extracted: \n" . $text;
    }
}

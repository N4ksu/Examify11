<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureValidExamSession
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $attemptId = $request->route('id');
        if ($attemptId) {
            $attempt = \App\Models\StudentAttempt::find($attemptId);
            
            if ($attempt && $attempt->status === 'in_progress') {
                $matchesIp = $attempt->ip_address === $request->ip();
                $matchesUa = $attempt->user_agent === $request->userAgent();

                // If strict UA mismatch or IP mismatch occurs (can be relaxed for IP if desired)
                if (!$matchesUa || !$matchesIp) {
                    $attempt->is_flagged_for_hijacking = true;
                    $attempt->save();

                    return response()->json([
                        'message' => 'Session Hijacking Detected. Your session has been locked.'
                    ], 403);
                }
            }
        }

        return $next($request);
    }
}

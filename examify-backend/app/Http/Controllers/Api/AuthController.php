<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => 'required|in:teacher,student',
        ]);

        $uniqueId = null;
        if ($validated['role'] === 'student') {
            $idPrefix = 'STU-';
            $uniqueId = $idPrefix . strtoupper(Str::random(4)) . rand(1000, 9999);
            while (User::where('student_id', $uniqueId)->exists()) {
                $uniqueId = $idPrefix . strtoupper(Str::random(4)) . rand(1000, 9999);
            }
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'student_id' => $uniqueId,
        ]);

        $expiresAt = now()->addMinutes(60);
        $token = $user->createToken('auth_token', ['*'], $expiresAt);
        $refreshToken = Str::random(64);

        $token->accessToken->refresh_token = $refreshToken;
        $token->accessToken->save();

        return response()->json([
            'user' => $user,
            'access_token' => $token->plainTextToken,
            'refresh_token' => $refreshToken,
            'expires_at' => $expiresAt->toIso8601String(),
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt($validated)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = User::where('email', $validated['email'])->firstOrFail();

        // Revoke all previous tokens
        $user->tokens()->delete();

        $expiresAt = now()->addMinutes(60);
        $token = $user->createToken('auth_token', ['*'], $expiresAt);
        $refreshToken = Str::random(64);

        $token->accessToken->refresh_token = $refreshToken;
        $token->accessToken->save();

        return response()->json([
            'user' => $user,
            'access_token' => $token->plainTextToken,
            'refresh_token' => $refreshToken,
            'expires_at' => $expiresAt->toIso8601String(),
        ], 200);
    }

    public function refresh(Request $request)
    {
        $validated = $request->validate([
            'refresh_token' => 'required|string',
        ]);

        $accessToken = DB::table('personal_access_tokens')
            ->where('refresh_token', $validated['refresh_token'])
            ->first();

        if (!$accessToken) {
            return response()->json(['message' => 'Invalid or expired refresh token'], 401);
        }

        $user = User::find($accessToken->tokenable_id);

        // Revoke old token
        $user->tokens()->where('id', $accessToken->id)->delete();

        $expiresAt = now()->addMinutes(60);
        $newToken = $user->createToken('auth_token', ['*'], $expiresAt);
        $newRefreshToken = Str::random(64);

        $newToken->accessToken->refresh_token = $newRefreshToken;
        $newToken->accessToken->save();

        return response()->json([
            'access_token' => $newToken->plainTextToken,
            'refresh_token' => $newRefreshToken,
            'expires_at' => $expiresAt->toIso8601String(),
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully'], 200);
    }
}

<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'John Teacher',
            'email' => 'teacher@example.com',
            'password' => 'password123',
            'role' => 'teacher',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure(['user', 'access_token', 'refresh_token', 'expires_at']);

        $this->assertDatabaseHas('users', ['email' => 'teacher@example.com']);
    }

    public function test_user_can_login()
    {
        $user = User::factory()->create([
            'email' => 'student@example.com',
            'password' => \Illuminate\Support\Facades\Hash::make('password123'),
            'role' => 'student',
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'student@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['user', 'access_token', 'refresh_token', 'expires_at']);
    }

    public function test_user_can_refresh_token()
    {
        $user = User::factory()->create(['role' => 'student']);

        $loginRes = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'password', // Default factory password is 'password'
        ]);

        $refreshToken = $loginRes['refresh_token'];

        $response = $this->postJson('/api/token/refresh', [
            'refresh_token' => $refreshToken,
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['access_token', 'refresh_token', 'expires_at']);
    }

    public function test_user_can_logout()
    {
        $user = User::factory()->create(['role' => 'teacher']);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/logout');

        $response->assertStatus(200);
        $this->assertEmpty($user->tokens);
    }
}

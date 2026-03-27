<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('proctoring_snapshots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attempt_id')->constrained('student_attempts')->onDelete('cascade');
            $table->string('image_path');
            $table->timestamp('captured_at');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('proctoring_snapshots');
    }
};

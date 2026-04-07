<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('proctoring_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('attempt_id')->constrained('student_attempts')->cascadeOnDelete();
            $table->enum('event_type', ['alt_tab', 'app_background', 'window_blur', 'fullscreen_exit']);
            $table->string('platform');
            $table->string('device_info');
            $table->string('ip_address');
            $table->integer('violation_number');
            $table->timestamp('timestamp');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('proctoring_logs');
    }
};

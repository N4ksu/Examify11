<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('proctoring_logs', function (Blueprint $table) {
            if (Schema::hasColumn('proctoring_logs', 'timestamp')) {
                $table->dropColumn('timestamp');
            }
        });
    }

    public function down(): void
    {
        Schema::table('proctoring_logs', function (Blueprint $table) {
            if (!Schema::hasColumn('proctoring_logs', 'timestamp')) {
                $table->timestamp('timestamp')->nullable();
            }
        });
    }
};

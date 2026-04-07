<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            // Add columns if they don't exist
            if (!Schema::hasColumn('questions', 'type')) {
                $table->string('type')->default('multiple_choice')->after('body');
            }
            if (!Schema::hasColumn('questions', 'points')) {
                $table->integer('points')->default(1)->after('type');
            }
            // 'order' already exists in your migration; if not, uncomment:
            // if (!Schema::hasColumn('questions', 'order')) {
            //     $table->integer('order')->nullable()->after('points');
            // }
        });
    }

    public function down(): void
    {
        Schema::table('questions', function (Blueprint $table) {
            $table->dropColumn(['type', 'points']);
        });
    }
};
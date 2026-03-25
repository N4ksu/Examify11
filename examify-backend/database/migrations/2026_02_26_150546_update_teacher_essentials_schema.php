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
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (!Schema::hasColumn('users', 'student_id')) {
                    $table->string('student_id')->nullable()->unique()->after('id');
                }
                if (!Schema::hasColumn('users', 'section')) {
                    $table->string('section')->nullable()->after('role');
                }
            });
        }

        if (Schema::hasTable('assessments')) {
            Schema::table('assessments', function (Blueprint $table) {
                if (!Schema::hasColumn('assessments', 'weight')) {
                    $table->integer('weight')->default(0)->after('type');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['student_id', 'section']);
        });

        Schema::table('assessments', function (Blueprint $table) {
            $table->dropColumn('weight');
        });
    }
};

# Examify Setup & Maintenance Guide

Follow these steps to set up and run Examify on a new computer.

## Prerequisites
- **Node.js** (latest LTS)
- **Flutter SDK**
- **PHP 8.2+** & **Composer**
- **MySQL** (or MariaDB)

---

## 🚀 Initial Setup

### 1. Clone & Core Prep
```bash
git clone <repository-url>
cd Examify
```

### 2. Backend Setup (examify-backend)
```bash
cd examify-backend
composer install
copy .env.example .env
# Update .env with your DB_DATABASE, DB_USERNAME, DB_PASSWORD
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### 3. Frontend Setup (examify_flutter)
```bash
cd ../examify_flutter
flutter pub get
# If you are on Windows
flutter run -d windows
```

---

## 🧹 Database Maintenance Commands

### Clean all data (Refresh Database)
This will delete all users, classrooms, assessments, and results, then re-seed the default data.
```bash
cd examify-backend
php artisan migrate:fresh --seed
```

### Clear Cache & Logs
```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

---

## 🛠️ Troubleshooting

### Windows Build Issues
If the Flutter Windows build fails, try:
```bash
flutter clean
flutter pub get
flutter run -d windows
```

### Backend Connection
Ensure your `.env` file points to `127.0.0.1` or the correct local IP for the API bridge.
In `examify_flutter/lib/core/api/api_client.dart`:
```dart
baseUrl: 'http://127.0.0.1:8000/api'
```

---

## 👨‍💻 Developer Notes
- **Teacher IDs**: Format `TEA-XXXX####` (e.g., TEA-ABCD1234)
- **Student IDs**: Format `STU-XXXX####` (e.g., STU-EFGH5678)
- **Proctoring**: Window management locks are active only on Windows builds.

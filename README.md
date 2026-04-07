# Examify 🎓

Examify is a proctored assessment platform designed to ensure exam integrity. This repository contains both the Laravel backend and the Flutter web/mobile/desktop frontend.

## 🚀 Quick Start (Docker)

The easiest way to run the project on any computer is using **Docker**.

### 1. Prerequisites
- Install **[Docker Desktop](https://www.docker.com/products/docker-desktop/)**.
- Git installed.

### 2. Setup
Clone the repository and navigate into the project:
```bash
git clone https://github.com/N4ksu/Examify.git
cd Examify
```

### 3. Run the Project
Start all services (Database, Backend, and Frontend):
```bash
docker-compose up --build -d
```

### 4. Database Initialization (First Run Only)
Run the following command to set up the database and seed initial demo data:
```bash
docker exec -it examify_backend php artisan migrate --seed
```

### 5. Access the Apps
- **Frontend (Flutter Web)**: [http://localhost:8080](http://localhost:8080)
- **Backend API**: [http://localhost:8000/api](http://localhost:8000/api)

---

## 🛠 Manual Setup (VS Code / Local Windows)

If you are developing or running locally on Windows without Docker, follow these steps.

### 1. Database Setup (XAMPP)
- Open **XAMPP Control Panel** and start **Apache** and **MySQL**.
- Go to [http://localhost/phpmyadmin](http://localhost/phpmyadmin) and create a database named `examify`.

### 2. Backend (Laravel)
Open a terminal in the `examify-backend/` folder:
```bash
# Install dependencies
composer install

# Setup environment
copy .env.example .env

# Configure .env (ensure these match your local DB)
# DB_DATABASE=examify
# DB_USERNAME=root
# DB_PASSWORD=

# Initialize Database
php artisan key:generate
php artisan migrate --seed

# Start Server
php artisan serve
```
*Backend will be running at [http://127.0.0.1:8000](http://127.0.0.1:8000)*

### 3. Frontend (Flutter Windows)
Open a **new second terminal** in the `examify_flutter/` folder:
```bash
# Get dependencies
flutter pub get

# Run the app for Windows
flutter run -d windows
```

### 🎯 VS Code Tips
- **Multi-Terminal**: Open two terminal tabs in VS Code to keep both the Backend and Frontend running simultaneously.
- **Hot Reload**: Press `r` in the Flutter terminal to apply changes instantly without restarting.
- **Hot Restart**: Press `R` in the Flutter terminal to reset the app state.

---

## 🔒 Proctoring Features
- **Full-Screen Enforcement**: Works on Web, Desktop, and Mobile.
- **Always on Top**: Supported on Windows.
- **Violation Logging**: Detects tab switching, window blurring, and app backgrounding.

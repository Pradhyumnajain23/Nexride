# NexRide – AI-Powered Public Transport System

NexRide is a public transport project for Bengaluru. It brings together a Flutter rider app, a Python API, and an admin dashboard to support route search, bus information, and ticketing.

---

## 🔍 Problem Statement

Public transport riders need a convenient way to find routes, check bus information, and manage tickets. NexRide brings these tasks together in one mobile app backed by a central API and an admin interface.

---

## 🚀 Features

- Rider registration, login, and OTP authentication
- Search for routes between stops
- View bus and estimated arrival information
- Ticket booking and ticket details
- Map and location screens
- AI-assisted chat
- Admin dashboard for transport data management

---

## 🧠 Tech Stack

**Mobile App**
- Flutter
- Dart
- Provider
- GoRouter
- Dio

**Backend**
- Python
- FastAPI
- SQLAlchemy
- MySQL

**Admin Dashboard**
- HTML
- CSS
- JavaScript

**Integrations**
- Gemini API for AI-assisted responses
- Gmail SMTP for email and OTP features
- Mapbox for map tiles

---

## 🏗️ System Architecture

1. Riders use the Flutter app to access transport features.
2. The app sends requests to the FastAPI backend.
3. The backend handles authentication, routes, buses, stops, tickets, chat, and admin requests.
4. SQLAlchemy connects the backend to the MySQL database.
5. API responses are displayed in the rider app or admin dashboard.

---

## 🧪 How It Works

- Riders sign in and search for routes or bus information.
- The app communicates with the backend API over HTTP.
- The backend reads or updates transport data in MySQL.
- Chat and estimated arrival features provide additional travel assistance.

---

## 📂 Project Structure

```text
Nexride/
├── admin_dashboard/   # Browser-based admin interface
├── backend/           # FastAPI application and database services
└── nexride_app/       # Flutter rider application
```

---

## ▶️ How to Run

### 1. Clone the repository

```bash
git clone https://github.com/Pradhyumnajain23/Nexride.git
cd Nexride
```

### 2. Start the backend

Create a MySQL database named `nexride`. In the `backend` folder, create a `.env` file with your local database and service settings:

```dotenv
DB_HOST=localhost
DB_PORT=3306
DB_NAME=nexride
DB_USER=root
DB_PASSWORD=your_local_mysql_password

SECRET_KEY=replace_with_a_long_random_value
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

SMTP_EMAIL=
SMTP_PASSWORD=
OTP_EXPIRE_MINUTES=10
GEMINI_API_KEY=
```

Install dependencies and start the API:

```bash
cd backend
python -m venv .venv
```

On Windows:

```cmd
.venv\Scripts\activate
```

Then:

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

The API runs at `http://localhost:8000`. API documentation is available at `http://localhost:8000/docs`.

### 3. Start the Flutter app

In a second terminal:

```bash
cd nexride_app
flutter pub get
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_PUBLIC_MAPBOX_TOKEN
```

Use a **public** Mapbox token (`pk…`) for the client app. Update the API base URL in `lib/core/constants/app_constants.dart` if testing from a physical device.

### 4. Open the admin dashboard

Open `admin_dashboard/index.html` in a browser and make sure its API URL points to the running backend.

---

## 🎯 Use Cases

NexRide is designed for:

- Public transport riders looking up routes and bus information
- Riders managing tickets through a mobile app
- Administrators managing transport data through a dashboard

---

## 👨‍💻 Author

**Pradyumna J Jain**  
GitHub: [Pradhyumnajain23](https://github.com/Pradhyumnajain23)

---

## 🔐 Security Note

Keep database passwords, JWT signing keys, SMTP passwords, and Gemini API keys out of source code and GitHub. Store backend credentials in `backend/.env`. Before deploying, replace development settings such as local API URLs and wildcard CORS with production values.

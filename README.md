\# NexRide



NexRide is a public transport project for Bengaluru. It includes a Flutter rider app, a FastAPI backend, and a browser-based admin dashboard.



\## Project components



\- \*\*Rider app:\*\* Sign-in, route search, bus information, tickets, maps, chat, and profile screens.

\- \*\*Backend API:\*\* Authentication, bus, route, stop, ticket, chat, and admin services.

\- \*\*Admin dashboard:\*\* HTML, CSS, and JavaScript interface.



\## Technology



\- Flutter and Dart

\- Python, FastAPI, SQLAlchemy, and MySQL

\- HTML, CSS, and JavaScript



\## Requirements



\- Flutter SDK (Dart SDK constraint: `>=3.0.0 <4.0.0`)

\- Python 3.10 or newer

\- MySQL



\## Run the backend locally



Create a MySQL database named `nexride`. Then, from the project folder:



```cmd

cd backend

python -m venv .venv

.venv\\Scripts\\activate

pip install -r requirements.txt

```



Create `backend\\.env` with your local settings:



```dotenv

DB\_HOST=localhost

DB\_PORT=3306

DB\_NAME=nexride

DB\_USER=root

DB\_PASSWORD=your\_local\_mysql\_password



SECRET\_KEY=replace\_with\_a\_long\_random\_value

ALGORITHM=HS256

ACCESS\_TOKEN\_EXPIRE\_MINUTES=60



SMTP\_EMAIL=

SMTP\_PASSWORD=

OTP\_EXPIRE\_MINUTES=10

GEMINI\_API\_KEY=

```



Start the API from the `backend` folder:



```cmd

uvicorn main:app --reload

```



The API runs at `http://localhost:8000`. Interactive API documentation is at `http://localhost:8000/docs`. The backend creates its database tables at startup.



\## Run the Flutter app



Open a second terminal in the project folder:



```cmd

cd nexride\_app

flutter pub get

flutter run --dart-define=MAPBOX\_ACCESS\_TOKEN=YOUR\_PUBLIC\_MAPBOX\_TOKEN

```



Use a \*\*public\*\* Mapbox token (`pk…`) for the client app. Keep secret credentials such as database passwords, JWT signing keys, SMTP passwords, and Gemini API keys out of Flutter code and the public repository.



The app's API base URL is configured in `lib/core/constants/app\_constants.dart`. For a physical phone, set it to an address reachable from that device.



\## Admin dashboard



Open `admin\_dashboard/index.html` in a browser. The dashboard requires the backend API to be running and may need its API URL configured for your environment.



\## Repository layout



```text

admin\_dashboard/   Browser-based admin interface

backend/           FastAPI application and requirements

nexride\_app/       Flutter application

```



\## Deployment note



Before deploying, replace development settings such as the default JWT secret, wildcard CORS policy, and local API URLs with production values. Never commit real credentials; `backend\\.env` is ignored by Git.


# BuildTrack Pro

A Flutter web + Node.js/PostgreSQL construction project management system.

## Modules
- Project tracking
- Budget management
- Worker attendance
- Material management
- Progress photos
- Client reporting
- Administrator login
- Staff account creation and login
- Role-based access control

## 1. Database
Create a PostgreSQL database named `buildtrack`, then run:

```powershell
psql -U postgres -d buildtrack -f backend/schema.sql
```

## 2. Backend
```powershell
cd backend
copy .env.example .env
npm install
npm run seed
npm run dev
```

API health check: `http://localhost:3000/api/health`

Default administrator:
- Email: `admin@buildtrack.com`
- Password: `Admin123!`

Change this password before production use.

## 3. Flutter web frontend
```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api
```

Production web build:
```powershell
flutter build web --release --dart-define=API_URL=https://YOUR-API-DOMAIN/api
```

The generated site will be in `frontend/build/web`.

## Production recommendations
Use managed PostgreSQL, HTTPS, a strong JWT secret, server-side authorization, object storage for progress photos, password-reset email flows, audit logs, database backups, and environment-specific CORS rules.

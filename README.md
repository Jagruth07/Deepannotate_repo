# DeepAnnotate

DeepAnnotate is a full-stack, unified mobile application prototype designed for efficiently collecting diverse data types (audio, images, and video) from distributed users. It features an integrated Admin Dashboard and User Interface, completely removing the need for a separate website.

## Core Features

*   **Unified Access**: A single Flutter app houses both the Admin Dashboard and the Data Collector (User) interfaces, managed via a simplistic local routing guard.
*   **Real-Time Live Feed**: The Admin Dashboard receives instant updates via WebSockets (`Socket.io`) when a user uploads a new file, providing an uninterrupted live feed of submissions.
*   **AWS S3 Storage**: All media submissions are uploaded directly from the mobile app to an AWS S3 bucket using pre-signed HTTP PUT URLs, keeping cloud credentials securely isolated on the backend.
*   **Theme Management**: A global, state-managed dark and light mode toggle responsive across all screens.
*   **Offline Experience**: Users local completion lists are tracked to prevent duplicate submissions and distinguish between "Available" and "Completed" tasks.

## Technology Stack

The project transitioned from Firebase to an industry-standard, scalable architecture:

*   **Frontend**: Flutter (Dart)
*   **Backend Server**: Node.js with Express.js
*   **Real-time Communication**: Socket.io
*   **Database**: PostgreSQL
*   **Cloud Storage**: AWS S3 (via `@aws-sdk/client-s3`)

## Project Structure
```text
DeepAnnotate/
├── backend/                  # Node.js Express server
│   ├── index.js              # Main server file (API & WebSockets)
│   ├── package.json          # Backend dependencies
│   └── .env                  # Environment variables (AWS, Postgres)
├── mobile_app/               # Flutter native application
│   ├── lib/
│   │   ├── main.dart         # Entry point & ThemeNotifier
│   │   ├── constants.dart    # Backend IP/URL configuration
│   │   ├── screens/          # Login, Admin Dashboard, User Task Lists
│   │   └── services/         # API Service for HTTP and REST calls
│   ├── pubspec.yaml          # Flutter dependencies
│   └── ...
└── README.md
```

## Setup Instructions

### 1. Database Initialization
1.  Ensure you have a running PostgreSQL database (e.g., Supabase Postgres).
2.  Provide the `DATABASE_URL` in the `backend/.env` file.

### 2. AWS S3 Configuration
1.  Create an IAM user with `AmazonS3FullAccess`.
2.  Provide the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, and `AWS_S3_BUCKET` in the `backend/.env` file.

### 3. Run Backend Server
```bash
cd backend
npm install
node index.js
```
*Note: To automatically create the SQL tables for the first time, visit `http://localhost:3000/init-db` in your browser.*

### 4. Run Mobile App
Open `mobile_app/lib/constants.dart` and ensure `backendUrl` points to your active server IP (e.g., `http://10.0.2.2:3000` for Android emulators).
```bash
cd mobile_app
flutter pub get
flutter run
```

* **Admin Access**: Login with ID: `admin`, Password: `admin`
* **User Access**: Login with any other ID and password.
# DeepAnnotate Prototype

DeepAnnotate is an end-to-end data collection system designed for AI training workflows. This prototype demonstrates a complete flow where an administrator creates tasks via a web dashboard, and mobile users fulfill those tasks by capturing and uploading media.

## Project Structure

The repository is organized into three main components:

- **backend**: Node.js and Express server that handles task management and submission logging.
- **admin-dashboard**: React application built with Vite for task creation and real-time monitoring of submissions.
- **mobile_app**: Flutter application for mobile users to browse tasks and upload media.

## Technology Stack

### Mobile Application
- **Flutter**: Used for high-performance, natively compiled mobile applications for iOS and Android from a single codebase.
- **Supabase Storage**: Integrated for scalable, cloud-based media storage without upfront billing requirements.
- **Shared Preferences**: Used for local state persistence to track completed tasks on the device.

### Backend API
- **Node.js & Express**: Provides a lightweight and modular REST API layer.
- **Firebase Admin SDK**: Securely interacts with Firestore for real-time metadata storage.
- **Dotenv**: Manages environment variables and credentials securely.

### Admin Dashboard
- **React**: Modern component-based UI for the administrative interface.
- **Firebase Web SDK**: Utilizes the onSnapshot listener for real-time UI updates when new submissions arrive.
- **Lucide React**: Provides consistent iconography.
- **Vanilla CSS**: Custom styling with CSS Variables for theme consistency and Dark Mode support.

## Getting Started

### 1. Backend Setup
1. Navigate to the `backend` directory.
2. Install dependencies: `npm install`.
3. Add your `serviceAccountKey.json` from Firebase.
4. Start the server: `node index.js`.

### 2. Admin Dashboard Setup
1. Navigate to the `admin-dashboard` directory.
2. Install dependencies: `npm install`.
3. Start the development server: `npm run dev`.

### 3. Mobile App Setup
1. Ensure you have the Flutter SDK installed.
2. Navigate to the `mobile_app` directory.
3. Install dependencies: `flutter pub get`.
4. Run the app: `flutter run`.

## Infrastructure Configuration

### Firestore (Database)
The project uses two primary collections:
- **tasks**: Stores task titles, descriptions, and timestamps.
- **submissions**: Stores references to task IDs and the public URLs of uploaded media.

### Supabase (Storage)
Media files are stored in a public bucket named `submissions`. Ensure that the storage policies are configured to allow anonymous uploads for testing purposes.
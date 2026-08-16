# Pocket Queue

Pocket Queue is an offline-first digital queue manager for clinics, salons, repair shops, restaurants, government counters, and other small service desks. The Flutter application is designed around one operational principle: an operator should be able to start and manage a queue in less than one minute.

## Features

The app includes onboarding, business and counter setup, configurable queue prefixes and numbering, regular/priority/appointment tickets, next-customer calling, recall, finish, skip, pause/resume, destructive-action confirmation, digital display mode, history, queue detail, daily statistics, settings, CSV export through the Android Sharesheet, and local persistence through `shared_preferences`.

## Architecture

The project uses a small offline-first MVVM-inspired structure. `QueueStore` owns the local queue model and operations, persists JSON data through `SharedPreferences`, and notifies the widget tree through `ChangeNotifier`. `MainShell` provides responsive bottom navigation on phones and a navigation rail on wide screens. The presentation layer is split into onboarding, queue, display, history, statistics, detail, and settings screens.

## Requirements

Flutter 3.35 or newer, Dart 3.9 or newer, Android SDK tooling, and Java 17 or newer are recommended. The Android package is `com.pelayanan.pocket_queue`, with Android 8.0+ compatibility inherited from the Flutter toolchain.

## Installation

```bash
git clone https://github.com/pelayanan/pocketqueue.git
cd pocketqueue
flutter pub get
```

## Running the App

```bash
flutter run
```

For browser-based verification:

```bash
flutter run -d web-server --web-port 8080
```

## Building APK

```bash
flutter build apk --debug
```

The debug artifact is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Testing

The repository contains widget and queue-logic tests. Run the full local gate with:

```bash
flutter analyze
flutter test
```

The tests cover onboarding visibility, number generation, priority ordering, call-next transitions, recall, finish, and reset behavior.

## Project Structure

```text
lib/main.dart                         Flutter application, models, store, and screens
android/                               Android host and manifest configuration
test/widget_test.dart                  Widget and queue workflow tests
.github/workflows/android.yml          GitHub Actions analyzer, test, and APK build
docs/index.html                        Offline project documentation
docs/workflow.html                     Workflow and interaction documentation
docs/architecture.html                 Architecture and state documentation
docs/database.html                     Local data model documentation
docs/screenshots.html                  Screenshot gallery
docs/screenshots/                      Final UI screenshot assets
```

## Database and Offline Storage

Queue records and operational settings are stored locally on the device as JSON-backed preferences. The data model tracks ticket type, status, creation, call, start, completion, skip, recall, waiting duration, and service duration. No backend or network connection is required for queue operations.

## Documentation

Open [`docs/index.html`](docs/index.html) for the static documentation website. It works offline and links to workflow, architecture, database, and screenshot pages.

## Screenshots

The screenshot gallery is available at [`docs/screenshots.html`](docs/screenshots.html). The assets represent the final implemented UI, including onboarding, setup, queue operation, ticket creation, serving, display, history, queue detail, statistics, and settings.

## License

This project is provided for personal and internal business use. Add an explicit license before distributing it publicly.

# Auto Scheduler - Employee Appointment Management

A Flutter application for managing employee appointments, route planning, and cost tracking. This application helps businesses efficiently schedule and manage field service appointments.

## Features

- **Employee Management**: Track employee locations and availability in real-time
- **Appointment Scheduling**: Automatically assign appointments to employees based on availability
- **Route Planning**: Generate optimized 7-day route plans for employees
- **Cost Tracking**: Calculate travel costs, time costs, and total expenses
- **Data Visualization**: View cost and distance breakdowns with interactive charts
- **Export Functionality**: Export appointment data to CSV files

## Tech Stack

- **Flutter**: UI framework
- **Firebase Firestore**: Database for storing employees, customers, and appointments
- **GetX**: State management and dependency injection
- **Google Maps**: For location tracking and route visualization
- **FL Chart**: For data visualization

## Project Structure

The project follows a clean architecture approach with the following layers:

- **Domain**: Contains business logic, entities, and use cases
- **Data**: Implements repositories and data sources
- **Presentation**: Contains UI components and view models
- **DI**: Handles dependency injection

## Getting Started

### Prerequisites

- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)
- Firebase account
- Google Maps API key

### Setup

1. **Clone the repository**

```bash
git clone https://github.com/Shyam7219/autoscheduler_assignment.git
cd autoscheduler_assignment
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase Setup**

- Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
- Enable Firestore Database
- Add an Android/iOS app to your Firebase project
- Download the configuration file:
  - For Android: `google-services.json` (place in `android/app/`)
  - For iOS: `GoogleService-Info.plist` (place in `ios/Runner/`)

4. **Google Maps Setup**

- Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
- Add the API key to:
  - For Android: `android/app/src/main/AndroidManifest.xml`
  - For iOS: `ios/Runner/AppDelegate.swift`

5. **Firestore Database Setup**

Create the following collections in your Firestore database:

- **employees**: Contains employee data
  - Fields: `id`, `name`, `latitude`, `longitude`, `isAvailable`
- **customers**: Contains customer data
  - Fields: `id`, `name`, `latitude`, `longitude`, `recurringTimes`
- **appointments**: Contains appointment data
  - Fields: `customerId`, `employeeId`, `time`, `duration`, `status`

6. **Run the application**

```bash
flutter run
```

## Usage

1. **Home Screen**: Navigate between different features of the app
2. **Map Screen**: View employee locations and track them in real-time
3. **Scheduler Screen**: Generate and view appointments
4. **Route Plan Screen**: View 7-day route plans for employees
5. **Summary Screen**: View cost summaries and export data

## Performance Considerations

- The app uses efficient data loading patterns to minimize Firestore reads
- Map markers are optimized for smooth performance
- Background location updates are throttled to save battery


## Contact

Shyam Patil - [shyampatil9723@gmail.com](mailto:shyampatil9723@gmail.com)

Project Link: [https://github.com/Shyam7219/autoscheduler_assignment](https://github.com/Shyam7219/autoscheduler_assignment)
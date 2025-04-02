# Parking App - Admin Panel

## Overview

This Flutter-based Admin Panel application is designed for managing a parking lights control system. The app allows administrators to monitor network modules, manage OTA updates, check BLE and dimming statuses, and handle emergency system operations. It integrates multiple functionalities into a single, easy-to-navigate interface.

## Features

- **Server URL Management**: 
  - The server URL is pre-populated with the default value `http://intra.luxrobo.net:7880`.
  - Click the **서버 연결** button to apply the server URL.

- **Network Module Status**:
  - Four buttons are displayed in one row on the 네트워크 (Network) page: 
    - **모든 모듈 상태**: Fetch the status of all modules.
    - **ble**: Display BLE-related input fields and results by querying BLE status using a CCTV name.
    - **dimming**: Input and query the dimming status of the system.
    - **ota**: Manage OTA functions including file lists, OTA info, OTA init, and upload progress.

- **OTA Functionality**:
  - **OTA File List**: Displays a list of OTA files available from the server.
  - **OTA Info**: Queries OTA information using a provided CCTV name.
  - **OTA Init**: Opens an input dialog for initializing OTA with user provided parameters that trigger a server API call.
  - **Upload Progress**: Monitors the upload progress of OTA files.

- **Emergency System**:
  - **SOS 벨 Push**: 
    - Opens a dialog where users can input the CCTV name, device type, and master code. 
    - The device type and master code fields have default values (`OnePassKey` and `E8-54-B1-93-A1-56`).
    - Sends a POST request to `/api/dev/test/sos-push/{cctvName}` with a JSON body containing the device type and master code.
  - **SOS 벨 Pop**: 
    - Opens a dialog to input the CCTV name.
    - Sends a POST request to `/api/dev/test/sos-pop/{cctvName}` to perform the pop action.

- **Admin Site**:
  - Contains additional controls for managing lighting and emergency systems.
  - **Lighting Control Panel**: Manage lighting settings for various zones (e.g., 통로등, 만공차등, 충돌방지등, 실내경광등) and query default dimming values.
  - **Emergency Call System**: Access emergency system functions integrated with SOS commands.

## Setup and Installation

### Prerequisites

- [Flutter SDK](https://flutter.dev/) (version 2.0 or higher recommended)
- [http](https://pub.dev/packages/http) package for API requests (included in pubspec.yaml)

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   ```

2. **Navigate to the project directory**:
   ```bash
   cd parking_app
   ```

3. **Install the dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## Usage

- **Server URL**: Modify the server URL at the top of the application if needed and click **서버 연결** to apply the changes.
- **Modules and Features**:
  - Use the network page buttons to switch between different module views and functionalities.
  - For OTA and SOS actions, interact with the dialogs that prompt for inputs.
- **Admin Functionality**: Navigate through the bottom navigation bar to access the network, lighting control, and admin pages.

## Code Structure

- **lib/features/auth/presentation/pages/main_page.dart**: Contains the main UI logic and API integration for the networking, OTA, emergency, and admin functions.
- The project is built with Flutter and follows best practices in UI design and API consumption.

## Required Libraries

- [Flutter Material](https://api.flutter.dev/flutter/material/material-library.html)
- [http](https://pub.dev/packages/http) for making API requests

## Notes

- Ensure that the server URL and API keys/authorization values are set correctly in the code.
- For any changes to take effect, rebuild the application after modifying the code.

## License

[Include license information if applicable]

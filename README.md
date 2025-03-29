# IoT Interactor

IoT Interactor is a web-based application designed to interact with IoT devices, gather forensic data, and display logs. It provides a user-friendly interface to connect to IoT devices, start forensic data gathering, and view logs in real-time.

## Features

- **Interact with IoT Devices**: Connect to an IoT device by entering its IP address.
- **Start Forensic Data Gathering**: Trigger forensic data collection on the IoT device.
- **View Logs**: Fetch and display logs from the IoT device.
- **Responsive UI**: Built with Bootstrap for a clean and responsive design.

## Project Structure
```plaintext
iot_interactor/ 
├── app.js # Backend server code 
├── interact.html # Frontend HTML file 
├── DJLinuxJF.sh # Bash script for forensic data extraction 
├── .env # Environment variables 
├── package.json # Node.js project configuration
```


## Prerequisites

- Node.js (v16 or later)
- npm (Node Package Manager)
- Bash shell (for running `DJLinuxJF.sh` script)
- IoT device with accessible IP address

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/iot_interactor.git
   cd iot_interactor
    ```
2. Install dependencies:
    ```bash
    npm install
    ```

3. Set up environment variables:
   Create a `.env` file in the root directory and add the following variables:
   ```plaintext
   PORT=3000
   AUTH_HEADER=your_auth_header
   ```

4. Ensure the DJLinuxJF.sh script is executable:
    ```bash
    chmod +x DJLinuxJF.sh
    ```

## Usage

1. Start the server:
   ```bash
   node app.js
   ```

2. Open the `interact.html` file in a web browser.
3. Enter the IP address of the IoT device and click Interact.
4. Use the interface to start forensic data gathering and view logs.

## API Endpoints
The backend server provides the following endpoints:

- `GET /`: Returns "Hello World".
- `POST /start`: Starts the forensic data gathering process.
- `GET /logs/`:filename: Fetches the content of a specific log file.
- `GET /list`: Lists all available log files.
- `GET /help`: Provides a list of available endpoints and their descriptions.

## Scripts
- Start the server: `npm start`
- Development mode: `npm run dev` (uses nodemon for live reload)

## Colaborators
- **Dhivijit Koppuravuri**
- **Mokshagna Bhuvan**
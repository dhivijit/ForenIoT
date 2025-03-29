const express = require('express');
const { exec } = require('child_process');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

const auth_header = process.env.AUTH_HEADER;

app.use(cors());

const checkAuthHeader = (req, res, next) => {
    if (req.path === '/') {
        return next();
    }

    const authHeader = req.headers['authorization'];
    if (!authHeader || authHeader !== auth_header) {
        return res.status(403).json({ error: "Access Denied: Authorization header missing or invalid" });
    }

    next();
};

app.use(checkAuthHeader);

app.get('/', (req, res) => {
    res.send('Hello World');
});

app.post("/start", (req, res) => {
    console.log("Starting the process");
    exec('bash /home/pi/DFLinuxJF.sh -i n', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
        }
        console.log(`Output: ${stdout}`);
    });
    res.send("Process started");
});

app.get("/logs", (req, res) => {
    exec('cat /var/log/syslog', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return res.status(500).send(`Error: ${error.message}`);
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
            return res.status(500).send(`Stderr: ${stderr}`);
        }
        res.send(`Output: ${stdout}`);
    });
});

const jsonFiles = [
    'bash_command_history_pi.json', 'current_system_date.json', 'current_unix_timestamp.json', 'dmi_bios_info.json',
    'dpkg_installed_packages.json', 'executables_MD5_hashes.txt', 'extraction.log', 'hardware_clock_readout.json',
    'hardware_summary_report.json', 'ip_address_info.json', 'last_logged_on_users.json', 'network_configuration.json',
    'network_interfaces.json', 'open_files.json', 'os_installer_log.json', 'pci_device_list.json',
    'recently_used_files_pi.json', 'root_filesystem_info.json', 'root_partition_filesystem_details.json',
    'rpm_installed_packages.json', 'running_processes.json', 'system_auth_logs.json', 'system_cpuinfo.json',
    'system_environment_variables.json', 'system_filesystem_table.json', 'system_groups.json', 'system_journal_logs.json',
    'system_modules.json', 'system_startup_time.json', 'system_sudoers.json', 'system_syslog.json', 'system_uptime.json',
    'system_users.json', 'var_log_directory_listing.json'
];

jsonFiles.forEach(file => {
    app.get(`/logs/${file}`, (req, res) => {
        const filePath = path.join('/tmp/ExtractedInfo', file);
        fs.readFile(filePath, 'utf8', (err, data) => {
            if (err) {
                console.error(`Error reading file ${file}: ${err}`);
                return res.status(500).send(`Error reading file: ${err.message}`);
            }
            res.send(data);
        });
    });
});

app.get('/list', (req, res) => {
    fs.readdir('/tmp/ExtractedInfo', (err, files) => {
        if (err) {
            console.error(`Error reading directory: ${err}`);
            return res.status(500).send(`Error reading directory: ${err.message}`);
        }
        const jsonFiles = files.filter(file => file.endsWith('.json'));
        res.json(jsonFiles);
    });
});

app.get('/help', (req, res) => {
    const endpoints = {
        "GET /": "Returns 'Hello World'",
        "POST /start": "Starts the process and returns 'Process started'",
        "GET /logs/:filename": "Returns the content of the specified JSON file from /tmp/ExtractedInfo",
        "GET /list": "Returns a list of all JSON files in /tmp/ExtractedInfo",
        "GET /help": "Returns a list of available endpoints and their descriptions"
    };
    res.json(endpoints);
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    exec('whoami', (error, stdout, stderr) => {
        if (error) {
            console.error(`exec error: ${error}`);
            return;
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
            return;
        }
        console.log(`Current user: ${stdout}`);
    });
});

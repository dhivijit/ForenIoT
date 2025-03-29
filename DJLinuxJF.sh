#!/bin/bash

output_dir="/tmp/ExtractedInfo"
mkdir -p "$output_dir"
logfile="$output_dir/extraction.log"
password="vapt"

# Function to write command output in JSON format
write_output_json() {
    command=$1
    filename=$2
    key=$3

    # Run the command and capture output
    output=$($command 2>&1)
    
    # Create the JSON structure
    json_content="{
  \"status\": \"$([[ $? -eq 0 ]] && echo \"success\" || echo \"failure\")\",
  \"output\": \"$output\"
}"

    # Write to a separate JSON file
    echo "$json_content" > "$output_dir/$filename.json"

    # Log the result
    if [[ $? -eq 0 ]]; then
        echo "Successfully executed: $command" >> "$logfile"
    else
        echo "Failed to execute: $command" >> "$logfile"
    fi
}

# Hide cursor during script execution
tput civis

# Parse command-line arguments
install_dependencies="n"
while getopts "i:" opt; do
    case $opt in
        i)
            install_dependencies=$OPTARG
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ -n "$ID" ]; then
        distro="$ID"
        if [ "$install_dependencies" == "y" ]; then
            echo "Installing Dependencies." > "$logfile"
            (while :; do for c in / - \\ \|; do printf "\e[1;33m\r[$c] Installing Dependencies...\e[0m"; sleep .1; done; done) &
            case "$distro" in
                "ubuntu" | "debian" | "linuxmint" | "elementary")
                    sudo apt-get update &> /dev/null
                    sudo apt-get install -y util-linux net-tools zip unzip &> /dev/null
                    ;;
                "centos" | "rhel" | "fedora")
                    sudo yum update &> /dev/null
                    sudo yum install -y util-linux net-tools zip unzip &> /dev/null
                    ;;
                "opensuse")
                    sudo zypper refresh &> /dev/null
                    sudo zypper install -y util-linux net-tools zip unzip &> /dev/null
                    ;;
                *)
                    exit 1
                    ;;
            esac
        elif [ "$install_dependencies" == "n" ]; then
            echo "Skipping Dependency Installation." > "$logfile"
        else
            echo "Invalid input. Please enter 'y' or 'n'."
            exit 1
        fi
    else
        echo "Unable to determine distribution." >> "$logfile"
        exit 1
    fi
else
    echo "Unable to determine distribution." >> "$logfile"
    exit 1
fi

if [ "$install_dependencies" == "y" ]; then
  echo "Successfully Installed Dependencies." >> "$logfile"
  { printf "\e[1;32m\r[+] Successfully Installed Dependencies.\e[0m"; kill $! && wait $!; } 2>/dev/null
else
  { printf "\e[1;32m\r[+] Skipped Installing Dependencies.\e[0m"; kill $! && wait $!; } 2>/dev/null
fi

# Run commands and save their outputs as JSON files

write_output_json "uptime -p" "system_uptime" "System Uptime"
write_output_json "uptime -s" "system_startup_time" "System Startup Time"
write_output_json "date" "current_system_date" "Current System Date"
write_output_json "date +%s" "current_unix_timestamp" "Current Unix Timestamp"
write_output_json "env" "system_environment_variables" "System Environment Variables"
write_output_json "lsmod" "system_modules" "System Modules"
write_output_json "lsof" "open_files" "Open Files"
write_output_json "cat /etc/passwd" "system_users" "System Users"
write_output_json "cat /etc/group" "system_groups" "System Groups"
write_output_json "cat /proc/cpuinfo" "system_cpuinfo" "System CPU Info"
write_output_json "cat /etc/sudoers" "system_sudoers" "System Sudoers File"
write_output_json "cat /etc/fstab" "system_filesystem_table" "System Filesystem Table"
write_output_json "ps aux" "running_processes" "Running Processes"

# Check for hwclock command
if command -v hwclock &>/dev/null; then
    write_output_json "hwclock -r" "hardware_clock_readout" "Hardware Clock Readout"
else
    echo "hwclock command not found" >> "$logfile"
fi

# Additional system information and extraction logic
write_output_json "df -P /" "root_filesystem_info" "Root Filesystem Info"
write_output_json "ls -l /var/log/installer" "os_installer_log" "OS Installer Log"
filesystem_name=$(df / | awk 'NR==2 {print $1}')
write_output_json "tune2fs -l $filesystem_name" "root_partition_filesystem_details" "Root Partition Filesystem Details"

write_output_json "ifconfig" "network_configuration" "Network Configuration"
write_output_json "ip addr" "ip_address_info" "IP Address Info"
write_output_json "netstat -i" "network_interfaces" "Network Interfaces"

# Installed Programs
write_output_json "dpkg -l" "dpkg_installed_packages" "Installed Packages (dpkg)"
write_output_json "rpm -qa" "rpm_installed_packages" "Installed Packages (rpm)"

# Hardware Information
write_output_json "lspci" "pci_device_list" "PCI Device List"
write_output_json "lshw -short" "hardware_summary_report" "Hardware Summary Report"
write_output_json "dmidecode" "dmi_bios_info" "DMI BIOS Info"

# System Logs and Usage
write_output_json "journalctl" "system_journal_logs" "System Journal Logs"
write_output_json "cat /var/log/syslog" "system_syslog" "System Syslog"
write_output_json "cat /var/log/auth.log" "system_auth_logs" "System Auth Logs"
write_output_json "ls -lah /var/log/" "var_log_directory_listing" "Var Log Directory Listing"
write_output_json "last" "last_logged_on_users" "Last Logged On Users"

# User Command History
for user_home in /home/*; do
    username=$(basename "$user_home")
    if [ -f "$user_home/.bash_history" ]; then
        write_output_json "cat $user_home/.bash_history" "bash_command_history_$username" "Bash Command History ($username)"
    else
        echo "No .bash_history for $username" >> "$logfile"
    fi
    if [ -f "$user_home/.zsh_history" ]; then
        write_output_json "cat $user_home/.zsh_history" "zsh_command_history_$username" "Zsh Command History ($username)"
    else
        echo "No .zsh_history for $username" >> "$logfile"
    fi
    write_output_json "cat $user_home/.local/share/recently-used.xbel" "recently_used_files_$username" "Recently Used Files ($username)"
done

# Crontab for root
if crontab -l &>/dev/null; then
    write_output_json "crontab -l" "scheduled_cron_jobs_root" "Scheduled Cron Jobs (root)"
else
    echo "No crontab for root" >> "$logfile"
fi

# Hashing Executable Files
find / -type f -xdev -executable -not \( -path '/proc/*' -o -path '/sys/*' \) -exec md5sum {} \; 2>/dev/null > "$output_dir/executables_MD5_hashes.txt"
write_output_json "cat $output_dir/executables_MD5_hashes.txt" "executables_md5_hashes" "Executable Files MD5 Hashes"

# Dump Memory
sudo ./avml memory.dmp
sudo mv memory.dmp "$output_dir"
write_output_json "cat $output_dir/memory.dmp" "memory_dump" "Memory Dump"

# Encrypt and Compress the JSON files
host_name=$(hostname)
zip -P "$password" -r "$output_dir/$host_name.zip" "$output_dir"/*.json &>/dev/null

# Clean up JSON files after zipping
rm "$output_dir"/*.json

# Show completion
echo "Data extraction complete. Check the $output_dir directory for the output ZIP file."
echo "Successfully completed encryption and compression." >> "$logfile"
printf "\e[1;32m[+] Data extraction complete. Check the $output_dir directory for output.\e[0m"
printf "\n"

# Show cursor again
tput cnorm
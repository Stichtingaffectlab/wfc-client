#!/bin/bash

cd ~/code/wfc-client

# Set the directory where the logs are stored
LOG_DIR="tmp"  # Replace with the actual directory where logs are stored

# Find and remove log files older than 7 days
find "$LOG_DIR" -type f -name "mpv-*.log" -mtime +7 -exec rm -f {} \;

# Find and remove ruby log files more than 2 weeks
find "$LOG_DIR" -type f -name "wfc-*.log" -mtime +14 -exec rm -f {} \;

# Optionally, print a message after cleaning up
echo "Removed log files older than 7 days from $LOG_DIR"

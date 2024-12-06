#!/bin/bash

# Generate timestamp in yyyy-mm-dd-hh format
DATESTAMP=$(date +"%Y-%m-%d")

# Start mpv with logs visible and running in the background
nohup mpv --input-ipc-server=/tmp/mpvsocket --loop=inf --fullscreen ./videos/235_ruminations_inside.mp4 > tmp/mpv-$DATESTAMP.log 2>&1 &

echo "mpv started. Logs are being written to tmp/mpv-$DATESTAMP.log"

# Start the Ruby script with logs visible and running in the background
nohup ruby main.rb > tmp/wfc-$DATESTAMP.log 2>&1 &

echo "Ruby script started. Logs are being written to tmp/wfc-$DATESTAMP.log"

# Display information to the user
echo "Both processes are running in the background."

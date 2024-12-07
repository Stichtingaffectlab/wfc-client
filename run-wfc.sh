#!/bin/bash

# Define process names or identifiers
MPV_SOCKET="/tmp/mpvsocket"
RUBY_SCRIPT="main.rb"

# Ensure tmp directory exists
mkdir -p tmp

# Kill the `mpv` process if running
if [ -e "$MPV_SOCKET" ]; then
  echo "Stopping existing mpv process..."
  MPV_PID=$(pgrep -f "$MPV_SOCKET")
  if [ ! -z "$MPV_PID" ]; then
    kill "$MPV_PID"
    echo "mpv process ($MPV_PID) stopped."
  fi
else
  echo "No mpv process found."
fi

# Kill the Ruby process if running
RUBY_PID=$(pgrep -f "$RUBY_SCRIPT")
if [ ! -z "$RUBY_PID" ]; then
  echo "Stopping existing Ruby process..."
  kill "$RUBY_PID"
  echo "Ruby process ($RUBY_PID) stopped."
else
  echo "No Ruby process found."
fi

# Generate timestamp in yyyy-mm-dd-hh format
DATESTAMP=$(date +"%Y-%m-%d")

# Start mpv with logs visible and running in the background
nohup mpv --input-ipc-server=/tmp/mpvsocket --loop=inf --fullscreen ./videos/235_ruminations_inside.mp4 >> tmp/mpv-$DATESTAMP.log 2>&1 &

echo "mpv started. Logs are being written to tmp/mpv-$DATESTAMP.log"

# Start the Ruby script with logs visible and running in the background
nohup ruby main.rb >> tmp/wfc-$DATESTAMP.log 2>&1 &

echo "Ruby script started. Logs are being written to tmp/wfc-$DATESTAMP.log"

# Display information to the user
echo "Both processes are running in the background."

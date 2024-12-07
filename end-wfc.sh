#!/bin/bash

# Define process names or identifiers
MPV_SOCKET="/tmp/mpvsocket"
RUBY_SCRIPT="main.rb"

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

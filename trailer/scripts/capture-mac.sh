#!/usr/bin/env bash
# Record the Mac's main display while TrailerMode plays takes in Studio.
#   scripts/capture-mac.sh <seconds> <out.mov>
# Uses ffmpeg (avfoundation, 60 fps) when installed, else macOS's built-in
# `screencapture -v`. Either needs Screen Recording permission for the app
# running it (System Settings > Privacy & Security > Screen Recording).
set -euo pipefail
secs=${1:?seconds}; out=${2:?out file}
if command -v ffmpeg >/dev/null 2>&1; then
  # "Capture screen 0" is the main display; list devices with:
  #   ffmpeg -f avfoundation -list_devices true -i ""
  screen=$(ffmpeg -hide_banner -f avfoundation -list_devices true -i "" 2>&1 | sed -n 's/.*\[\([0-9]*\)\] Capture screen 0.*/\1/p' | head -1)
  ffmpeg -hide_banner -loglevel warning -y -f avfoundation -capture_cursor 0 -framerate 60 -i "${screen:-1}:none" \
    -t "$secs" -c:v libx264 -preset ultrafast -crf 14 -pix_fmt yuv420p "$out"
else
  screencapture -v -V "$secs" -x "$out"
fi
echo "$out"

#!/bin/bash

# Ensure VIDEO_URL and STREAM_KEY are set
if [ -z "$VIDEO_URL" ]; then
  echo "Error: VIDEO_URL is not set."
  exit 1
fi

if [ -z "$STREAM_KEY" ]; then
  echo "Error: STREAM_KEY is not set."
  exit 1
fi

# Download the best MP4 video (vertical format preferred)
echo "Downloading video from YouTube..."
yt-dlp --cookies /app/cookies.txt -f "bv*[height<=1920][ext=mp4]+ba[ext=m4a]/b[height<=1920][ext=mp4]" -o "/app/video.%(ext)s" "$VIDEO_URL"

# Wait for the download to complete
sleep 5

# Find the downloaded video file
VIDEO_FILE=$(find /app -type f -name "video.mp4" | head -n 1)

# Debugging: Show file name
echo "Video file found: $VIDEO_FILE"

# Check if the file exists
if [ -z "$VIDEO_FILE" ]; then
  echo "Error: Failed to download video."
  exit 1
fi

# Ensure video is in vertical format (9:16)
echo "Checking video aspect ratio..."
ffmpeg -i "$VIDEO_FILE" -vf "scale=1080:1920,setsar=1:1" -c:v libx264 -preset fast -c:a aac -b:a 128k -y /app/vertical_video.mp4

# Check if the fixed file exists
if [ ! -f /app/vertical_video.mp4 ]; then
  echo "Error: Failed to fix video aspect ratio."
  exit 1
fi

# Start streaming to YouTube
echo "Starting the stream in vertical format..."
ffmpeg -re -stream_loop -1 -i /app/vertical_video.mp4 -c:v libx264 -preset fast -c:a aac -b:a 128k -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

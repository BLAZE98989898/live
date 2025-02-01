#!/bin/bash

# Ensure the VIDEO_URL and STREAM_KEY are set
if [ -z "$VIDEO_URL" ]; then
  echo "Error: VIDEO_URL is not set."
  exit 1
fi

if [ -z "$STREAM_KEY" ]; then
  echo "Error: STREAM_KEY is not set."
  exit 1
fi

# Download the best video and audio streams separately
echo "Downloading video and audio from YouTube..."
yt-dlp --cookies /app/cookies.txt -f bestvideo+bestaudio --merge-output-format mp4 -o "/app/video.mp4" "$VIDEO_URL"

# Wait until video is downloaded
sleep 5

# Check if the video file was downloaded
if [ ! -f /app/video.mp4 ]; then
  echo "Error: Failed to download video."
  exit 1
fi

# Convert to vertical format and fix moov atom issue
echo "Converting video to vertical format..."
ffmpeg -i /app/video.mp4 -vf "scale=720:1280,format=yuv420p" \
-c:v libx264 -preset fast -b:v 2500k -c:a aac -b:a 128k \
-movflags +faststart -y /app/final_video.mp4

# Check if the final video exists
if [ ! -f /app/final_video.mp4 ]; then
  echo "Error: Failed to process video."
  exit 1
fi

# Start streaming to YouTube
echo "Starting the stream to YouTube..."
ffmpeg -re -stream_loop -1 -i /app/final_video.mp4 -c:v libx264 -b:v 2500k -c:a aac -b:a 128k -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

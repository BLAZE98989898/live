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

# Download video and audio separately
echo "Downloading video and audio from YouTube..."
yt-dlp --cookies /app/cookies.txt -f bestvideo -o "/app/video.%(ext)s" "$VIDEO_URL"
yt-dlp --cookies /app/cookies.txt -f bestaudio -o "/app/audio.%(ext)s" "$VIDEO_URL"

# Wait for downloads
sleep 5

# Find downloaded files dynamically
VIDEO_FILE=$(find /app -type f -name "video.*" | head -n 1)
AUDIO_FILE=$(find /app -type f -name "audio.*" | head -n 1)

# Debugging: Show file names
echo "Video file found: $VIDEO_FILE"
echo "Audio file found: $AUDIO_FILE"

# Check if both files exist
if [ -z "$VIDEO_FILE" ] || [ -z "$AUDIO_FILE" ]; then
  echo "Error: Failed to download video or audio."
  exit 1
fi

# Merge video and audio
echo "Merging video and audio..."
ffmpeg -i "$VIDEO_FILE" -i "$AUDIO_FILE" -c:v libx264 -preset fast -b:v 2500k -c:a aac -b:a 128k -movflags +faststart -y /app/video.mp4

# Check if the final video is created
if [ ! -f /app/video.mp4 ]; then
  echo "Error: Failed to merge video and audio."
  exit 1
fi

# Convert to vertical format
echo "Converting video to vertical format..."
ffmpeg -i /app/video.mp4 -vf "scale=720:1280,format=yuv420p" -c:v libx264 -preset fast -b:v 2500k -c:a aac -b:a 128k -movflags +faststart -y /app/final_video.mp4

# Check if final file exists
if [ ! -f /app/final_video.mp4 ]; then
  echo "Error: Failed to process video."
  exit 1
fi

# Start streaming
echo "Starting the stream to YouTube..."
ffmpeg -re -stream_loop -1 -i /app/final_video.mp4 -c:v libx264 -b:v 2500k -c:a aac -b:a 128k -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

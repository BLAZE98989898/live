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

# Remove old files to prevent issues
rm -f /app/video.mp4 /app/audio.m4a /app/merged.mp4

# Download the best available video (preferably 720p)
echo "Downloading video (preferably 720p)..."
yt-dlp --cookies /app/cookies.txt -f "bestvideo[height<=720][ext=mp4]" -o "/app/video.mp4" "$VIDEO_URL"

# Download audio separately (M4A format)
echo "Downloading audio..."
yt-dlp --cookies /app/cookies.txt -f "bestaudio[ext=m4a]" -o "/app/audio.m4a" "$VIDEO_URL"

# Wait for downloads to complete
sleep 5

# Verify if video and audio exist
if [ ! -f "/app/video.mp4" ] || [ ! -f "/app/audio.m4a" ]; then
  echo "Error: Video or audio file missing."
  exit 1
fi

# Scale the video to 720p if necessary and merge video and audio
echo "Scaling video to 720p and merging with audio..."
ffmpeg -i "/app/video.mp4" -i "/app/audio.m4a" -vf "scale=1280:720" -c:v libx264 -preset fast -c:a aac -b:a 128k -strict experimental -movflags +faststart "/app/merged.mp4"

# Verify merged file
if [ ! -f "/app/merged.mp4" ]; then
  echo "Error: Merging failed."
  exit 1
fi

# Start streaming with proper encoding
echo "Starting vertical live stream..."
ffmpeg -re -stream_loop -1 -i "/app/merged.mp4" \
  -c:v libx264 -preset veryfast -tune zerolatency -crf 28 -b:v 1000k -maxrate 1500k -bufsize 2000k \
  -c:a aac -b:a 128k -ac 2 -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

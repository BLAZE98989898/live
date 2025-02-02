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

# Remove old files if exist
rm -f /app/video.mp4 /app/video.webm /app/audio.m4a /app/vertical_video.mp4

# Download video and audio separately
echo "Downloading video..."
yt-dlp --cookies /app/cookies.txt -f "bestvideo[height<=1920][ext=mp4]" -o "/app/video.mp4" "$VIDEO_URL"

echo "Downloading audio..."
yt-dlp --cookies /app/cookies.txt -f "bestaudio[ext=m4a]" -o "/app/audio.m4a" "$VIDEO_URL"

# Wait for downloads to complete
sleep 5

# Verify downloaded files
if [ ! -f "/app/video.mp4" ] || [ ! -f "/app/audio.m4a" ]; then
  echo "Error: Video or audio file missing."
  exit 1
fi

# Merge video and audio properly
echo "Merging video and audio..."
ffmpeg -i "/app/video.mp4" -i "/app/audio.m4a" -c:v copy -c:a aac -strict experimental -movflags +faststart "/app/merged.mp4"

# Verify merged file
if [ ! -f "/app/merged.mp4" ]; then
  echo "Error: Merging failed."
  exit 1
fi

# Ensure vertical format (1080x1920)
echo "Converting to vertical format..."
ffmpeg -i "/app/merged.mp4" -vf "scale=1080:1920,setsar=1:1" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart "/app/vertical_video.mp4"

# Verify final file
if [ ! -f "/app/vertical_video.mp4" ]; then
  echo "Error: Failed to convert video to vertical format."
  exit 1
fi

# Start streaming
echo "Starting vertical live stream..."
ffmpeg -re -stream_loop -1 -i "/app/vertical_video.mp4" -c:v libx264 -preset fast -c:a aac -b:a 128k -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

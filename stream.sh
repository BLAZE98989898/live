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

# Download the best video and audio streams separately using cookies.txt
echo "Downloading video and audio from YouTube..."
yt-dlp --cookies /app/cookies.txt -f bestvideo -o "/app/video.%(ext)s" "$VIDEO_URL"
yt-dlp --cookies /app/cookies.txt -f bestaudio -o "/app/audio.%(ext)s" "$VIDEO_URL"

# Wait for downloads to complete
sleep 5

# Check if the files were downloaded
VIDEO_FILE=$(ls /app/video.* 2>/dev/null)
AUDIO_FILE=$(ls /app/audio.* 2>/dev/null)

if [ -z "$VIDEO_FILE" ] || [ -z "$AUDIO_FILE" ]; then
  echo "Error: Failed to download video or audio."
  exit 1
fi

# Merge the video and audio using ffmpeg
echo "Merging video and audio into a single file..."
ffmpeg -i "$VIDEO_FILE" -i "$AUDIO_FILE" -c:v copy -c:a aac -strict experimental /app/merged.mp4

# Check if the merged file exists
if [ ! -f /app/merged.mp4 ]; then
  echo "Error: Failed to merge video and audio."
  exit 1
fi

# Start streaming to YouTube in vertical format
echo "Starting the vertical live stream to YouTube..."
ffmpeg -re -stream_loop -1 -i "/app/merged.mp4" \
  -vf "scale=720:-1" -c:v libx264 -preset veryfast -tune zerolatency -crf 28 -b:v 1000k -maxrate 1500k -bufsize 2000k \
  -c:a aac -b:a 96k -ac 2 -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"

echo "Stream ended."

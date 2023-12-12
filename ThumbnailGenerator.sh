#!/bin/bash

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to convert timecode to seconds
timecode_to_seconds() {
    local timecode=$1
    local hours=$(echo "$timecode" | cut -d: -f1)
    local minutes=$(echo "$timecode" | cut -d: -f2)
    local seconds=$(echo "$timecode" | cut -d: -f3 | cut -d. -f1)

    local total_seconds=$((hours * 3600 + minutes * 60 + seconds))
    echo "$total_seconds"
}

# Variables for error messages
error_messages=()
has_errors=false

# Check if a directory has been passed as a parameter
if [ $# -eq 0 ]; then
    echo -e "${RED}Please specify the path to the folder containing the videos.${NC}"
    exit 1
fi

videos_folder="$1"

# Check if the folder exists
if [ ! -d "$videos_folder" ]; then
    echo -e "${RED}The specified folder does not exist.${NC}"
    exit 1
fi

thumbnails_folder="$videos_folder/thumbnails"
if [ ! -d "$thumbnails_folder" ]; then
    if ! mkdir "$thumbnails_folder"; then
        echo -e "${RED}Failed to create thumbnails folder.${NC}"
        exit 1
    fi
fi

# Browse through all the videos in the folder
for video_file in "$videos_folder"/*; do
    if [ -f "$video_file" ]; then
        # Check if it's a video file
        file_type=$(file -b --mime-type "$video_file")
        if [[ $file_type == video/* ]]; then
            # Extract the file name without extension
            video_name=$(basename "$video_file")
            video_name="${video_name%.*}"  # Remove extension

            echo -e "${YELLOW}Processing video: $video_name${NC}"
            # Create a folder for each video if it doesn't exist already
            output_folder="$videos_folder/${video_name}"
            if ! mkdir -p "$output_folder"; then
                error_messages+=("Failed to create output folder for $video_name.")
                has_errors=true
                continue
            fi

            # Extract duration information of the video
            duration_timecode=$(ffmpeg -i "$video_file" 2>&1 | awk '/Duration:/ {print $2}' | tr -d , | awk -F ':' '{printf "%02d:%02d:%02d", $1, $2, $3}')
            duration_seconds=$(timecode_to_seconds "$duration_timecode")
            if [ -z "$duration_seconds" ]; then
                error_messages+=("Failed to extract duration for $video_name.")
                has_errors=true
                rm -r "$output_folder"
                continue
            fi

            #echo -e "${YELLOW}Duration for $video_name: $duration_seconds seconds${NC}"

            # Generate thumbnails based on video duration
            if [ "$duration_seconds" -lt 60 ]; then
              # Generate 4 thumbnails with timecode in the filename
              for ((i = 0; i < 4; i++)); do
                  segment_start=$((duration_seconds * i / 4))
                  timecode=$(printf "%04d" $((segment_start)))
                  if ! ffmpeg -ss "$segment_start" -i "$video_file" -hide_banner -loglevel error -nostats -vframes 1 "$output_folder/$timecode.jpg" &>/dev/null; then
                      error_messages+=("Failed to generate thumbnail $i/4 for $video_name.")
                      has_errors=true
                  fi
              done
            else
              # Generate 16 thumbnails with timecode in the filename
              for ((i = 0; i < 16; i++)); do
                  segment_start=$((duration_seconds * i / 16))
                  timecode=$(printf "%04d" $((segment_start)))
                  if ! ffmpeg -ss "$segment_start" -i "$video_file" -hide_banner -loglevel error -nostats -vframes 1 "$output_folder/$timecode.jpg" &>/dev/null; then
                      error_messages+=("Failed to generate thumbnail $i/16 for $video_name.")
                      has_errors=true
                  fi
              done
          fi

          wait # Wait for all background thumbnail generation processes to finish

          video_title=$(basename "$video_file")
          duration_timecode=$(ffmpeg -i "$video_file" 2>&1 | awk '/Duration:/ {print $2}' | tr -d , | awk -F ':' '{printf "%02d:%02d:%02d", $1, $2, $3}')
          file_size=$(du -h "$video_file" | cut -f1)
          #width=$(identify -format "%w" "$output_folder/mosaic.jpg")
          #height=$(identify -format "%h" "$output_folder/mosaic.jpg")

          # Calculate dimensions for text overlay
          #black_image_height=$(awk "BEGIN { printf \"%.0f\n\", $height * 0.1 }")
          #new_mosaic_height=$((height - black_image_height))

          text="Filename: $video_title\nSize: $file_size\nResolution: $resolution\nLength: $duration_timecode"
          # Get video resolution
          resolution=$(mediainfo --Output="Video;%Width%x%Height%" "$video_file")
          rotation=$(mediainfo --Output="Video;%Rotation%" "$video_file")

          mapfile -d '' files_array < <(find "$output_folder" -type f -name '*.jpg' -print0 | sort -z)
          #If rotation is 90 or 270, exchange resolution values
          if [ "$rotation" = "90.000°" ] || [ "$rotation" = "270.000" ]; then
              resolution=("${resolution##*x}")x"${resolution%%x*}"
          fi
          # Create mosaic based on video duration
          if [ "$duration_seconds" -lt 60 ]; then
            mapfile -d '' files_array < <(find "$output_folder" -type f -name '*.jpg' -print0 | sort -z)
            # For short videos, create a 2x2 mosaic
            montage -tile 2x2 -geometry "${resolution}+0+0" "${files_array[@]}" "$output_folder/mosaic.jpg"
          else
            # For longer videos, create a 4x4 mosaic
            montage -tile 4x4 -geometry "${resolution}+0+0" "${files_array[@]}" "$output_folder/mosaic.jpg"

          fi

          # Retrieve video information if not retrieved previously
          if [ ! -f "$output_folder/image_noire.jpg" ]; then
              video_title=$(basename "$video_file")
              duration_timecode=$(ffmpeg -i "$video_file" 2>&1 | awk '/Duration:/ {print $2}' | tr -d , | awk -F ':' '{printf "%02d:%02d:%02d", $1, $2, $3}')
              file_size=$(du -h "$video_file" | cut -f1)
              width=$(identify -format "%w" "$output_folder/mosaic.jpg")
              height=$(identify -format "%h" "$output_folder/mosaic.jpg")

              # Calculate dimensions for text overlay
              black_image_height=$(awk "BEGIN { printf \"%.0f\n\", $height * 0.1 }")
              new_mosaic_height=$((height - black_image_height))

              text="Filename: $video_title\nSize: $file_size\nResolution: $resolution\nLength: $duration_timecode"
              scale_factor=0.02
              text_size=$(awk "BEGIN { printf \"%.0f\n\", $new_mosaic_height * $scale_factor }")

              # Create a black image with text overlay
              convert -size "${width}x${black_image_height}" xc:black -fill white -pointsize "$text_size" -gravity West -annotate +50+0 "$text" "$output_folder/image_noire.jpg"
          fi
          # Combine images vertically to create the final thumbnail image
          convert "$output_folder/image_noire.jpg" "$output_folder/mosaic.jpg" -background none -quality 80 -append "$output_folder/${video_name}_thumbnails.jpg"
          #cp "$output_folder/${video_name}_thumbnails.jpg"  "$thumbnails_folder"
          find "$output_folder" -maxdepth 1 -type f -name '*.jpg' ! -name "*thumbnails.jpg" -exec rm -v {} + &>/dev/null
          # Move the video file to the processed folder
          mv "$video_file" "$output_folder/"
          cp "$output_folder/${video_name}_thumbnails.jpg" "$thumbnails_folder"
          echo -e "${YELLOW}Completed processing for video: $video_name${NC}"

        else
            error_messages+=("${RED}The file '$video_file' is not a video and will be ignored.${NC}")
            has_errors=true
            rm -r "$output_folder"
        fi
    fi
done

# Display error messages
if [ "$has_errors" = true ]; then
    echo -e "${RED}Errors occurred during processing:${NC}"
    for error_message in "${error_messages[@]}"; do
        echo -e "$error_message"
    done
fi

#!/bin/bash

# Check if a directory has been passed as a parameter
if [ $# -eq 0 ]; then
    echo "Please specify the path to the folder containing the videos."
    exit 1
fi

videos_folder="$1"

# Check if the folder exists
if [ ! -d "$videos_folder" ]; then
    echo "The specified folder does not exist."
    exit 1
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

            # Measure the time for each video processing
            echo "Processing video: $video_name"
            time (
                # Create a folder for each video if it doesn't exist already
                output_folder="$videos_folder/${video_name}"
                mkdir -p "$output_folder"

                # Get the total duration of the video (if not retrieved previously)
                duration=$(ffprobe -i "$video_file" -show_entries format=duration -v quiet -of csv="p=0")

                # Generate thumbnails for 16 segments in parallel
                for ((i = 0; i < 16; i++)); do
                    segment_start=$(bc -l <<< "$duration * $i / 16")
                    segment_end=$(bc -l <<< "$duration * ($i + 1) / 16")

                    # Generate thumbnails for each segment in the background
                    ffmpeg -ss "$segment_start" -i "$video_file" -hide_banner -loglevel error -nostats -vframes 1 -vf "scale=1920:-1" "$output_folder/${video_name}_thumbnail_$i.jpg" &
                done
                wait # Wait for all background processes to finish

                # Create a mosaic from the thumbnails
                montage -tile 4x4 -geometry 1920x1080+0+0 "$output_folder/${video_name}_thumbnail_"*.jpg "$output_folder/${video_name}_mosaic.jpg"

                # Retrieve video information (if not retrieved previously)
                if [ ! -f "$output_folder/image_noire.jpg" ]; then
                    video_title=$(basename "$video_file")
                    resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$video_file")
                    duration_timecode=$(ffmpeg -i "$video_file" 2>&1 | awk '/Duration:/ {print $2}' | tr -d , | awk -F ':' '{printf "%02d:%02d:%02d", $1, $2, $3}')
                    file_size=$(du -h "$video_file" | cut -f1)

                    # Concatenate information into the text variable
                    text="Filename: $video_title\nSize: $file_size\nResolution: $resolution\nLength: $duration_timecode"

                    convert -size 7680x400 xc:black -fill white -pointsize 80 -gravity West -annotate +50+0 "$text" "$output_folder/image_noire.jpg"
                fi

                # Combine images vertically
                convert "$output_folder/image_noire.jpg" "$output_folder/${video_name}_mosaic.jpg" -background none -append "$output_folder/${video_name}_thumbnails.jpg"

                # Remove individual thumbnails after creating the mosaic
                rm "$output_folder/${video_name}_thumbnail_"*.jpg
                rm "$output_folder/${video_name}_mosaic"*.jpg
                rm "$output_folder/image_noire.jpg"

                #Move the video in the folder
                mv "$video_file" "$output_folder/"
            )
            echo "Completed processing for video: $video_name"
        else
            echo "The file '$video_file' is not a video and will be ignored."
        fi
    fi
done

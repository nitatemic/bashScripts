#!/bin/bash

# Check if the argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <folder_path>"
    exit 1
fi

# Store the folder path provided as an argument
folder_path=$1

# Check if the folder exists
if [ ! -d "$folder_path" ]; then
    echo "Folder not found: $folder_path"
    exit 1
fi

# Move files from subfolders to the topmost folder
find "$folder_path" -mindepth 2 -type f -exec bash -c 'mv "$1" "${1%/*}/../.." ' _ {} \;

# Remove empty directories
find "$folder_path" -type d -empty -delete

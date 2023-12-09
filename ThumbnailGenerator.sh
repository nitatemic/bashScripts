#!/bin/bash

# Vérifier si un dossier a été passé en paramètre
if [ $# -eq 0 ]; then
    echo "Veuillez spécifier le chemin du dossier contenant les vidéos."
    exit 1
fi

videos_folder="$1"

# Vérifier si le dossier existe
if [ ! -d "$videos_folder" ]; then
    echo "Le dossier spécifié n'existe pas."
    exit 1
fi

# Parcourir toutes les vidéos du dossier
for video_file in "$videos_folder"/*; do
    if [ -f "$video_file" ]; then
        # Vérifier si c'est un fichier vidéo
        file_type=$(file -b --mime-type "$video_file")
        if [[ $file_type == video/* ]]; then
            # Extraire le nom du fichier sans extension
            video_name=$(basename "$video_file")
            video_name="${video_name%.*}"  # Retirer l'extension

            # Créer un dossier pour chaque vidéo s'il n'existe pas déjà
            output_folder="$videos_folder/${video_name}"
            mkdir -p "$output_folder"

            # Obtenir la durée totale de la vidéo
            duration=$(ffprobe -i "$video_file" -show_entries format=duration -v quiet -of csv="p=0")

            # Diviser la vidéo en 16 segments égaux et générer des miniatures
            for ((i = 0; i < 16; i++)); do
                segment_start=$(bc -l <<< "$duration * $i / 16")
                segment_end=$(bc -l <<< "$duration * ($i + 1) / 16")

                # Générer des miniatures pour chaque segment
                ffmpeg -ss "$segment_start" -i "$video_file" -vframes 1 -vf "scale=1920:1080" "$output_folder/${video_name}_thumbnail_$i.jpg"
            done

            # Créer une mosaïque à partir des miniatures
            montage -tile 4x4 -geometry 1920x1080+0+0 "$output_folder/${video_name}_thumbnail_"*.jpg "$output_folder/${video_name}_mosaic.jpg"
        
            # Supprimer les miniatures individuelles après la création de la mosaïque
            rm "$output_folder/${video_name}_thumbnail_"*.jpg
        else
            echo "Le fichier '$video_file' n'est pas une vidéo et sera ignoré."
        fi
    fi
done

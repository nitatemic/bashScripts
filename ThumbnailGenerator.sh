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

            # Définir les pourcentages pour les segments (10%, 50%, 90%)
            segment1_start=$(bc -l <<< "$duration * 0.1")
            segment1_end=$(bc -l <<< "$duration * 0.2")
            segment2_start=$(bc -l <<< "$duration * 0.5")
            segment2_end=$(bc -l <<< "$duration * 0.6")
            segment3_start=$(bc -l <<< "$duration * 0.9")
            segment3_end=$(bc -l <<< "$duration * 0.95")

            # Générer une vidéo à partir des segments spécifiés
            ffmpeg -i "$video_file" -vf "select='between(t,$segment1_start,$segment1_end)+between(t,$segment2_start,$segment2_end)+between(t,$segment3_start,$segment3_end)',setpts=N/FRAME_RATE/TB" -af "aselect='between(t,$segment1_start,$segment1_end)+between(t,$segment2_start,$segment2_end)+between(t,$segment3_start,$segment3_end)',asetpts=N/SR/TB" -an "$output_folder/${video_name}_output.mp4"

            # Créer des miniatures à partir de la vidéo
            ffmpeg -i "$video_file" -vf "select='isnan(prev_selected_t)+gte(t-prev_selected_t,2)',scale=160:90,tile=7x7" "$output_folder/${video_name}_thumbnails_$(uuidgen).jpg"

        else
            echo "Le fichier '$video_file' n'est pas une vidéo et sera ignoré."
        fi
    fi
done

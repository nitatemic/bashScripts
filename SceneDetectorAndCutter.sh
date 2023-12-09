#!/bin/bash

# Vérifie si un dossier est passé en paramètre
if [ $# -ne 1 ]; then
    echo "Usage: $0 <dossier>"
    exit 1
fi

# Récupère le dossier passé en paramètre
dossier="$1"

# Vérifie si le dossier existe
if [ ! -d "$dossier" ]; then
    echo "Le dossier spécifié n'existe pas."
    exit 1
fi

# Parcours tous les sous-dossiers du dossier spécifié
for sous_dossier in "$dossier"/*; do
    if [ -d "$sous_dossier" ]; then
        # Recherche des fichiers vidéo dans chaque sous-dossier
        for video in "$sous_dossier"/*.mp4 "$sous_dossier"/*.avi "$sous_dossier"/*.mkv; do
            if [ -f "$video" ]; then

                scenedetect -i "$video" split-video
                # Créer un sous-dossier à côté de la vidéo d'origine
                nouveau_dossier="${video%.*}_scenes"
                mkdir -p "$nouveau_dossier"

                # Récupère le dossier du script
                dossier_script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

                # Déplacer les fichiers avec le format nomdufichier-Scene-001.mp4, etc.
                mv "$dossier_script"/*-Scene-*.mp4 "$nouveau_dossier/"

                #problème de permission sinon
                chmod +x ThumbnailGenerator.sh
                ./ThumbnailGenerator.sh "$nouveau_dossier"
            fi
        done
    fi
done

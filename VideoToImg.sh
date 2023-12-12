#!/bin/bash

# Vérification du nombre d'arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 chemin_dossier_videos"
  exit 1
fi

# Récupération du chemin du dossier passé en paramètre
dossier_videos="$1"

# Vérification si le dossier existe
if [ ! -d "$dossier_videos" ]; then
  echo "Le dossier spécifié n'existe pas."
  exit 1
fi

# Se déplacer vers le dossier vidéo
cd "$dossier_videos" || exit

# Boucle pour chaque fichier vidéo dans le dossier
for fichier in *.{mp4,avi,mov,mpeg,mpg,wmv,flv,mts}
do
  # Vérifier si le fichier existe
  if [ -f "$fichier" ]; then
    # Créer un répertoire pour stocker les images jpg
    dossier_images="${fichier%.*}_images"
    mkdir "$dossier_images"

    # Conversion du fichier vidéo en séquence d'images .jpg
    ffmpeg -i "$fichier" -q:v 1 "$dossier_images/image_%04d.jpg"

    # Suppression du fichier vidéo (optionnel, à décommenter si nécessaire)
    # rm "$fichier"
  fi
done

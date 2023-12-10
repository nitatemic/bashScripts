#Script qui permet de convertir les fichiers .mts en .mov, de garder les metadatas grâce à ffmpeg

#boucle pour chaque fichier .mts dans le dossier
for fichier in *.MTS
do
  #conversion du fichier .mts en .mov
  ffmpeg -i "$fichier" "${fichier%.mts}.mov"
  #Changer la ModifyDate avec exiftool
  exiftool -tagsFromFile "$fichier" -FileModifyDate "${fichier%.mts}.mov"
  #Suppression du fichier .mts
  rm "$fichier"
done
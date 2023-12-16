#!/bin/bash

# Fonction pour extraire l'ID d'application Steam à partir de l'URL
extractSteamAppID() {
  local url="$1"
  local regex='https%3A%2F%2Fstore\.steampowered\.com%2Fapp%2F([0-9]+)%2F' # Expression régulière pour extraire l'ID

  if [[ $url =~ $regex ]]; then
    echo "${BASH_REMATCH[1]}" # Retourne l'ID correspondant à la capture
  else
    echo "ID non trouvé"
  fi
}

# Fonction pour extraire l'ID à partir d'une requête DuckDuckGo
DuckyExtractID() {
  local recherche="$1"
  local rechercheEncodee=$(echo -n "$recherche" | sed -e 's/ /%20/g') # Encode la valeur pour une URL

  # Crée l'URL de recherche DuckDuckGo avec la requête
  local url="https://duckduckgo.com/?q=!ducky+site:steampowered.com+$rechercheEncodee&t=h_&ia=web"
  echo "URL: $url"

  # Effectue la requête HTTP GET avec curl en suivant les redirections (-L)
  local response=$(curl -s -L "$url")
  local finalURL=$(echo "$response" | awk -F 'uddg=' '{print $2}' | awk -F '&' '{print $1}')
  local steam_app_id=$(extractSteamAppID "$finalURL")
  if [ -n "$steam_app_id" ]; then
    echo "URL finale:$finalURL"
    if [ "$steam_app_id" != "ID non trouvé" ]; then
      echo "ID d'application Steam: $steam_app_id"
    else
      echo "ID Steam non trouvé dans l'URL finale."
    fi
  else
    echo "URL finale non trouvée"
  fi
}

# Vérification du nombre d'arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Nom du jeu>"
    exit 1
fi

# Utilisation de la fonction DuckyExtractID avec l'argument fourni
DuckyExtractID "$1"

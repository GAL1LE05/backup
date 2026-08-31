#!/bin/bash

currentdir="$(pwd)"
tempfile="$currentdir/transfer.tmp"
jsondb="/home/gal/Documents/Repos/backup/games.json"
defaultdir="$(jq -r '.steam_screenshot_folder // empty' "$jsondb")"
outputdir="$(jq -r '.sorted_screenshot_folder // empty' "$jsondb")"

exitfn () {
  exitcode=$?
  echo $exitcode
}

query_steamcmd () {
  app_id="${1}"
  app_info="$(steamcmd +app_info_print "$app_id" +quit | grep "name")"
  nameline="${app_info%%$'"\n'*}"
  gamename="${nameline##*\"}"
  jq --arg id "$app_id" --arg name "$gamename" '.apps.[$id].name = $name | .apps.[$id].vendor = "Steam"' \
   "$jsondb" > "$tempfile" && mv "$tempfile" "$jsondb"
  echo "$gamename"
}

sort_folder () {
  for filepath in "${1}"/*
  do
    filename=${filepath##*/}
    app_id="${filename%%_*}"
    echo "Checking local database for $app_id."
    gamename="$(jq -r --arg id "$app_id" '.apps.[$id].name // empty' "$jsondb")"
    if [ -z "$gamename" ]; then
      echo "The game isn't in the local database."
      echo "Querying SteamCMD for $app_id."
      steamgamename="$(query_steamcmd "$app_id")"
      echo "$app_id is $steamgamename."
    else
      echo "The game $app_id is $gamename."
    fi
  done
}

if [ -z "$1" ]; then
  if [ -z "$defaultdir" ]; then
    echo "Steam screenshot folder not set. Please do so using --set-dir \"/path/to/dir\" (without a trailing /)."
    echo "For more information and other options, use -h or --help."
    exit 9
  elif [ -z "$defaultdir" ]; then
    echo "Desired output folder not set. Please do so using --set-output-dir \"/path/to/dir\" (without a trailing /)."
    echo "For more information and other options, use -h or --help."
    exit 9
  fi
  echo "Sorting through the default Steam screenshots folder: ${defaultdir}. Output folder is ${outputdir}"
  echo ""
  sort_folder "${defaultdir}"
elif [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "set-defaults <key> <value>  Specify a game to be backed up and synchronized." | sed 's/^/  /'
  echo "							              The game's exact folder name must be provided" | sed 's/^/  /'
  echo
  echo "-a, --all                   Sync all games' save files with the remote." | sed 's/^/  /'
  echo "-d, --dir <path>            Specify a different folder containing the game's savefolder" | sed 's/^/  /'
  exit 0
fi

trap exitfn EXIT

# todo: define error codes specific to this scrip and catch error codes to give user-friendly message
# todo: include a check for if the dependencies are installed: jq, steamcmd
# todo: finish help information
# todo: handle setting up default directories and decide what directory to place
# todo: allow for one-time custom directories to be fed
# todo: allow for user to specify game metadata when steamcmd fails or when it's a sideloaded game
# todo: maybe switch from steamcmd to some steam api if it exists and can be used without api key preferrably
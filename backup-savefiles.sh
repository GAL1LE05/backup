#!/bin/bash

COMMAND="${1,,}" #first command

#command with no arguments
if [ -z "$1" ]; then
    echo "Backing up all SaveGames subfolders to Proton Drive." | sed 's/^/  /'
    echo "You can provide arguments to specify a single game to back up."
    echo "See backup-savefiles -h or --help for more details."
    echo "Do you want to proceed with backing up all subfolders? Y/n"
    read CONFIRMATION
    if [ "$CONFIRMATION" == "y" ]; then
    	echo "Proceeding..."
    else
    	echo "Aborting."
    	exit 1
    fi
fi

if [ "$1" == "-h" || "$1" == --help ]; then
    echo "-g, --game <game name>    Specify a game to be backed up and synchronized." | sed 's/^/  /'
    echo "							The game's exact folder name must be provided" | sed 's/^/  /'
    echo
    echo "-d, --dir <path>          Specify a different folder containing the game's savefolder" | sed 's/^/  /'
    echo
    exit 1
fi

if [[ "$COMMAND" == "s" || "$COMMAND" == "set" ]]; then

    if [ -z "$2" ]; then
        echo "Usage: rice $COMMAND <name> [-n]"
        exit 1
    fi

    RICE_NAME="${2,,}"

    if [[ "${3,,}" == "-n" || "${3,,}" == "--no-konsole" ]]; then
        OPEN_KONSOLE=false
    else
        OPEN_KONSOLE=true
    fi

    RICE="$HOME/Rices/$RICE_NAME"

    if [ ! -d "$RICE" ]; then
    echo "Rice '$RICE_NAME' does not exist."
    exit 1
    fi


datetime=`date '+%Y_%m_%d__%H_%M_%S'`
protondir="/home/gal/Applications/Proton Drive"
localdir="/home/gal/Documents/Savegames"
clouddir="/my-files/Chimaera Backups/Savegames"
counter=0


exitfn () {
  trap SIGINT            # Restore signal handling for SIGINT.
  echo; echo "Synced ${counter} directories. Process interrupted by user..." >> "${protondir}/logs/uploads_${datetime}.log"
  exit                   #   then exit script.
}

trap "exitfn" INT

cd $localdir

for dir in $localdir/*/     # list directories in the form "/path/to/localdir/dirname/"
do
    dir=${dir%*/}      # remove the trailing "/"
    dirname="${dir##*/}"    # print everything after the final "/"
    cloudfolderinfo="$("${protondir}/proton-drive" filesystem info "${clouddir}/${dirname}")"
    if [ -z "${cloudfolderinfo}" ]; then
        echo "Creating folder ${dirname}..." >> "${protondir}/logs/uploads_${datetime}.log"
        "${protondir}/proton-drive" filesystem create-folder "${clouddir}" "${dirname}" &>> "${protondir}/logs/uploads_${datetime}.log"
    else 
        echo "Remote folder ${dirname} already exists..." >> "${protondir}/logs/uploads_${datetime}.log"
    fi
    echo "Syncing save files for ${dirname}..." >> "${protondir}/logs/uploads_${datetime}.log"
    find -L "./${dirname}" -type f -exec "${protondir}"/check_sync.sh '{}' \;
    echo "${dirname} sync finished." >> "${protondir}/logs/uploads_${datetime}.log"
    counter=$((counter + 1))
    "${protondir}/proton-drive" filesystem empty-trash
done
echo "Synced ${counter} directories. Process exiting..." >> "${protondir}/logs/uploads_${datetime}.log"
exit

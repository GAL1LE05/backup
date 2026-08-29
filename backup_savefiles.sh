#!/bin/bash

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

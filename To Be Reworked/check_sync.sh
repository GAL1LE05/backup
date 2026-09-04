#!/bin/bash

datetime=`date '+%Y_%m_%d %H_%M_%S'`
protondir="/home/gal/Applications/Proton Drive"
localdir="/home/gal/Documents/Savegames"
clouddir="/my-files/Chimaera Backups/Savegames"

foundfile=$1
dirname=`dirname "$foundfile"`
dirname=${dirname:2}
gamename=${dirname%%/*}
file=${foundfile##*/}

#echo "$foundfile"
#echo "$dirname"
#echo "$gamename"
#echo "$file"

if [ -L "${foundfile}" ]; then
    foundfile=$(realpath "$foundfile")
fi

if [ "$gamename" == "Kenshi" ]; then
    exit
elif [[ "$gamename" == *"Witcher"* ]]; then
    exit
fi

echo "${datetime} - Checking local ${file} against remote" >> "${protondir}/logs/sync_${gamename}.log"	
localversion=`date -r "$foundfile" --utc '+%FT%T.%3NZ'`
remoteinfo="$("${protondir}/proton-drive" filesystem info --json "${clouddir}/${dirname}/${file}")"

if [ -z "$remoteinfo" ]; then
    echo "${datetime} - File ${file} not found on remote. Uploading..." >> "${protondir}/logs/sync_${gamename}.log"
    "${protondir}/proton-drive" filesystem upload -d merge "${foundfile}" "${clouddir}/${dirname}" &>> "${protondir}/logs/sync_${gamename}.log"
    exit
fi
remoteversion=$(echo ${remoteinfo} | jq -r .activeRevision.value.claimedModificationTime)

echo "${file}"
echo "Local: ${localversion} \n Remote: ${remoteversion}"

if [ "${localversion}" != "${remoteversion}" ]; then
    echo "${datetime} - Local version (${localversion}) of ${foundfile} is more recent than remote (${remoteversion}). Overwriting outdated remote file..." >> "${protondir}/logs/sync_${gamename}.log"
    "${protondir}/proton-drive" filesystem upload -d merge -f replace "${foundfile}" "${clouddir}/${dirname}" &>> "${protondir}/logs/sync_${gamename}.log"
else
    echo "${datetime} - Remote is already up to date" >> "${protondir}/logs/sync_${gamename}.log"	
fi


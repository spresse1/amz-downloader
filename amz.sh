#!/bin/bash

set -e #exiton first non-zero exit code

PARALLEL="" #we'll put arguments related to parallel fetch here
GUESSNAMES=0
DEST=. #where we put files.  Only ever used with --guess-names, set by --dest
if [ $# -eq 0 ] ; then
    echo Usage: $0 [-p] [--guess-names] [--dest folder] ".amz file"
    echo  -p   Download in parallel
    echo  --guess-names  Attempt to guess the names for files.  This implies
    echo                 creating and placcing them in a directory tree in the
    echo                 form artist/album/trackno song.mp3
    echo  --dest=folder  Downloads files to the folder named.  If used with 
    echo                 --guess-names is the root of the file tree.  Defaults
    echo                 to the curent directory
    exit 1
else
    while [ -n "$1" ]; do
        ARG=$1 #hols the most recent argument (last after the loop ends
        if [ $ARG == "-p" ] ; then
            PARALLEL=" -b -o /dev/null " # the command line options we add for parallel
        elif [ $ARG == "--guess-names" ];then
            GUESSNAMES=1
        elif [ $ARG == "--dest" ]; then
            shift
            DEST=$1
        fi
        shift
    done
fi
echo $ARG

which wget > /dev/null
if [ $? -ne 0 ]; then
    echo Please install wget.
    exit 1
fi

while read line; do
    if [ "`echo $line | grep \"<track>\"`" ]; then
        # new track record, wipe (and init) variables
        LOCATION=""
        ARTIST=""
        ALBUM=""
        TITLE=""
        NUMBER=""
    elif [ "`echo $line | grep '<location'`" ]; then
        LOCATION="`echo $line | sed 's/.*<location>//' | sed 's/<\/location.*//'`"
    elif [ "`echo $line | grep '<album'`" ]; then
       ALBUM=`echo "$line" | sed 's/.*<album>//' | sed 's/<\/album.*//'`
    elif [ "`echo $line | grep '<creator'`" ]; then
       ARTIST="`echo $line | sed 's/.*<creator>//' | sed 's/<\/creator.*//'`"
    elif [ "`echo $line | grep '<title'`" ]; then
       TITLE="`echo $line | sed 's/.*<title>//' | sed 's/<\/title.*//'`"
    elif [ "`echo $line | grep '<trackNum'`" ]; then
       NUMBER="`echo $line | sed 's/.*<trackNum>//' | sed 's/<\/trackNum.*//'` " #include a space so if we never find a number we don't end up with odd filenames
    elif [ `echo $line | grep "</track>"` ]; then
        if [ "$LOCATION" ]; then # -a ( $GUESSNAMES -ne 1 -o ( -n "${TITLE}" -a -n "$ARTIST" -a -n "$ALBUM" ) ) ]; then
            # Whatever, if we found where to download it from we probably got the rest
            echo "Fetching track ${NUMBER}($TITLE) by $ARTIST on $ALBUM to $DEST"
            if [ $GUESSNAMES -eq 1 ]; then
                OUTPUT="-O${DEST}/${ARTIST}/${ALBUM}/${NUMBER}${TITLE}.mp3"
                mkdir -p "${DEST}/${ARTIST}/${ALBUM}/" #ensure destination exists
            fi #blank otherwise so wget just picks its own name
            wget $PARALLEL "$OUTPUT" "$LOCATION"
        else
            echo "Insuffiecnt input detail or failure to parse.  We got:"
            echo "Location: ${LOCATION}"
            echo "Artist: $ARTIST"
            echo "Album: $ALBUM"
            echo "Track title: $TITLE"
            echo "Track number: $NUMBER"
            echo "Guess names: $GUESSNAMES (if 1, enabled)"
            echo "Must always have location.  if --guess-names must also have artist, album, and title"
        fi
    fi
done < $ARG #this bit actually feeds the file in..




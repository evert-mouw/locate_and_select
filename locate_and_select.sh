#!/bin/bash

# pipe the results of locate to fzf or rofi
# and open the selection in a file manager
# evert mouw, 2021-10-16

# dependencies: fzf, rofi, mlocate, xhost
# optional: mc, ranger, nemo, nautilus, thunar, exo-open

FZFCOLORS="dark,hl:#FF5555"
ROFITHEME="purple"
LOCATEOPTIONS="--all --ignore-case"

# try one of these filemanagers
# not all filemanagers support opening a directory with a file selected
# for XFCE/Thunar, the exo-open command is best, (g)dbus is another option
#FILEMANAGER="nemo --no-desktop"
#FILEMANAGER="nautilus --no-desktop"
FILEMANAGER="exo-open --launch FileManager"

# when using without X, try this CLI file manager
# (only sending the directory, not the file)
#CLIFM="ranger"
CLIFM="mc"

# -------------------------------

# get search terms
if [[ $1 == "" ]]
then
	MSG="Enter your search terms"
	if xhost >& /dev/null
		then
		#SEARCH=$(zenity --entry \
		#	--title="File Search" \
		#	--text="$MSG" \
		#	--icon-name="edit-find")
		SEARCH=$(rofi -dmenu -theme $ROFITHEME -p "$MSG")
	else
		echo "$MSG"
		read SEARCH
	fi
else
	SEARCH=${@}
fi
if [[ "$SEARCH" == "" ]]
	then
	echo "No search terms given."
	exit
fi

# locate them
RESULTS=$(locate $LOCATEOPTIONS $SEARCH)

# remove empty lines; count lines
RESULTS=$(echo "$RESULTS" | sed '/^$/d')
LINECOUNT=$(echo "$RESULTS" | wc --lines) 

# if no results, just exit
if [[ $LINECOUNT -lt 2 && $RESULTS == "" ]]
then
	MSG="No hits for: $SEARCH"
	if xhost >& /dev/null
	then
		#zenity --error --title="File Search" --text="$MSG"
		echo "$MSG" | rofi -dmenu -theme $ROFITHEME -p "$MSG"
	else
		echo "$MSG"
	fi
	exit
fi

# feed the results to fzf or rofi
# then get the user selection
# and open it in the file manager
if xhost >& /dev/null
	then
	ROFIMAGIC="rofi -dmenu -i
		-window-title 'File Search'
		-normal-window
		-theme $ROFITHEME
		-theme-str 'window {height: 80%; width: 90%;}'"
	SELECTION=$(echo "$RESULTS" | eval $ROFIMAGIC)
else
	FZFMAGIC="fzf --no-sort
		--color=$FZFCOLORS
		--exact
		--query='$SEARCH'"
	SELECTION=$(echo "$RESULTS" | eval $FZFMAGIC)
fi

if [[ $SELECTION = "" ]]
then
		echo "No file selected."
else
		if xhost >& /dev/null
		then
			echo "Opening in file manager:"
			echo "$SELECTION"
			$FILEMANAGER "$SELECTION"
		else
			# No X detected, so not starting a GUI file manager.
			# Instead, try to open the directory using Midnight Commander.
			DIR=$(dirname "$SELECTION")
			$CLIFM "$DIR"
			echo "$SELECTION"
		fi
fi

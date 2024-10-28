#!/bin/bash
app="${1}"

function sendMusicStatus() {
	title=$(rhythmbox-client --print-playing)
	if [ "$title" == " - " ]; then
		return
	fi

	length=$(gdbus call --session --dest=org.mpris.MediaPlayer2.rhythmbox \
		--object-path /org/mpris/MediaPlayer2 \
		--method org.freedesktop.DBus.Properties.Get \
		org.mpris.MediaPlayer2.Player Metadata | \
		sed -n "s/.*'mpris:length': <int64 \([0-9]*\)>.*/\1/p")

	if [ -z "$length" ] || ! [[ "$length" =~ ^[0-9]+$ ]]; then
		length_sec=$(echo "(2*60) -1" | bc)
	else
		length_sec=$(echo "($length / 1000000) -1" | bc)
	fi

	title_enc=$(echo $title | jq -Rr '@uri')

	expiration=$(date -d "+${length_sec} seconds" +%s)

	if [ "${app}" == "algia" ]; then
		algia event --kind 30315 --content "♫ $title ($length seconds)" --tag d=music --tag expiration="$expiration" --tag r="spotify:search:$title_enc"
	fi
}

export -f sendMusicStatus

# dbus-monitor でイベント監視
dbus-monitor --session "path=/org/mpris/MediaPlayer2,member=PropertiesChanged" --monitor |\
	stdbuf -i0 -oL grep PlaybackStatus |\
	xargs -i{} bash -c sendMusicStatus


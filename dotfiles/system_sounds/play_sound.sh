#!/usr/bin/env bash
# Play a sound from /home/jbxoid/.config/system_sounds
SOUND_NAME="$1"
SOUND_DIR="/home/jbxoid/.config/system_sounds"
AUDIO_PLAYER="pw-play"

if [ -z "$SOUND_NAME" ]; then
    echo "Usage: $0 <sound_name>" >&2
    exit 1
fi

SOUND_FILE=""
for ext in ogg wav mp3 flac; do
    if [ -f "$SOUND_DIR/$SOUND_NAME.$ext" ]; then
        SOUND_FILE="$SOUND_DIR/$SOUND_NAME.$ext"
        break
    fi
done

if [ -z "$SOUND_FILE" ]; then
    echo "Sound file not found: $SOUND_DIR/$SOUND_NAME.*" >&2
    exit 1
fi

exec $AUDIO_PLAYER "$SOUND_FILE"

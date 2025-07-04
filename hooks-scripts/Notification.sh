#!/bin/bash

# Notification フック用音声再生
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/play-voice.sh" "Notification"
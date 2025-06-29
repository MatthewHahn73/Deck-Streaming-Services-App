#!/bin/sh
echo -ne '\033c\033]0;Steam Deck Streaming\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Streaming Services App.x86_64" "$@"

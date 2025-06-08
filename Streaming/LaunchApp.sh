#!/bin/bash
# Streaming App Links (For reference)
    # Prime - https://www.amazon.com/video
    # Youtube - https://www.youtube.com/
    # Netflix - https://www.netflix.com/
    # HBO - https://www.max.com/ 
    # Apple TV - https://tv.apple.com/

LINK="$1"
DIR=$(pwd)
source ${DIR}/Streaming/Config/Streaming.conf
"/usr/bin/flatpak" run ${FLATPAKOPTIONS} ${BROWSERAPP} @@u @@ ${BROWSEROPTIONS} ${LINK}

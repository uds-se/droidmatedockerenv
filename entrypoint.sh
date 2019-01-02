#!/bin/bash

# Just to make sure there is no adb server running, actually this should never be the case
adb kill-server >/dev/null 2>&1
# Provide -P <PORT> option, if yout want to specify the port
# Standard port is 5037
# Seems a little bit hacky, but it was the only way I found getting the adb server listening
# to remote connects
adb -a nodaemon server >/dev/null 2>&1 &
${ANDROID_EMULATOR} -avd ${NAME} ${START_UP_PARAMETERS}
#!/bin/bash

apt-get update && apt-get install -y git-all

sdkmanager "system-images;android-24;google_apis;x86_64"
# sdkmanager "system-images;android-23;google_apis;x86_64"
# sdkmanager "system-images;android-24;google_apis;armeabi-v7a"
# sdkmanager "system-images;android-23;google_apis;armeabi-v7a"

avdmanager create avd -n "droidmate_nexus5_24_gapps_x86-64" -k "system-images;android-24;google_apis;x86_64" -d "Nexus 5"
# avdmanager create avd -n "droidmate_nexus5_23_gapps_x86-64" -k "system-images;android-23;google_apis;x86_64" -d "Nexus 5"
# avdmanager create avd -n "droidmate_nexus5_24_gapps_armeabi-v7a" -k "system-images;android-24;google_apis;armeabi-v7a" -d "Nexus 5"
# avdmanager create avd -n "droidmate_nexus5_23_gapps_armeabi-v7a" -k "system-images;android-23;google_apis;armeabi-v7a" -d "Nexus 5"

# fix problem if run the emulator without -no-window
# export LD_LIBRARY_PATH="/android-sdk/tools/lib:/android-sdk/tools/lib64/:/android-sdk/emulator/lib64/qt/lib"

cd /root/droidmate
if [[ ! -f gradlew ]]; then
    # is not downloaded
    git clone https://github.com/uds-se/droidmate.git
    git checkout dev
fi

./gradlew build
./gradlew shadowJar
cp ./project/pcComponents/API/build/libs/shadow-*.jar .


# fix: Could not launch '/root/droidmate/../emulator/qemu/linux-x86_64/qemu-system-x86_64': No such file or directory
/android-sdk/emulator/emulator64-x86 -avd droidmate_nexus5_24_gapps_x86-64 -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-x86 -avd droidmate_nexus5_23_gapps_x86-64 -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-arm -avd droidmate_nexus5_24_gapps_armeabi-v7a -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-arm -avd droidmate_nexus5_23_gapps_armeabi-v7a -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &

sleep 1m

wget -q https://software.imdea.org/cloud/index.php/s/z7K9ZCrjSo05Jbi/download -O apks/Tippy_1.1.3-debug.apk

# export TIME_TOOL_SEC=60
export TIME_TOOL_SEC=300
args="--Exploration-apksDir=apks"
# args="${args} --Exploration-runOnNotInlined"
# @TODO: pass the path instead of move it
# args="${args} --Output-droidmateOutputDirPath=${tool_output_results}"
args="${args} --Selectors-timeLimit=${TIME_TOOL_SEC}"
# args="${args} --Selectors-resetEvery=100"
# args="${args} --Selectors-actionLimit=1000"
# args="${args} --Selectors-randomSeed=0"

java -jar $(ls shadow-*.jar) ${args} &> out/droidmate.log
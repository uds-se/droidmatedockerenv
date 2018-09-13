#!/bin/bash

# Note: Multiple tagging https://stackoverflow.com/questions/22080706/how-to-create-named-and-latest-tag-in-docker
#IMAGE_ID=$(docker build -q -t farmtesting . 2>/dev/null | awk '/Successfully built/{print $NF}')
#echo ${IMAGE_ID}
docker build -q -t farmtesting:latest . 2>/dev/null
#docker build -t farmtesting --build-arg APK_FOLDER_HOST="/tmp/e20ae504-ec53-452d-9c96-3f99279568d6" .


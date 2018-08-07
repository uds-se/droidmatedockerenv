FROM debian:stretch
# FROM debian:stretch-slim
# => couldn't use stretch-slim because of: `dpkg: dependency problems prevent configuration of ca-certificates-java`

LABEL maintainer "Timo Gühring,svg153"
LABEL version "0.5"
LABEL description "https://github.com/uds-se/droidmate"
# Mostly copied from https://github.com/sweisgerber-dev/android-sdk-ndk

ENV SDK_TOOLS_LINUX_WEB_VERSION="3859397"

ENV ANDROID_SDK_MAX="27"
ENV ANDROID_SDK_MIN="23"
ENV ANDROID_BUILD_TOOLS_LEGACY="26.0.2"
ENV ANDROID_BUILD_TOOLS="27.0.3"
ENV ANDROID_SDK_FOLDER="/android-sdk"
ENV ANDROID_HOME="${ANDROID_SDK_FOLDER}"

# Debian Installation
RUN apt-get update --yes
RUN apt-get install --yes apt-utils
RUN apt-get install --yes \
        wget \
        curl \
        tar \
        unzip \
        lib32stdc++6 \
        lib32z1 \
        openjdk-8-jdk \
        openjdk-8-jre \
        git-all
RUN apt-get upgrade --yes
RUN apt-get dist-upgrade --yes

# Setup Java
RUN update-alternatives --config java

# Install Gnuplot
RUN apt-get update > /dev/null 2>&1 && \
    apt-get install -y gnuplot > /dev/null 2>&1

RUN wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-${SDK_TOOLS_LINUX_WEB_VERSION}.zip
RUN mkdir -p ${HOME}/.android
RUN echo "count=0\n" > ${HOME}/.android/repositories.cfg
RUN mkdir -p ${ANDROID_SDK_FOLDER}
RUN unzip -d ${ANDROID_SDK_FOLDER} -qq android-sdk.zip
RUN rm android-sdk.zip

# SDK Installation
RUN ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager --list || true
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "platform-tools"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "tools"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_LEGACY}"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "platforms;android-27"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "platforms;android-23"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;android;m2repository"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;m2repository"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;google_play_services"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;instantapps"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;market_apk_expansion"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;market_licensing"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;google;webdriver"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN echo yes | ${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager --licenses


ENV ANDROID_HOME="${ANDROID_SDK_FOLDER}"
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"

ENV PATH="$PATH:${ANDROID_HOME}"
ENV PATH="$PATH:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}/"
ENV PATH="$PATH:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_LEGACY}/"
ENV PATH="$PATH:${ANDROID_HOME}/platform-tools/"
ENV PATH="$PATH:${ANDROID_HOME}/tools"
ENV PATH="$PATH:${ANDROID_HOME}/tools/bin"
ENV PATH="$PATH:${JAVA_HOME}"

# fix problem if run the emulator without -no-window
ENV LD_LIBRARY_PATH="${ANDROID_HOME}/tools/lib:${ANDROID_HOME}/tools/lib64/:${ANDROID_HOME}/emulator/lib64/qt/lib"



#
# DroidMate
#

ENV TOOL="DroidMate"
ENV TOOL_REPONAME="droidmate"
ENV TOOL_FOLDERNAME="droidmate"
ENV TOOL_PATH="/root/${TOOL_FOLDERNAME}"
ARG TOOL_COMMIT_DEF="dev"
ENV ENT ./entrypoint.sh

# Clone
RUN URL="https://github.com/uds-se/${TOOL_REPONAME}.git" && \
    git clone ${URL} ${TOOL_PATH} && \
    cd ${TOOL_PATH} && \
    git checkout ${TOOL_COMMIT_DEF} ; \
    fi

# Build
RUN cd ${TOOL_PATH} && \
    chmod +x gradlew && \
    sync && \
    ./gradlew build && \
    ./gradlew shadowJar



#
# Clean
#

RUN apt-get clean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/*
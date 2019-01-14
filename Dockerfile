FROM debian:stretch
# FROM debian:stretch-slim
# => couldn't use stretch-slim because of: `dpkg: dependency problems prevent configuration of ca-certificates-java`

LABEL maintainer "Timo Gühring"
LABEL description="Repository: https://github.com/uds-se/droidmatedockerenv/tree/farmtesting \
for DroidMate-2: https://github.com/uds-se/droidmate"
# Based on a large extent on: https://github.com/sweisgerber-dev/android-sdk-ndk
# Helpful links:
# - https://hub.docker.com/r/thyrlian/android-sdk/

ENV SDK_TOOLS_LINUX_WEB_VERSION="3859397"

ENV ANDROID_SDK_MAX="27"
ENV ANDROID_SDK_MIN="23"
ENV ANDROID_BUILD_TOOLS_LEGACY="26.0.2"
ENV ANDROID_BUILD_TOOLS="27.0.3"
ENV ANDROID_SDK_FOLDER="/android-sdk"
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
# Define some environment variables, some programs require these
ENV ANDROID_HOME="${ANDROID_SDK_FOLDER}"
ENV ANDROID_SDK_HOME="${ANDROID_SDK_FOLDER}"
ENV ANDROID_SDK_ROOT="${ANDROID_SDK_FOLDER}"
ENV ANDROID_SDK_MANAGER="${ANDROID_SDK_FOLDER}/tools/bin/sdkmanager"
ENV ANDROID_AVD_MANAGER="${ANDROID_SDK_FOLDER}/tools/bin/avdmanager"
ENV ANDROID_EMULATOR="${ANDROID_SDK_FOLDER}/emulator/emulator"

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
# Install Python and git for CI
RUN apt-get install --yes python \
        git
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

# Workaround for
# Warning: File /android-sdk/.android/repositories.cfg could not be loaded
RUN mkdir -p /android-sdk/.android \
        && touch /android-sdk/.android/repositories.cfg

# SDK Installation
RUN ${ANDROID_SDK_MANAGER} --list || true
RUN echo yes | ${ANDROID_SDK_MANAGER} "platform-tools"
RUN echo yes | ${ANDROID_SDK_MANAGER} "tools"
RUN echo yes | ${ANDROID_SDK_MANAGER} "build-tools;${ANDROID_BUILD_TOOLS}"
RUN echo yes | ${ANDROID_SDK_MANAGER} "build-tools;${ANDROID_BUILD_TOOLS_LEGACY}"
RUN echo yes | ${ANDROID_SDK_MANAGER} "platforms;android-${ANDROID_SDK_MIN}"
RUN echo yes | ${ANDROID_SDK_MANAGER} "platforms;android-${ANDROID_SDK_MAX}"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;android;m2repository"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;m2repository"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;google_play_services"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;instantapps"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;market_apk_expansion"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;market_licensing"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;google;webdriver"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2"
RUN echo yes | ${ANDROID_SDK_MANAGER} "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"
RUN echo yes | ${ANDROID_SDK_MANAGER} --licenses

# Copy adb key
ARG ADB_KEYS_PATH="./androidfiles"
COPY ${ADB_KEYS_PATH}/adbkey /root/.android/
COPY ${ADB_KEYS_PATH}/adbkey.pub /root/.android/

ENV PATH="$PATH:${ANDROID_HOME}"
ENV PATH="$PATH:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS}/"
ENV PATH="$PATH:${ANDROID_HOME}/build-tools/${ANDROID_BUILD_TOOLS_LEGACY}/"
ENV PATH="$PATH:${ANDROID_HOME}/platform-tools/"
ENV PATH="$PATH:${ANDROID_HOME}/tools"
ENV PATH="$PATH:${ANDROID_HOME}/tools/bin"
ENV PATH="$PATH:${JAVA_HOME}"

# Clean
RUN apt-get clean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/*

# Process dependencies
ARG SETUP_PARAMETERS="[ ]"
COPY ./processSetupParameters.sh /
RUN chmod +x ./processSetupParameters.sh
RUN ./processSetupParameters.sh ${SETUP_PARAMETERS}

ARG TOOL_COMMIT_DEF="dev"
ARG GIT_REPOSITORY="https://github.com/uds-se/droidmate.git"
ARG TOOL_FOLDERNAME="droidmate"
ENV TOOL_FOLDERNAME_ENV=${TOOL_FOLDERNAME}
ENV TOOL_PATH="/root/${TOOL_FOLDERNAME_ENV}"

# Clone
RUN git clone ${GIT_REPOSITORY} ${TOOL_PATH} && \
    cd ${TOOL_PATH} && \
    git checkout ${TOOL_COMMIT_DEF}

# Build
RUN cd ${TOOL_PATH} && \
    chmod +x gradlew && \
    sync && \
    ./gradlew build -x test

# Prepare resources
ENV TOOL_OUTPUT_FOLDER="/root/output"
RUN mkdir ${TOOL_OUTPUT_FOLDER}
ENV APK_FOLDER_CONTAINER="/root/apks"
RUN mkdir ${APK_FOLDER_CONTAINER}
COPY ./runTest.sh /
RUN chmod +x ./runTest.sh

ENTRYPOINT ["./runTest.sh"]

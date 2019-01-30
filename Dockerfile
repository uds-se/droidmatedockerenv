FROM debian:stretch
# FROM debian:stretch-slim
# => couldn't use stretch-slim because of: `dpkg: dependency problems prevent configuration of ca-certificates-java`

LABEL maintainer "Timo Gühring"
# Based on a large extent on: https://github.com/sweisgerber-dev/android-sdk-ndk
# Helpful links:
# https://hub.docker.com/r/thyrlian/android-sdk/

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
# Android 6.0 and 6.0.1 API 23
RUN echo yes | ${ANDROID_SDK_MANAGER} "system-images;android-23;google_apis;x86"
# Android 7.0 API 24
RUN echo yes | ${ANDROID_SDK_MANAGER} "system-images;android-24;google_apis;x86"
# Android 8.1 API 27
RUN echo yes | ${ANDROID_SDK_MANAGER} "system-images;android-27;google_apis;x86"
RUN echo yes | ${ANDROID_SDK_MANAGER} --licenses

# Copy adb key
COPY ./androidfiles/ /root/.android/

# Clean
RUN apt-get clean
RUN apt-get autoremove
RUN rm -rf /var/lib/apt/lists/*

ENV PATH="$PATH:${ANDROID_HOME}"
ENV PATH="$PATH:${ANDROID_HOME}/platform-tools/"
ENV PATH="$PATH:${ANDROID_HOME}/tools"
ENV PATH="$PATH:${JAVA_HOME}"

# Expose adb server port
EXPOSE 5037
EXPOSE 5554
EXPOSE 5555

# Create emulator
ARG SYSTEM_IMAGE="system-images;android-23;google_apis;x86"
ARG SD_CARD_SIZE="1200"
ARG START_UP_PARAMETERS="-no-boot-anim -no-window -no-audio -gpu off -no-snapshot-save -wipe-data"
ARG NAME="emu"

ENV ENV_SYSTEM_IMAGE=${SYSTEM_IMAGE}
ENV ENV_SD_CARD_SIZE=${SD_CARD_SIZE}
ENV ENV_START_UP_PARAMETERS=${START_UP_PARAMETERS}
ENV ENV_NAME=${NAME}

RUN echo no | ${ANDROID_AVD_MANAGER} create avd -n ${ENV_NAME} -k "${ENV_SYSTEM_IMAGE}" -c ${ENV_SD_CARD_SIZE}M

# Workaround for PANIC: Broken AVD system path. Check your ANDROID_SDK_ROOT value [/android-sdk]!
RUN mkdir ${ANDROID_HOME}/platforms

COPY ./entrypoint.sh /
RUN chmod +x ./entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

# DroidMate Docker CI environment [![Docker Hub](https://img.shields.io/badge/Docker%20Hub-info-blue.svg)](https://hub.docker.com/r/timoguehring/droidmatedockerenv/) [![Build Status](https://travis-ci.com/JeannedArk/droidmatedockerenv.svg?branch=farmtesting)](https://travis-ci.com/JeannedArk/droidmatedockerenv)
[DroidMate](https://github.com/uds-se/droidmate) Docker setup for CI providing an environment with JDK8, Android SDK and Android platform tools.

### Docker CE

Install Docker CE from the official Docker Website:

* [Ubuntu](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)
* [Debian](https://docs.docker.com/engine/installation/linux/docker-ce/debian/)

Tested with `Docker version 17.03.2-ce, build f5ec1e2`.

#### Post-installation of Docker

It is desireable to setup Docker to be able to run as non-root. To do that, execute the next commands:

```shell
sudo groupadd docker
sudo usermod -aG docker $ USER
```

Restart the computer so that your group membership is re-evaluated, and be sure you can run docker commands without sudo. You can test this by executing:

```shell
docker run hello-world
```
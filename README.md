# DroidMate Docker environment
Docker setup for DroidMate (https://github.com/uds-se/droidmate) using JDK8, Android SDK, and Android platform tools.

## Requirements

### Operating System

Working on:

* Debian 9.4 (stretch)

Tested on:

* Debian 9 -> Debian 9.4 (stretch)

Did not work on:

* Windows: bash scripts.

Not tested:

* Mac: ??

### Other

* Bash shell
* Git
* CE Docker
    * Ours version: 18.03.1-ce (Client and Server)
    * All the test: 18.03.0-ce (Client and Server), build 0520e24
    * Tested on:
        * 18.03.1-ce (Client and Server)
        * 18.03.0-ce (Client and Server)

### Docker CE

Install Docker CE from the official Docker Website:

* [Ubuntu](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/)
* [Debian](https://docs.docker.com/engine/installation/linux/docker-ce/debian/)

#### Post-installation of Docker

After installing Docker in your system, it will only run if the user logs as root.
To manage Docker as a non-root user, type the next commands:

```shell
sudo groupadd docker
sudo usermod -aG docker $ USER
```

Restart the computer so that your group membership is re-evaluated, and be sure
you can run docker commands without sudo.

```shell
docker run hello-world
```

## Run

Duplicate the [`run.properties.template`](run.properties.template) file, rename to [` run.properties`](run.properties) and edit as you want. To edit follow the info inside.

> NOTE:
> Force update a branch when the container is built:
> - 1st option: Remove all containers, and run again. This rebuilds everything from scratch, but take a lot of time.
> - 2nd option: Edit the run.properties and change the `TOOL_COMMIT`, with the SHA commit that you want your run. This rebuilds the container, form that point. Take less time.
> - 3rd option: Edit the run.properties and change the `share_droidmate_flag = 1`, to share your local DroidMate (have to be in this folder with" droidmate "folder name) with the container. This does not rebuild the container. This is immediate.

### DroidMate configuration

#### Default: [`args.txt.default`](args.txt.default)

This file has the default options to run DroidMate as you run DroidMate `.jar` file by command line interface.

Before running, we add the `--Selectors-timeLimit` (in milliseconds) option with the time in the var` TIME_TOOL_SEC` (in seconds, for better manages.We convert in milliseconds before running) in the `run.properties` file.

#### Custom

##### [`args.txt`](args.txt)

This [`args.txt`](args.txt) is the same as [` args.txt.default`](args.txt.default) file, but with your personal configuration

For example:

```bash
$ cat args.txt
--Exploration-apksDir = apks --Exploration-deviceIndex = 0 --Selectors-timeLimit = 60000 - Strategies-dfs = false
```

##### [`config.properties`](config.properties)

Duplicate the [`config.properties.template`](config.properties.template) file, rename to [`config.properties`](config.properties) and edit as you want.

This [`config.properties`](config.properties) has the same structure as [`defaultConfig.properties`](https://github.com/uds-se/droidmate/project/pcComponents/core/src/main/resources/defaultConfig.properties)

Change the vars that you want to run DroidMate.

For example:

```bash
$ cat config.properties
# Selectors.timeLimit time to run DroidMate in mileconds (0 == no limit)
# Selectors.timeLimit = 0 # def
Exploration.apksDir =. / Apks
Exploration.deviceIndex = 0
Selectors.timeLimit = 60000
Strategies.dfs = false
```
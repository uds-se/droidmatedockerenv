# DroidMate Docker environment
Docker setup for DroidMate (https://github.com/uds-se/droidmate) using JDK8, Android SDK and Android platform tools.

## Build and run


### [`config.properties.template`](config.properties.template)
This [`config.properties.template`](config.properties.template) is the same as [`defaultConfig.properties`](https://github.com/uds-se/droidmate/project/pcComponents/core/src/main/resources/defaultConfig.properties)
Duplicate [`config.properties.template`](config.properties.template) and rename to `config.properties`.
Change the vars that you want to run DroidMate.

```text
$ cat config.properties
# Selectors.timeLimit=0 # def
Selectors.timeLimit=60
```
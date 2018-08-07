
# DroidMate Docker container 

## From the host (tested on Ubuntu 16.04.1)

### Download and run DroidMate container

DroidMate repo: [uds-se/droidmate](https://github.com/uds-se/droidmate)
DroidMate docker image:
* Github: [JeannedArk/droidmatedockerenv](https://github.com/JeannedArk/droidmatedockerenv)
* Dockerhub: [timoguehring/droidmatedockerenv:latest](https://hub.docker.com/r/timoguehring/droidmatedockerenv/)

Copy and paste into a terminal
```shell
docker run -it -e DISPLAY=${DISPLAY} --device="/dev/dri/card0:/dev/dri/card0" -v /tmp/.X11-unix:/tmp/.X11-unix:rw -e XAUTHORITY=/tmp/.docker.xauth -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw  --privileged -v /dev/kvm:/dev/kvm:rw -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock:ro '-lxc-conf=lxc.cgroup.devices.allow = c 226:* rwm' -v `pwd`:/root/project timoguehring/droidmatedockerenv:latest /bin/bash
```

### TL;DR
1. [OPTIONAL] Install `vim` (emacs is installed):
```bash
apt-get update && apt-get install -y vim
```

2. Create a script inside the DroidMate docker container:

```bash
emacs run.sh
```

3. Paste this inside:

```bash

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
export LD_LIBRARY_PATH="/android-sdk/tools/lib:/android-sdk/tools/lib64/:/android-sdk/emulator/lib64/qt/lib"

cd /root
git clone https://github.com/uds-se/droidmate.git
cd droidmate
git checkout dev

./gradlew build
./gradlew shadowJar
cp ./project/pcComponents/API/build/libs/shadow-*.jar .


# fix: Could not launch '/root/droidmate/../emulator/qemu/linux-x86_64/qemu-system-x86_64': No such file or directory
/android-sdk/emulator/emulator64-x86 -avd droidmate_nexus5_24_gapps_x86-64 -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-x86 -avd droidmate_nexus5_23_gapps_x86-64 -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-arm -avd droidmate_nexus5_24_gapps_armeabi-v7a -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
# /android-sdk/emulator/emulator64-arm -avd droidmate_nexus5_23_gapps_armeabi-v7a -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &


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

java -jar $(ls shadow-*.jar) ${args}
```

4. Run:
```bash
chmod +x run.sh
./run.sh
```



### Inside the container

1. update and install git

```bash
apt-get update && apt-get install -y git-all
```

2. Install `x86_64` sdk package

```bash
sdkmanager "system-images;android-24;google_apis;x86_64"
```

3. Create avd

```bash
avdmanager create avd -n "droidmate_nexus5_24_gapps_x86-64" -k "system-images;android-24;google_apis;x86_64" -d "Nexus 5"
```

4. Clone DroidMate

```bash
cd /root
git clone https://github.com/uds-se/droidmate.git
cd droidmate
git checkout dev
```

5. Build DroidMate

```bash
./gradlew build
./gradlew shadowJar
```

6. Copy the `.jar` into the main DroidMate folder

```bash
cp ./project/pcComponents/API/build/libs/shadow-*.jar .
```

7. Run Android emulator
> fix: Could not launch '/root/droidmate/../emulator/qemu/linux-x86_64/qemu-system-x86_64': No such file or directory
> fix problem if run the emulator without -no-window
```bash
export LD_LIBRARY_PATH="/android-sdk/tools/lib:/android-sdk/tools/lib64/:/android-sdk/emulator/lib64/qt/lib"
```
Run:
```bash
/android-sdk/emulator/emulator64-x86 -avd droidmate_nexus5_24_gapps_x86-64 -no-boot-anim -no-window -no-audio -gpu off -skin "1080x1920" &
```


7. Copy the `.apk` into the `droidmate/apks` DroidMate folder. We download `Tippy_1.1.3-debug.apk` to test.

```bash
wget -q https://software.imdea.org/cloud/index.php/s/z7K9ZCrjSo05Jbi/download -O apks/Tippy_1.1.3-debug.apk
```

8. Set DroidMate args.

```bash
export TIME_TOOL_SEC=60
args="--Exploration-apksDir=apks"
# args="${args} --Exploration-runOnNotInlined"
# @TODO: pass the path instead of move it
# args="${args} --Output-droidmateOutputDirPath=${tool_output_results}"
args="${args} --Selectors-timeLimit=${TIME_TOOL_SEC}"
# args="${args} --Selectors-resetEvery=100"
# args="${args} --Selectors-actionLimit=1000"
# args="${args} --Selectors-randomSeed=0"
```

9. Run DroidMate

```bash
java -jar $(ls shadow-*.jar) ${args}
```

### Error trace

```log
email: jamrozik@st.cs.uni-saarland.de
web: www.droidmate.org
2018-07-19 14:21:03.102 INFO  org.droidmate.frontend.DroidmateFrontend Bootstrapping DroidMate: building ConfigurationWrapper from args and instantiating objects for DroidmateCommand.
2018-07-19 14:21:03.103 INFO  org.droidmate.frontend.DroidmateFrontend IMPORTANT: for help on how to configure DroidMate, run it with -help
2018-07-19 14:21:03.103 INFO  org.droidmate.frontend.DroidmateFrontend IMPORTANT: for detailed logs from DroidMate run, please see ./out/droidMate/logs.
2018-07-19 14:21:03.203 INFO  org.droidmate.frontend.DroidmateFrontend Successfully instantiated ExploreCommand. Welcome to DroidMate. Lie back, relax and enjoy.
2018-07-19 14:21:03.206 INFO  org.droidmate.frontend.DroidmateFrontend Run start timestamp: Thu Jul 19 14:21:03 UTC 2018
2018-07-19 14:21:03.207 INFO  org.droidmate.frontend.DroidmateFrontend Running in Android 23 compatibility mode (api23+ = version 6.0 or newer).
2018-07-19 14:21:03.213 INFO  org.droidmate.tools.ApksProvider         Reading input apks from /root/droidmate/apks
2018-07-19 14:21:03.299 INFO  org.droidmate.tools.ApksProvider         Following input apk is not inlined: alogcat-debug.apk
2018-07-19 14:21:03.300 INFO  org.droidmate.command.ExploreCommand     Not inlined input apks have been detected, but DroidMate was instructed to run anyway. Continuing with execution.
2018-07-19 14:21:03.323 INFO  o.droidmate.tools.AndroidDeviceDeployer  Setup device with deviceSerialNumber of emulator-5554
2018-07-19 14:21:03.358 INFO  org.droidmate.device.AndroidDevice       Using port.tmp located at /tmp/port.tmp5743455394960054937.tmp
2018-07-19 14:21:07.179 INFO  org.droidmate.command.ExploreCommand     Processing 1 out of 1 apks: alogcat-debug.apk
2018-07-19 14:21:07.180 INFO  org.droidmate.tools.ApkDeployer          Reinstalling alogcat-debug.apk
2018-07-19 14:21:07.648 INFO  org.droidmate.command.ExploreCommand     run(org.jtb.alogcat, device)
2018-07-19 14:21:08.705 INFO  o.d.e.strategy.ExplorationStrategyPool   Registering strategy org.droidmate.exploration.strategy.Back@41382722.
2018-07-19 14:21:08.706 INFO  o.d.e.strategy.ExplorationStrategyPool   Registering strategy class org.droidmate.exploration.strategy.Reset.
2018-07-19 14:21:08.706 INFO  o.d.e.strategy.ExplorationStrategyPool   Registering strategy org.droidmate.exploration.strategy.Terminate@7dac3fd8.
2018-07-19 14:21:08.706 INFO  o.d.e.strategy.ExplorationStrategyPool   Registering strategy org.droidmate.exploration.strategy.widget.RandomWidget@425357dd.
2018-07-19 14:21:08.706 INFO  o.d.e.strategy.ExplorationStrategyPool   Registering strategy org.droidmate.exploration.strategy.widget.AllowRuntimePermission@2102a4d5.
2018-07-19 14:21:08.746 INFO  o.d.e.strategy.ExplorationStrategyPool   (0) <ExplAct Reset app>
time 127.052621 ms 	 img file read
time 67.189 ns/1000 	  
 filter device objects
time 23410.556 ns/1000 	 create all widgets unconfined
===> sumS=0.0 	 sumP=23.410556
time 151070.737 ns/1000 	 compute Widget set 
time 56.405 ns/1000 	 compute result State for 24

time 114239.517 ns/1000 	 special widget handling
time 665.218 ns/1000 	 set dstState
time 0.073991 ms 	 24 widget adding 
time 0.018696 ms 	 state adding
2018-07-19 14:21:21.481 INFO  org.droidmate.command.ExploreCommand     Initial action: <ExplAct Reset app>
2018-07-19 14:21:21.485 WARN  org.droidmate.tools.ApkDeployer          ! Caught ArithmeticException in withDeployedApk(robust-{device emulator-5554}, alogcat-debug.apk)->computation(). Adding as a cause to an ApkExplorationException. Then adding to the collected exceptions list.
The ArithmeticException: java.lang.ArithmeticException: long overflow
2018-07-19 14:21:21.491 ERROR org.droidmate.tools.ApkDeployer          long overflowjava.lang.ArithmeticException: long overflow
	at java.lang.Math.multiplyExact(Math.java:892)
	at java.time.Duration.toMillis(Duration.java:1171)
	at org.droidmate.exploration.ExplorationContext.getExplorationTimeInMs(ExplorationContext.kt:168)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.doResume(StrategySelector.kt:96)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.invoke(StrategySelector.kt)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.invoke(StrategySelector.kt:59)
	at org.droidmate.exploration.strategy.ExplorationStrategyPool$selectStrategy$bestStrategy$1$doResume$$inlined$map$lambda$1.doResume(ExplorationStrategyPool.kt:122)
	at kotlin.coroutines.experimental.jvm.internal.CoroutineImpl.resume(CoroutineImpl.kt:42)
	at kotlinx.coroutines.experimental.DispatchedTask$DefaultImpls.run(Dispatched.kt:161)
	at kotlinx.coroutines.experimental.DispatchedContinuation.run(Dispatched.kt:25)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)

time 19424.581 ns/1000 	 create actionData
time 4723.758 ns/1000 	 add action
2018-07-19 14:21:21.528 INFO  org.droidmate.tools.ApkDeployer          Uninstalling alogcat-debug.apk.fileName
2018-07-19 14:21:31.489 INFO  org.droidmate.command.ExploreCommand     Writing reports
2018-07-19 14:21:31.490 INFO  org.droidmate.report.Reporter            Writing out report AggregateStats to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.513 INFO  org.droidmate.report.Reporter            Writing out report /root/droidmate/./out/droidMate/report/aggregate_stats.txt
2018-07-19 14:21:31.514 INFO  org.droidmate.report.Reporter            Writing out report Summary to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.515 INFO  org.droidmate.report.Reporter            Writing out report ApkViewsFile to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.515 INFO  org.droidmate.report.Reporter            Writing out report ApiCount to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.515 INFO  org.droidmate.report.Reporter            Writing out report ClickFrequency to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.515 INFO  org.droidmate.report.Reporter            Writing out report ApiActionTrace to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.515 INFO  org.droidmate.report.Reporter            Writing out report ActivitySeenSummary to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.516 INFO  org.droidmate.report.Reporter            Writing out report ActionTrace to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.516 INFO  org.droidmate.report.Reporter            Writing out report WidgetApiTrace to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.516 INFO  org.droidmate.report.Reporter            Writing out report VisualizationGraph to /root/droidmate/./out/droidMate/report
2018-07-19 14:21:31.516 ERROR org.droidmate.command.ExploreCommand     java.lang.ArithmeticException: long overflow
org.droidmate.device.android_sdk.ApkExplorationException: java.lang.ArithmeticException: long overflow
	at org.droidmate.tools.ApkDeployer.withDeployedApk(ApkDeployer.kt:66)
	at org.droidmate.command.ExploreCommand$deployExploreSerialize$1.invoke(ExploreCommand.kt:335)
	at org.droidmate.command.ExploreCommand$deployExploreSerialize$1.invoke(ExploreCommand.kt:84)
	at org.droidmate.tools.AndroidDeviceDeployer.withSetupDevice(AndroidDeviceDeployer.kt:179)
	at org.droidmate.command.ExploreCommand.deployExploreSerialize(ExploreCommand.kt:324)
	at org.droidmate.command.ExploreCommand.execute(ExploreCommand.kt:306)
	at org.droidmate.command.ExploreCommand.execute(ExploreCommand.kt:231)
	at org.droidmate.frontend.DroidmateFrontend$Companion.execute(DroidmateFrontend.kt:131)
	at org.droidmate.frontend.DroidmateFrontend$Companion.execute$default(DroidmateFrontend.kt:97)
	at org.droidmate.frontend.DroidmateFrontend$Companion.main(DroidmateFrontend.kt:86)
	at org.droidmate.frontend.DroidmateFrontend.main(DroidmateFrontend.kt)
Caused by: java.lang.ArithmeticException: long overflow
	at java.lang.Math.multiplyExact(Math.java:892)
	at java.time.Duration.toMillis(Duration.java:1171)
	at org.droidmate.exploration.ExplorationContext.getExplorationTimeInMs(ExplorationContext.kt:168)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.doResume(StrategySelector.kt:96)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.invoke(StrategySelector.kt)
	at org.droidmate.exploration.StrategySelector$Companion$timeBasedTerminate$1.invoke(StrategySelector.kt:59)
	at org.droidmate.exploration.strategy.ExplorationStrategyPool$selectStrategy$bestStrategy$1$doResume$$inlined$map$lambda$1.doResume(ExplorationStrategyPool.kt:122)
	at kotlin.coroutines.experimental.jvm.internal.CoroutineImpl.resume(CoroutineImpl.kt:42)
	at kotlinx.coroutines.experimental.DispatchedTask$DefaultImpls.run(Dispatched.kt:161)
	at kotlinx.coroutines.experimental.DispatchedContinuation.run(Dispatched.kt:25)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
2018-07-19 14:21:31.519 ERROR org.droidmate.frontend.ExceptionHandler  A nonempty ThrowablesCollection was thrown during DroidMate run. Each of the 1 Throwables will now be logged.
2018-07-19 14:21:31.520 ERROR org.droidmate.frontend.ExceptionHandler  ========================================
2018-07-19 14:21:31.520 ERROR org.droidmate.frontend.ExceptionHandler  An ApkExplorationException was thrown during DroidMate run, pertaining to alogcat-debug.apk: org.droidmate.device.android_sdk.ApkExplorationException: java.lang.ArithmeticException: long overflow
2018-07-19 14:21:31.520 ERROR org.droidmate.frontend.ExceptionHandler  ========================================
2018-07-19 14:21:31.520 ERROR org.droidmate.frontend.ExceptionHandler  Please see ./out/droidMate/logs/exceptions.txt log for details.
2018-07-19 14:21:31.521 WARN  org.droidmate.frontend.DroidmateFrontend DroidMate run finished, but some exceptions have been thrown and handled during the run. See previous logs for details.
2018-07-19 14:21:31.521 INFO  org.droidmate.frontend.DroidmateFrontend Run finish timestamp: Thu Jul 19 14:21:31 UTC 2018. DroidMate ran for 28 sec.
2018-07-19 14:21:31.521 INFO  org.droidmate.frontend.DroidmateFrontend The results from the run can be found in /root/droidmate/./out/droidMate directory.
2018-07-19 14:21:31.521 INFO  org.droidmate.frontend.DroidmateFrontend By default, for detailed diagnostics logs from the run, see ./out/droidMate/logs directory.
```


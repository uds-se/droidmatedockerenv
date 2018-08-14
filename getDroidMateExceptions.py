#!/usr/bin/python
# -*- coding: utf-8 -*-

# Thanks:
# https://stackoverflow.com/a/34325723/8091456

import re
import os
import sys
import hashlib
import glob
import json
import threading
import time



if len(sys.argv) < 2:
    print "Usage: " + sys.argv[0] + "<OUT_FOLDERPATH>"
    sys.exit(1)


OUT_FOLDERPATH = os.path.realpath(sys.argv[1])

files2check = ["/droidmate_*.log"]
# files2check = ["/droidmate_*.log", "/droidMate/logs/logcat.txt"]

filters_toTake = ['org.droidmate.']
ignoreWords = ['vladium', '\tat ', 'lack of ', 'DEBUG']

exception_filename = "exceptions"
exception_filename_txt = exception_filename + ".txt"
exception_filename_json = exception_filename + ".json"
exceptionMap_filename = "exceptions.map"
exceptionMap_filename_txt = exceptionMap_filename + ".txt"

################################################################
# AUX FUNCs
################################################################

# Print iterations progress
# https://stackoverflow.com/a/34325723/8091456
# https://gist.github.com/aubricus/f91fb55dc6ba5557fbab06119420dd6a


def print_progress(iteration, total, prefix='', suffix='', decimals=1, bar_length=100, fill='█'):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        bar_length  - Optional  : character length of bar (Int)
    """
    str_format = "{0:." + str(decimals) + "f}"
    percents = str_format.format(100 * (iteration / float(total)))
    filled_length = int(round(bar_length * iteration / float(total)))
    bar = fill * filled_length + '-' * (bar_length - filled_length)

    sys.stdout.write('\r%s |%s| %s%s %s' %
                     (prefix, bar, percents, '%', suffix)),

    if iteration == total:
        sys.stdout.write('\n')
    sys.stdout.flush()


def dict_to_json(dict_to_dump, jsonfilepath):
    with open(jsonfilepath, 'w') as f:
        json.dump(dict_to_dump, f, sort_keys=True,
                  indent=2, separators=(',', ': '))
    f.close()


def getDirs(root, cond=lambda x: True):
    return [name for name in sorted(os.listdir(root))
            if os.path.isdir(os.path.join(root, name)) and cond(name)]


def get_foldersNames_in_directory(directory=os.getcwd(), arr=[]):
    arr += getDirs(directory)
    return arr


def logError(curErr, ex):
    # ignore object ids while computing hash
    curErr = re.sub(r'@\w*', '', curErr)
    md5 = hashlib.md5(curErr).hexdigest()
    ex[md5] = curErr


def ignoreError(line):
    for f in filters_toTake:
        if f in line:
            for word in ignoreWords:
                if word in line:
                    return True
            return False
    return True


def writeExceptionDetails(d, ex):
    exceptions = open(d + "/" + exception_filename_txt, "w")
    exceptionMap = open(d + "/" + exceptionMap_filename_txt, "w")
    exKeys = sorted(ex.keys())
    for k in exKeys:
        exceptions.write(str(k) + "\n")
        exceptionMap.write("*" * 80 + "\n" + str(k) + "\n" + str(ex[k]) + "\n\n")
    exceptions.close()
    exceptionMap.close()


def get_files2check_validpaths(appDP, files2check):
    files2check_validpaths = []
    for f in files2check:
        d = glob.glob(appDP + "/" + f)
        if len(d) > 0:
            files2check_validpaths.append(d[0])
    return files2check_validpaths

################################################################
# AUX FUNCs
################################################################


ex_global = {}
threads_array = []


class Out_app_thread(threading.Thread):
    def __init__(self, name, path):
        threading.Thread.__init__(self)
        self.name = name
        self.out_app_name = name
        self.out_app_path = path

    def run(self):
        global ex_global

        ex = {}
        ex_global[self.out_app_name] = {}

        files2check_validpaths = get_files2check_validpaths(
            self.out_app_path, files2check)

        for f in files2check_validpaths:
            log = open(f)
            found = False
            curErr = ""
            for line in log:
                line = re.sub("^[\w/() \.]*: ", "", line)
                if 'Exception' in line:
                    if ignoreError(line):
                        continue
                    if found:
                        logError(curErr, ex)
                    curErr = line
                    found = True
                elif found:
                    if re.search('\tat', line):
                        curErr += line
                    else:
                        found = False
                        logError(curErr, ex)

        writeExceptionDetails(self.out_app_path, ex)
        dict_to_json(ex, self.out_app_path+"/"+exception_filename_json)
        ex_global[self.out_app_name] = ex
        

appsDirNames = get_foldersNames_in_directory(OUT_FOLDERPATH, [])
n_threads_array = len(appsDirNames)
iStats = 0
print_progress(iStats, n_threads_array*2, prefix='Progress:',
               suffix='Complete', bar_length=50)
for appDN in appsDirNames:
    appDP = OUT_FOLDERPATH + "/" + appDN + "/"
    th = Out_app_thread(appDN, appDP)
    iStats += 1
    # print("Running thread: " + str(iStats) + " / " +
    #       str(n_threads_array) + ": " + th.name)
    threads_array.append(th)
    th.start()
    print_progress(iStats, n_threads_array*2, prefix='Progress:',
                   suffix='Complete', bar_length=50)

# Wait for all threads
for idth, th in enumerate(threads_array):
    # print("Waiting thread: " + str(idth+1) + " / " +
    #       str(n_threads_array) + ": " + th.name)
    print_progress(n_threads_array+idth+1, n_threads_array*2, prefix='Progress:',
                   suffix='Complete', bar_length=50)
    th.join()

dict_to_json(ex_global, OUT_FOLDERPATH+"/"+exception_filename_json)

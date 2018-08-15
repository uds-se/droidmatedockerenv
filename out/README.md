# out

Folder name pattern:

```bash
$(date +"%Y-%m-%d_%H-%M-%S").${TOOL_REPONAME}.${TOOL_COMMIT}.${API}.${ARCH}
```

## Check the out folder

Go inside you apk folder and read the [DroidMate wiki](https://github.com/uds-se/droidmate/wiki/output).

### Check num of states

1. Find and replace this pattern `.[0-9\-_]*.droidmate.[a-zA-Z0-9.\-_/]*.png` by "".

2. Find and replace this `./out/` by "".

3. Count the num of occurs.

```bash
cat report_npngs_in_model-states.txt | sort | uniq -c > report_npngs_in_model-states_count.txt
```

4. Duplicate the file `report_npngs_in_model-states_count.txt` to `report_npngs_in_model-states_count.csv`.

5. Edit the file to convert in a CSV. Removing the spaces from 6 to 2 spaces. And replace the 1 space between numbers and text by `","` (comma).
#!/bin/bash

echo "Setup parameters: $@"

if [[ $1 != "[" ]]; then
    echo "Expected [ as next character, but was $1"
    exit 1
fi

# Process dependencies
echo "Process dependencies"
INDEX=2
SubStr="="
for i in ${@:${INDEX}}; do
    INDEX=$((INDEX+1))
    if [[ "${i}" == "]" ]]; then
        break
    fi
    echo "Param $i"
    keyword=${i%%=*}
    val=${i#*=}
    case "$keyword" in
        ("dependency")
            rm -rf ${INDEX}
            mkdir ${INDEX}
            git clone ${val} ${INDEX}
            cd ${INDEX}
            ./gradlew install
            ;;
        (*)
            echo "Not supported action: $keyword"
            ;;
    esac
done

exit 0
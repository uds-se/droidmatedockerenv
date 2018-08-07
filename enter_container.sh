#!/bin/bash

docker exec -it $(docker ps -q  --filter=ancestor="droidmate") /bin/bash
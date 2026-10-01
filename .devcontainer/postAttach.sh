#!/bin/bash

echo "Starting port forwards..."

# Run in background, print output directly
bash Scripts/port-forward-all.sh &

# Return immediately so container can attach

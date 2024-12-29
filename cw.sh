#!/bin/bash

# Get the absolute path of the directory containing the current script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Run the Lua script located in the same directory as the current script
lua "$SCRIPT_DIR/main.lua" "$@"

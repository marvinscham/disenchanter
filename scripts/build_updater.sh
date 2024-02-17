#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

ocran src/updater.rb \
    --gemfile ./Gemfile \
    --icon BE_icon.ico \
    --output ./build/disenchanter_up.exe

rm ./build/.build.lockfile

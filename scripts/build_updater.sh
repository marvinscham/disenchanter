#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

ocran src/updater.rb \
    --gemfile ./Gemfile \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter_up.exe

rm ./build/.build.lockfile

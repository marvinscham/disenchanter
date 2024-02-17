#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

ocran src/main.rb \
    --gemfile ./Gemfile \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter.exe

rm ./build/.build.lockfile

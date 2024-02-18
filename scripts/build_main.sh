#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

# Deleting the i18n gem's tests might be necessary
ocran src/main.rb \
    ./i18n/*.yml \
    --gemfile ./Gemfile \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter.exe

rm ./build/.build.lockfile

#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

# Deleting the i18n gem's tests might be necessary
bundle exec ocran src/main.rb \
    ./i18n/*.yml \
    --gemfile ./Gemfile \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter.exe && \
bundle exec ocran src/updater.rb \
    --gemfile ./Gemfile \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter_up.exe && \
echo "Success!" || echo "Something went wrong."

rm ./build/.build.lockfile

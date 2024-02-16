#!/bin/bash
mkdir -p build
touch ./build/.build.lockfile

ocra src/main.rb \
    --gemfile ./Gemfile \
    --dll ruby_builtin_dlls/libffi-7.dll \
    --dll ruby_builtin_dlls/libssp-0.dll \
    --dll ruby_builtin_dlls/libgmp-10.dll \
    --dll ruby_builtin_dlls/libgcc_s_seh-1.dll \
    --dll ruby_builtin_dlls/libwinpthread-1.dll \
    --dll ruby_builtin_dlls/libssl-1_1-x64.dll \
    --dll ruby_builtin_dlls/libcrypto-1_1-x64.dll \
    --icon ./assets/BE_icon.ico \
    --output ./build/disenchanter.exe

rm ./build/.build.lockfile

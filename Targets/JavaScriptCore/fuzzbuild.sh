#!/bin/bash
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export WEBKIT_OUTPUTDIR=FuzzBuild

clang_path=$LLVM_PATH/usr/bin/clang
clangpp_path=$LLVM_PATH/usr/bin/clang++

if [ "$(uname)" == "Linux" ]; then
    ./Tools/Scripts/build-jsc --jsc-only --debug --cmakeargs="-DDEVELOPER_MODE=OFF -DENABLE_FUZZILLI=ON -DENABLE_STATIC_JSC=ON -DCMAKE_C_COMPILER='${clang_path}' -DCMAKE_CXX_COMPILER='${clangpp_path}' -DCMAKE_CXX_FLAGS='-Wno-multichar -Wno-error -Wno-format-truncation'"
else
    echo "Unsupported operating system"
fi

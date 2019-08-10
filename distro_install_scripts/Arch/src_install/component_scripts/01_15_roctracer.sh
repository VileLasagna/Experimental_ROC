#!/bin/bash
###############################################################################
# Copyright (c) 2018 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
set -e
trap 'lastcmd=$curcmd; curcmd=$BASH_COMMAND' DEBUG
trap 'errno=$?; print_cmd=$lastcmd; if [ $errno -ne 0 ]; then echo "\"${print_cmd}\" command failed with exit code $errno."; fi' EXIT
source "$BASE_DIR/../common_options.sh"
parse_args "$@"

# Install pre-reqs. We might need build-essential, cmake, and git if nobody
# ran the higher-level build scripts.
# We need 'rpm' because this makefile will always try to build RPMs..
if [ ${ROCM_LOCAL_INSTALL} = false ] || [ ${ROCM_INSTALL_PREREQS} = true ]; then
    echo "Installing software required to build the ROC profiler."
    echo "You will need to have root privileges to do this."
    sudo pacman -Sy --noconfirm --needed base-devel cmake pkgconf git
    if [ ${ROCM_INSTALL_PREREQS} = true ] && [ ${ROCM_FORCE_GET_CODE} = false ]; then
        exit 0
    fi
fi

# Set up source-code directory
if [ $ROCM_SAVE_SOURCE = true ]; then
    SOURCE_DIR=${ROCM_SOURCE_DIR}
    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ -d ${SOURCE_DIR}/roctracer ]; then
        rm -rf ${SOURCE_DIR}/roctracer
    fi
    mkdir -p ${SOURCE_DIR}
else
    SOURCE_DIR=`mktemp -d`
fi
cd ${SOURCE_DIR}

# Download ROC profiler
if [ ${ROCM_FORCE_GET_CODE} = true ] || [ ! -d ${SOURCE_DIR}/roctracer ]; then
    git clone -b ${ROCM_VERSION_BRANCH} https://github.com/ROCm-Developer-Tools/roctracer.git
    cd ${SOURCE_DIR}/roctracer/
    git checkout ${ROCM_ROCTRACER_CHECKOUT}
else
    echo "Skipping download of ROC-tracer, since ${SOURCE_DIR}/roctracer already exists."
fi

if [ ${ROCM_FORCE_GET_CODE} = true ]; then
    echo "Finished downloading ROC profiler. Exiting."
    exit 0
fi

cd ${SOURCE_DIR}/roctracer
sed -i 's/sh -xc "${ROOT_DIR}/sh -xc "python2 ${ROOT_DIR}/' ./src/CMakeLists.txt
mkdir -p build
cd build
export CMAKE_PREFIX_PATH=${ROCM_INPUT_DIR}/include:${ROCM_INPUT_DIR}/lib
export CMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE}
export CMAKE_DEBUG_TRACE=0
# The build for roctracer tries to read these from the env instead of properly finding the CMake packages for whatever reason
# but they won't be set during the build yet so we need to point it in the correct direction
export HCC_HOME=${ROCM_INPUT_DIR}/hcc
export HIP_PATH=${ROCM_INPUT_DIR}
# There is no pacman cpack generator. It should(?) be possible to hook makepkg up to it through the external generator
# but that feels like much more hassle than it's worth. Instead, I think I'll just write the PKGBUILD files later and
# call the tool manually
cmake -DCMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ROCM_OUTPUT_DIR} -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DCPACK_GENERATOR=DEB ..
make -j `nproc`

if [ ${ROCM_FORCE_BUILD_ONLY} = true ]; then
    echo "Finished building ROC-tracer. Exiting."
    exit 0
fi

if [ ${ROCM_FORCE_PACKAGE} = true ]; then
    echo "Sorry, packaging not yet implemented for this distribution"
    exit 2
############
# This file wasn't written from scratch. It was copied and adapted from ROC profiler
# As such, I have no idea whether any of this section is correct
############

#     make package
#     echo "Copying `ls -1 roctracer-dev-*.deb` to ${ROCM_PACKAGE_DIR}"
#     mkdir -p ${ROCM_PACKAGE_DIR}
#     cp ./roctracer-dev-*.deb ${ROCM_PACKAGE_DIR}
#     if [ ${ROCM_LOCAL_INSTALL} = false ]; then
#         ROCM_PKG_IS_INSTALLED=`dpkg -l roctracer-dev | grep '^.i' | wc -l`
#         if [ ${ROCM_PKG_IS_INSTALLED} -gt 0 ]; then
#             PKG_NAME=`dpkg -l roctracer-dev | grep '^.i' | awk '{print $2}'`
#             sudo dpkg -r --force-depends ${PKG_NAME}
#         fi
#         sudo dpkg -i ./roctracer-dev-*.deb
#     fi
else
    ${ROCM_SUDO_COMMAND} make install

    ${ROCM_SUDO_COMMAND} bash -c "for i in include lib; do cp -fR ${ROCM_OUTPUT_DIR}/roctracer/${i}/* ${ROCM_OUTPUT_DIR}/${i}/; done"
    ${ROCM_SUDO_COMMAND} cp -fR ${ROCM_OUTPUT_DIR}/roctracer/tool ${ROCM_OUTPUT_DIR}
    ${ROCM_SUDO_COMMAND} rm -rf ${ROCM_OUTPUT_DIR}/roctracer
    #This install leaves a broken symlink behind
    if [ -L  ${ROCM_OUTPUT_DIR}/include/roctracer ] && [ ! -e  ${ROCM_OUTPUT_DIR}/include/roctracer ]; then ${ROCM_SUDO_COMMAND} rm -f ${ROCM_OUTPUT_DIR}/include/roctracer; fi
fi

if [ $ROCM_SAVE_SOURCE = false ]; then
    rm -rf ${SOURCE_DIR}
fi

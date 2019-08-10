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

# Install pre-reqs.
if [ ${ROCM_LOCAL_INSTALL} = false ] || [ ${ROCM_INSTALL_PREREQS} = true ]; then
    echo "Installing software required to build the rocBLAS."
    echo "You will need to have root privileges to do this."
    sudo pacman -Sy --noconfirm --needed base-devel cmake pkgconf git make python2 python2-yaml gcc-fortran boost
    if [ ${ROCM_INSTALL_PREREQS} = true ] && [ ${ROCM_FORCE_GET_CODE} = false ]; then
        exit 0
    fi
fi

# Set up source-code directory
if [ $ROCM_SAVE_SOURCE = true ]; then
    SOURCE_DIR=${ROCM_SOURCE_DIR}
    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ -d ${SOURCE_DIR}/rocBLAS ]; then
        rm -rf ${SOURCE_DIR}/rocBLAS
    fi
    mkdir -p ${SOURCE_DIR}
else
    SOURCE_DIR=`mktemp -d`
fi
cd ${SOURCE_DIR}

# Download rocBLAS
if [ ${ROCM_FORCE_GET_CODE} = true ] || [ ! -d ${SOURCE_DIR}/rocBLAS ]; then
    git clone https://github.com/ROCmSoftwarePlatform/rocBLAS.git
    cd rocBLAS
    git checkout ${ROCM_ROCBLAS_CHECKOUT}
else
    echo "Skipping download of rocBLAS, since ${SOURCE_DIR}/rocBLAS already exists."
fi

if [ ${ROCM_FORCE_GET_CODE} = true ]; then
    echo "Finished downloading rocBLAS. Exiting."
    exit 0
fi

cd ${SOURCE_DIR}/rocBLAS
#sed -i 's/find_package( hcc REQUIRED/#find_package( hcc REQUIRED/' ./library/src/CMakeLists.txt
mkdir -p build/release
cd build/release
CXX=${ROCM_INPUT_DIR}/bin/hcc cmake -DCMAKE_CXX_COMPILER=${ROCM_INPUT_DIR}/bin/hcc -DCMAKE_PREFIX_PATH=${ROCM_INPUT_DIR}/lib  -DCMAKE_VERBOSE_MAKEFILE=ON -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DCPACK_GENERATOR=DEB -DCMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ ../..
# Linking can take a large amount of memory, and it will fail if you do not
# have enough memory available per thread. As such, this # logic limits the
# number of build threads in response to the amount of available memory on
# the system.
MEM_AVAIL=`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`
AVAIL_THREADS=`nproc`

# Give about 2 GB to each building thread
MAX_THREADS=`echo $(( ${MEM_AVAIL} / $(( 1024 * 1024 * 2 )) ))`
if [ ${MAX_THREADS} -lt ${AVAIL_THREADS} ]; then
    NUM_BUILD_THREADS=${MAX_THREADS}
else
    NUM_BUILD_THREADS=${AVAIL_THREADS}
fi
if [ ${NUM_BUILD_THREADS} -lt 1 ]; then
    NUM_BUILD_THREADS=1
fi

make -j ${NUM_BUILD_THREADS}

if [ ${ROCM_FORCE_BUILD_ONLY} = true ]; then
    echo "Finished building rocBLAS. Exiting."
    exit 0
fi

if [ ${ROCM_FORCE_PACKAGE} = true ]; then
    echo "Sorry, packaging not yet implemented for this distribution"
    exit 2
    # make package
    # echo "Copying `ls -1 rocblas-*.deb` to ${ROCM_PACKAGE_DIR}"
    # mkdir -p ${ROCM_PACKAGE_DIR}
    # cp ./rocblas-*.deb ${ROCM_PACKAGE_DIR}
    # if [ ${ROCM_LOCAL_INSTALL} = false ]; then
    #     ROCM_PKG_IS_INSTALLED=`dpkg -l rocblas | grep '^.i' | wc -l`
    #     if [ ${ROCM_PKG_IS_INSTALLED} -gt 0 ]; then
    #         PKG_NAME=`dpkg -l rocblas | grep '^.i' | awk '{print $2}'`
    #         sudo dpkg -r --force-depends ${PKG_NAME}
    #     fi
    #     sudo dpkg -i ./rocblas-*.deb
    # fi
else
    ${ROCM_SUDO_COMMAND} make install

    if [ ${ROCM_LOCAL_INSTALL} = false ]; then
        echo ${ROCM_OUTPUT_DIR}/lib | ${ROCM_SUDO_COMMAND} tee -a /etc/ld.so.conf.d/rocblas.conf
    fi
fi

if [ $ROCM_SAVE_SOURCE = false ]; then
    rm -rf ${SOURCE_DIR}
fi

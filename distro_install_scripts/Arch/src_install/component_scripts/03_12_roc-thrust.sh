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
    echo "Installing software required to build ROC Thrust."
    echo "You will need to have root privileges to do this."
    sudo pacman -Sy --noconfirm --needed base-devel cmake pkgconf git
    if [ ${ROCM_INSTALL_PREREQS} = true ] && [ ${ROCM_FORCE_GET_CODE} = false ]; then
        exit 0
    fi
fi

# Set up source-code directory
if [ $ROCM_SAVE_SOURCE = true ]; then
    SOURCE_DIR=${ROCM_SOURCE_DIR}
    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ -d ${SOURCE_DIR}/rocThrust ]; then
        rm -rf ${SOURCE_DIR}/rocThrust
    fi
    mkdir -p ${SOURCE_DIR}
else
    SOURCE_DIR=`mktemp -d`
fi
cd ${SOURCE_DIR}

# Download rocThrust
if [ ${ROCM_FORCE_GET_CODE} = true ] || [ ! -d ${SOURCE_DIR}/rocThrust ]; then
    git clone --recursive https://github.com/ROCmSoftwarePlatform/rocThrust.git
    cd rocThrust
    git checkout ${ROCM_ROCTHRUST_CHECKOUT}
    git submodule update
else
    echo "Skipping download of HIP Thrust, since ${SOURCE_DIR}/rocThrust already exists."
fi

if [ ${ROCM_FORCE_GET_CODE} = true ]; then
    echo "Finished downloading rocThrust. Exiting."
    exit 0
fi

cd ${SOURCE_DIR}/rocThrust
# cp ${SOURCE_DIR}/Thrust/postinst.orig ${SOURCE_DIR}/rocThrust/postinst
# sed -i "s#ROCM_INSTALL_DIR#${ROCM_OUTPUT_DIR}#" ${SOURCE_DIR}/rocThrust/postinst
# cp ${SOURCE_DIR}/Thrust/prerm.orig ${SOURCE_DIR}/rocThrust/prerm
# sed -i "s#ROCM_INSTALL_DIR#${ROCM_OUTPUT_DIR}#" ${SOURCE_DIR}/rocThrust/prerm
mkdir -p build
cd build
HIP_PLATFORM=hcc cmake -DCMAKE_CXX_COMPILER=${ROCM_INPUT_DIR}/bin/hcc -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DCPACK_GENERATOR=DEB -DCMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DBUILD_VERSION_MAJOR=${ROCM_VERSION_MAJOR} -DBUILD_VERSION_MINOR=${ROCM_VERSION_MINOR} -DBUILD_VERSION_PATCH=${ROCM_VERSION_PATCH} -DCPACK_DEBIAN_PACKAGE_CONTROL_EXTRA="${SOURCE_DIR}/rocThrust/postinst;${SOURCE_DIR}/rocThrust/prerm" ..
make -j `nproc`

if [ ${ROCM_FORCE_BUILD_ONLY} = true ]; then
    echo "Finished building rocALUTIONrocThrust. Exiting."
    exit 0
fi

if [ ${ROCM_FORCE_PACKAGE} = true ]; then
    echo "Sorry, packaging not yet implemented for this distribution"
    exit 2
#     # Temporarily delete the bad symlink mentioned above
#     BAD_SYMLINK_LOCATION=`find ${SOURCE_DIR}/rocThrust/ -name cub -type l`
#     rm -f ${BAD_SYMLINK_LOCATION}
#     make package
#     # Restore it so that any future 'make install' does not miss it.
#     # We don't have postinst/prerm for 'make install', so the file does
#     # need to exist.
#     ln -sf cub-hip/cub ${BAD_SYMLINK_LOCATION}
#     echo "Copying `ls -1 roc-thrust-*.deb` to ${ROCM_PACKAGE_DIR}"
#     mkdir -p ${ROCM_PACKAGE_DIR}
#     cp ./roc-thrust-*.deb ${ROCM_PACKAGE_DIR}
#     if [ ${ROCM_LOCAL_INSTALL} = false ]; then
#         ROCM_PKG_IS_INSTALLED=`dpkg -l roc-thrust | grep '^.i' | wc -l`
#         if [ ${ROCM_PKG_IS_INSTALLED} -gt 0 ]; then
#             PKG_NAME=`dpkg -l roc-thrust | grep '^.i' | awk '{print $2}'`
#             sudo dpkg -r --force-depends ${PKG_NAME}
#         fi
#         sudo dpkg -i ./roc-thrust-*.deb
#     fi
else
    ${ROCM_SUDO_COMMAND} make install
fi

if [ $ROCM_SAVE_SOURCE = false ]; then
    rm -rf ${SOURCE_DIR}
fi
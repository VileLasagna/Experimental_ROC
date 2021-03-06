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
    echo "Installing software required to build HIP Thrust."
    echo "You will need to have root privileges to do this."
    sudo pacman -Sy --noconfirm --needed base-devel cmake pkgconf git
    if [ ${ROCM_INSTALL_PREREQS} = true ] && [ ${ROCM_FORCE_GET_CODE} = false ]; then
        exit 0
    fi
fi

# Set up source-code directory
if [ $ROCM_SAVE_SOURCE = true ]; then
    SOURCE_DIR=${ROCM_SOURCE_DIR}
    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ -d ${SOURCE_DIR}/Thrust ]; then
        rm -rf ${SOURCE_DIR}/Thrust
    fi
    mkdir -p ${SOURCE_DIR}
else
    SOURCE_DIR=`mktemp -d`
fi
cd ${SOURCE_DIR}

# Download HIP Thrust
if [ ${ROCM_FORCE_GET_CODE} = true ] || [ ! -d ${SOURCE_DIR}/Thrust ]; then
    git clone --recursive https://github.com/ROCmSoftwarePlatform/Thrust.git
    cd Thrust
    git checkout ${ROCM_HIPTHRUST_CHECKOUT}
    git submodule update
    sed -i 's/"Thrust"/"hip-thrust"/' ./CMakeLists.txt
    sed -i 's/set(CPACK_DEBIAN_PACKAGE_DEPENDS "cub-hip")//' ./CMakeLists.txt
    # Someone committed a bunch of hidden .swp files to cub-hip. These can
    # break package installs, so kill them here.
    for i in `find ./ -name \*.swp`; do rm -f ${i}; done
    # # Newer versions of cmake really do not like having a symlink directory
    # # in the deb that points to somewhere else in the deb. They try to package
    # # up all the files in the symlink, and the install breaks. As such, we
    # # need to delete this symlink and add a postinst/prerm pair to handle it
    # # during package installation
    # pushd ${BASE_DIR}/../common/deb_files/
    # cp ./hip-thrust-postinst ${SOURCE_DIR}/Thrust/postinst.orig
    # cp ./hip-thrust-prerm ${SOURCE_DIR}/Thrust/prerm.orig
    # popd
else
    echo "Skipping download of HIP Thrust, since ${SOURCE_DIR}/Thrust already exists."
fi

if [ ${ROCM_FORCE_GET_CODE} = true ]; then
    echo "Finished downloading HIP Thrust. Exiting."
    exit 0
fi

cd ${SOURCE_DIR}/Thrust
# cp ${SOURCE_DIR}/Thrust/postinst.orig ${SOURCE_DIR}/Thrust/postinst
# sed -i "s#ROCM_INSTALL_DIR#${ROCM_OUTPUT_DIR}#" ${SOURCE_DIR}/Thrust/postinst
# cp ${SOURCE_DIR}/Thrust/prerm.orig ${SOURCE_DIR}/Thrust/prerm
# sed -i "s#ROCM_INSTALL_DIR#${ROCM_OUTPUT_DIR}#" ${SOURCE_DIR}/Thrust/prerm
mkdir -p build
cd build
cmake -DCPACK_PACKAGING_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DCPACK_GENERATOR=DEB -DCMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/ -DBUILD_VERSION_MAJOR=${ROCM_VERSION_MAJOR} -DBUILD_VERSION_MINOR=${ROCM_VERSION_MINOR} -DBUILD_VERSION_PATCH=${ROCM_VERSION_PATCH} -DCPACK_DEBIAN_PACKAGE_CONTROL_EXTRA="${SOURCE_DIR}/Thrust/postinst;${SOURCE_DIR}/Thrust/prerm" ..

if [ ${ROCM_FORCE_BUILD_ONLY} = true ]; then
    echo "Nothing to build for HIP Thrust. It is a header-only library. Exiting."
    exit 0
fi

if [ ${ROCM_FORCE_PACKAGE} = true ]; then
    echo "Sorry, packaging not yet implemented for this distribution"
    exit 2
#     # Temporarily delete the bad symlink mentioned above
#     BAD_SYMLINK_LOCATION=`find ${SOURCE_DIR}/Thrust/ -name cub -type l`
#     rm -f ${BAD_SYMLINK_LOCATION}
#     make package
#     # Restore it so that any future 'make install' does not miss it.
#     # We don't have postinst/prerm for 'make install', so the file does
#     # need to exist.
#     ln -sf cub-hip/cub ${BAD_SYMLINK_LOCATION}
#     echo "Copying `ls -1 hip-thrust-*.deb` to ${ROCM_PACKAGE_DIR}"
#     mkdir -p ${ROCM_PACKAGE_DIR}
#     cp ./hip-thrust-*.deb ${ROCM_PACKAGE_DIR}
#     if [ ${ROCM_LOCAL_INSTALL} = false ]; then
#         ROCM_PKG_IS_INSTALLED=`dpkg -l hip-thrust | grep '^.i' | wc -l`
#         if [ ${ROCM_PKG_IS_INSTALLED} -gt 0 ]; then
#             PKG_NAME=`dpkg -l hip-thrust | grep '^.i' | awk '{print $2}'`
#             sudo dpkg -r --force-depends ${PKG_NAME}
#         fi
#         sudo dpkg -i ./hip-thrust-*.deb
#     fi
else
    ${ROCM_SUDO_COMMAND} make install
fi

if [ $ROCM_SAVE_SOURCE = false ]; then
    rm -rf ${SOURCE_DIR}
fi

#!/bin/bash
###############################################################################
# Copyright (c) 2018-2019 Advanced Micro Devices, Inc.
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

# ROCm software tags across all of the build scripts.
# These should be updated whenever new versions of ROCm are released.
ROCM_VERSION_BRANCH=roc-2.6.x # Most ROCm repos have a major release branch
ROCM_HCC_VERSION_BRANCH=roc-hcc-2.6.x
ROCM_OCL_VERSION_BRANCH=roc-ocl-2.6.x
ROCM_VERSION_MAJOR=2
ROCM_VERSION_MINOR=6
ROCM_VERSION_PATCH=0
# Most ROCm repos have the ROCm release tagged
ROCM_VERSION_TAG=roc-${ROCM_VERSION_MAJOR}.${ROCM_VERSION_MINOR}.${ROCM_VERSION_PATCH}
ROCM_VERSION_LONG=2.6.0 # The meta-packages have a ROCM version number
# The following projects do not yet tag their releases cleanly, so we need
# to pull their versions based on the GitHub SHA-1.
ROCM_CMAKE_SHA=56e04c0
ROCM_MIOPENGEMM_SHA=9547fb9
# The following projects have different version number schemes that ROCm,
# so they need custom tag names.
ROCM_HCC_TAG=roc-hcc-2.6.0
ROCM_ATMI_TAG=rocm_2.6.0
ROCM_ROCBLAS_TAG=rocm-2.6
ROCM_ROCRAND_TAG=2.6.0
ROCM_HIPBLAS_TAG=rocm-2.6
ROCM_ROCFFT_TAG=v0.9.4
ROCM_ROCSPARSE_TAG=rocm-2.7
ROCM_HIPSPARSE_TAG=rocm-2.6
ROCM_ROCALUTION_TAG=rocm-2.6
ROCM_RCCL_TAG=2.6.0
# HIPTHRUST is deprecated, leaving for compatibility
# AMD announced it is to be removed from the suite later
ROCM_HIPTHRUST_TAG=2.6.0
ROCM_ROCTHRUST_TAG=2.6.0
ROCM_HIPCUB_TAG=2.6.0
ROCM_ROCPRIM_TAG=2.6.0

# Step 01 checkout tags and hashes
ROCM_ROCK_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_ROCT_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_ROCR_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_SMI_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_CMAKE_CHECKOUT=${ROCM_CMAKE_SHA}
ROCM_ROCMINFO_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_ROCTRACER_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_ROCPROFILER_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_OPENCL_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_CLANG_OCL_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_HCC_CHECKOUT=tags/${ROCM_HCC_TAG}
ROCM_HIP_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_DEVICE_LIBS_CHECKOUT=tags/roc-hcc-${ROCM_VERSION_LONG}
ROCM_ATMI_CHECKOUT=tags/${ROCM_ATMI_TAG}
ROCM_COMGR_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCR_DEBUG_AGENT_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_BANDWIDTH_TEST_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_ROCPRIM_CHECKOUT=tags/${ROCM_ROCPRIM_TAG}

# Step 03 checkout tags and hashes
ROCM_ROCBLAS_CHECKOUT=tags/${ROCM_ROCBLAS_TAG}
ROCM_HIPBLAS_CHECKOUT=tags/${ROCM_HIPBLAS_TAG}
ROCM_ROCFFT_CHECKOUT=tags/${ROCM_ROCFFT_TAG}
ROCM_ROCRAND_CHECKOUT=tags/${ROCM_ROCRAND_TAG}
ROCM_ROCSPARSE_CHECKOUT=tags/${ROCM_ROCSPARSE_TAG}
ROCM_HIPSPARSE_CHECKOUT=tags/${ROCM_HIPSPARSE_TAG}
ROCM_ROCALUTION_CHECKOUT=tags/${ROCM_ROCALUTION_TAG}
ROCM_MIOPENGEMM_CHECKOUT=${ROCM_MIOPENGEMM_SHA}
ROCM_MIOPEN_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_HIPTHRUST_CHECKOUT=tags/${ROCM_HIPTHRUST_TAG}
ROCM_ROCTHRUST_CHECKOUT=tags/${ROCM_ROCTHRUST_TAG}
ROCM_HIPCUB_CHECKOUT=tags/${ROCM_HIPCUB_TAG}
ROCM_SMILIB_CHECKOUT=tags/${ROCM_VERSION_TAG}
ROCM_RCCL_CHECKOUT=tags/${ROCM_RCCL_TAG}

PRINT_HELP=false # -h option
ROCM_FORCE_BUILD_ONLY=false # -b option
ROCM_FORCE_GET_CODE=false # -g option
ROCM_LOCAL_INSTALL=false # -l option
ROCM_INSTALL_PREREQS=false # -r option

# -d option
ROCM_BUILD_DEBUG=false
ROCM_DEBUG_LEVEL=0
ROCM_CMAKE_BUILD_TYPE=Release
# -i option
ROCM_CHANGE_INPUT=false
ROCM_INPUT_DIR=/opt/rocm
# -o option
ROCM_CHANGE_OUTPUT=false
ROCM_OUTPUT_DIR=/opt/rocm
# -p option
ROCM_FORCE_PACKAGE=false
ROCM_PACKAGE_DIR=/tmp/
# -s option
ROCM_SAVE_SOURCE=false
ROCM_SOURCE_DIR=/tmp/

ROCM_FORCE_YES=false # -y option
ROCM_FORCE_NO=false # -n option

# MIOpen needs one extra option, so we silently pass this in to cause the
# options script do something a bit different.
IS_MIOPEN_CALL=false
# Internal parse variable to force OpenCL for MIOpen builds instead of HIP
# --force_opencl
MIOPEN_FORCE_OPENCL=false
IS_MIOPEN_CALL=false

# We can empty this variable out when we don't want to run commands as sudo
ROCM_SUDO_COMMAND=sudo

# Send this into RPM builds so that cpack sets the proper permissions for
# upper-level directories like /opt/ and /opt/rocm/. Othewise, it looks like
# new packages are causing conflicts with other when they try to change
# permissions.
ROCM_CPACK_RPM_PERMISSIONS='-DCPACK_RPM_DEFAULT_DIR_PERMISSIONS=OWNER_READ;OWNER_WRITE;OWNER_EXECUTE;GROUP_READ;GROUP_EXECUTE;WORLD_READ;WORLD_EXECUTE'

display_help() {
    if [ ${IS_MIOPEN_CALL} = false ]; then
        echo "Usage: $0 [-h] [-b/-g] [-l] [-r] [-d {#}] [-i {directory}] [-o {directory}] [-p {directory}] [-s {directory}] [-y/-n]"
    else
        echo "Usage: $0 [-h] [-b/-g] [-l] [-r] [-d {#}] [-i {directory}] [-o {directory}] [-p {directory}] [-s {directory}] [--force_opencl] [-y/-n]"
    fi
    echo ""
    echo "    Options for what is script should do:"
    echo "    -b / --build_only. This will force the script to only build the "
    echo "      software, but not to install or package it. This can be useful "
    echo "      when trying to make code modifications or debug builds."
    echo "      This cannot be passed in with '-g'."
    echo "    -g / --get_code_only. This tells the script to only download the "
    echo "      code for this component, but not to do any of the build, "
    echo "      install, or packaging steps. The data will be stored into the "
    echo "      directory specified by the '-s' argument. If '-s' is not set "
    echo "      when '-g' is set, the script will fail because there is "
    echo "      nowhere to store the code. Cannot be passed in with '-b'. "
    echo "    -l / --local. This tells the scripts if you are performing a "
    echo "      local installation of this ROCm software. Local installations "
    echo "      will not attempt to modify any system files which are changed "
    echo "      as part of a normal ROCm installation process. This is useful "
    echo "      if you are trying to install into a particular destination "
    echo "      directory or build (but not install) packages. Default: false."
    echo "    -r / --required. This will force the system-wide installation "
    echo "      of any required software or packages needed for the software "
    echo "      that will be built. When this flag is passed in, '-b' and '-l' "
    echo "      are ignored and the script will exit without building anything."
    echo "      This can be passed in along-side '-g', however."
    echo ""
    echo "    Software build and install options:"
    echo "    -d / --debug {#}: Build the requested software in debug mode, "
    echo "      with debug symbols. The default is 0, which is release mode "
    echo "      with symbols stripped. 1 includes debug symbols and compiler "
    echo "      optimizations. 2 is no optimizations and with debug symbols."
    echo "    -i / --input_dir {directory}. This sets the path for an existing "
    echo "      ROCm installation so dependencies can be met if you are trying "
    echo "      to build individual packages instead of only depending on "
    echo "      other thing you have built. By default, dependencies will be "
    echo "      satisfied by checking in /opt/rocm/."
    echo "    -o / --output_dir {directory}. This sets the output path for "
    echo "      the requested software to be installed into. By default, "
    echo "      the software will be put into /opt/rocm/. When packaging, this"
    echo "      will be the target installation directory for the package."
    echo "    -p / --package {directory}. This requests that, rather than "
    echo "      installing the software after building it, the tool instead "
    echo "      builds a system-specific package (e.g. deb, rpm) of the "
    echo "      software. The package will be stored in this flag's argument. "
    echo "      The package's target installation directory will be based on "
    echo "      the -o option."
    echo "      If this flag is not passed along with the '-l' flag, it will "
    echo "      also attempt to install the package for you."
    echo "    -s / --source_dir {directory}. Tells the scripts to keep the "
    echo "      requested software source code in the target location after "
    echo "      it is built so that it can be modified and rebuilt later. By "
    echo "      default, the scripts will download the source code into "
    echo "      temporary directories and delete the source after installing "
    echo "      the compiled software."
    if [ ${IS_MIOPEN_CALL} = true ]; then
        echo "    --force_opencl. Build MIOpen for OpenCL. The default is to "
        echo "      build MIOpen for HIP."
    fi
    echo ""
    echo "    Script interaction options:"
    echo "    -y.  This tells the script to automatically answer 'yes' to any "
    echo "      questions that it will ask the user, without requiring user "
    echo "      interaction. Cannot be simultaneously passed with -n."
    echo "    -n.  This tells the script to automatically answer 'no' to any "
    echo "      questions that it will ask the user, without requiring user "
    echo "      interaction. Cannot be simultaneously passed with -y."
    echo ""
}

parse_args() {
    OPTS=`getopt -o hbglrd:i:o:p:s:yn --long help,build_only,get_code_only,local,required,debug:,input_dir:,output_dir:,package:,source_dir:,miopen_option,force_opencl -n 'parse-options' -- "$@"`
    if [ $? != 0 ]; then
        echo "Failed to parse command-line options with `getopt`" >&2
        exit 1
    fi

    eval set -- "$OPTS"

    while true; do
        case "$1" in
            -h | --help ) PRINT_HELP=true; shift ;;
            -b | --build_only ) ROCM_FORCE_BUILD_ONLY=true; shift ;;
            -g | --get_code_only ) ROCM_FORCE_GET_CODE=true; ROCM_LOCAL_INSTALL=true; shift ;;
            -l | --local ) ROCM_LOCAL_INSTALL=true; unset ROCM_SUDO_COMMAND; shift ;;
            -r | --required ) ROCM_INSTALL_PREREQS=true; shift ;;
            -d | --debug ) ROCM_BUILD_DEBUG=true; ROCM_DEBUG_LEVEL="$2"; shift 2 ;;
            -i | --input_dir ) ROCM_CHANGE_INPUT=true; ROCM_INPUT_DIR="$2"; shift 2 ;;
            -o | --output_dir ) ROCM_CHANGE_OUTPUT=true; ROCM_OUTPUT_DIR="$2"; shift 2 ;;
            -p | --package ) ROCM_FORCE_PACKAGE=true; ROCM_PACKAGE_DIR="$2"; shift 2;;
            -s | --source_dir ) ROCM_SAVE_SOURCE=true; ROCM_SOURCE_DIR="$2"; shift 2 ;;
            -y ) ROCM_FORCE_YES=true; shift ;;
            -n ) ROCM_FORCE_NO=true; shift ;;
            --miopen_option ) IS_MIOPEN_CALL=true; shift ;;
            --force_opencl ) MIOPEN_FORCE_OPENCL=true; shift ;;
            * ) break ;;
          esac
    done
    # Note that we set ROCM_LOCAL_INSTALL when doing a GET_CODE so we do not
    # try to install any pre-requisite software during a "get code only" run.
    # However, if you pass in '-r', you will jump into those functions anyway.

    if [ $PRINT_HELP = true ]; then
        display_help
        exit 0
    fi

    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ ${ROCM_SAVE_SOURCE} = false ]; then
        echo "ERROR. Trying to download source code without specifying a detination."
        echo "Please set a source-code destination directory with the -s flag."
        echo ""
        display_help
        exit 1
    fi

    if [ ${ROCM_FORCE_YES} = true ] && [ ${ROCM_FORCE_NO} = true ]; then
        echo "ERROR: Cannot set both -y and -n as default script answers."
        echo ""
        display_help
        exit 1
    fi

    if [ ${ROCM_FORCE_BUILD_ONLY} = true ] && [ ${ROCM_FORCE_GET_CODE} = true ]; then
        echo "ERROR: Cannot try to 'only get source code' and also 'only build "
        echo "the application. Building the application implies you do not "
        echo "only want to get the source code. Do not pass '-b' and '-g' "
        echo "together."
        echo ""
        display_help
        exit 1
    fi

    if [ $ROCM_BUILD_DEBUG = true ]; then
        re='^[-]?[0-9]+$'
        if ! [[ $ROCM_DEBUG_LEVEL =~ $re ]]; then
            echo "ERROR: Debug level (0-2) should be passed to -d option."
            echo ""
            display_help
            exit 1
        fi
        if [ $ROCM_DEBUG_LEVEL -lt 0 ] || [ $ROCM_DEBUG_LEVEL -gt 2 ]; then
            echo "ERROR: Unable to set debug level less than 0 or greater than 2."
            echo ""
            display_help
            exit 1
        fi
        if [ $ROCM_DEBUG_LEVEL -eq 1 ]; then
            ROCM_CMAKE_BUILD_TYPE=RelWithDebInfo
        fi
        if [ $ROCM_DEBUG_LEVEL -eq 2 ]; then
            ROCM_CMAKE_BUILD_TYPE=Debug
        fi
    fi
}

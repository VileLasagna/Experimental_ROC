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
source "$BASE_DIR/common/common_options.sh"
parse_args "$@"

ROCM_FIX_RELEASE=false
ROCM_REBOOT_SYSTEM=false

if [ ${ROCM_LOCAL_INSTALL} = false ] || [ ${ROCM_INSTALL_PREREQS} = true ]; then
    echo "Installing software required to for ROCm."
    echo "You will need to have root privileges to do this."
    echo ""

    # Maybe we can sneak this install in before updating all the repo stuff below
    if [ "`which sudo`" = "" ]; then
        if [ "`whoami`" = "root" ]; then
            yum -y install sudo
        else
            echo "ERROR. Installing software on this system will require either"
            echo "running as root, or access to the 'sudo' application."
            echo "sudo is not installed, and you are not root. Failing."
            exit 1
        fi
    fi

    OS_VERSION_NUM=`cat /etc/redhat-release | sed -rn 's/[^0-9]*([0-9]+\.*[0-9]*\.*[0-9]*).*/\1/p'`
    OS_VERSION_MAJOR=`echo ${OS_VERSION_NUM} | awk -F"." '{print $1}'`
    OS_VERSION_MINOR=`echo ${OS_VERSION_NUM} | awk -F"." '{print $2}'`
    if [ ${OS_VERSION_MAJOR} -ne 7 ]; then
        echo "Attempting to run on an unsupported OS version: ${OS_VERSION_MAJOR}"
        exit 1
    fi

    if [ ${OS_VERSION_MINOR} -eq 4 ] || [ ${OS_VERSION_MINOR} -eq 5 ]; then
        if [ ${ROCM_FORCE_YES} = true ]; then
            ROCM_FIX_RELEASE=true
        elif [ ${ROCM_FORCE_NO} = true ]; then
            ROCM_FIX_RELEASE=false
        else
            echo ""
            echo "Would you like this script to lock your version of CentOS so that"
            read -p "it is not upgraded when we run 'yum update' (y/n)? " answer
            case ${answer:0:1} in
                y|Y )
                    ROCM_FIX_RELEASE=true
                    echo 'User chose "yes". Locking OS version.'
                ;;
                * )
                    ROCM_FIX_RELEASE=false
                    echo 'User chose "no". Will not lock in CentOS version.'
                ;;
            esac
        fi
        if [ ${ROCM_FIX_RELEASE} = true ]; then
            echo "Modifying /etc/yum.repos.d/CentOS-Base.repo."
            echo "It will be backed up to /etc/yum.repos.d/CentOS-Base.repo.bak if you want to restore it."
            sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
            # Force this older version of CentOS to stay at its current version by
            # updating the build scripts to not use the most up-to-date mirrors.
            sudo sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-Base.repo
            sudo sed -i 's/^#baseurl/baseurl/' /etc/yum.repos.d/CentOS-Base.repo
            sudo sed -i 's/mirror.centos.org/vault.centos.org/' /etc/yum.repos.d/CentOS-Base.repo
            sudo sed -i 's#centos/$releasever#centos/'${OS_VERSION_NUM}'#' /etc/yum.repos.d/CentOS-Base.repo
        fi
    fi
    sudo yum clean all

    echo ""
    echo "Preparing to install Developer Toolset 7, which is required for ROCm on CentOS 7."
    sudo yum -y install centos-release-scl
    sudo yum -y install devtoolset-7

    if [ ${ROCM_INSTALL_PREREQS} = true ]; then
        exit 0
    fi
fi

if [ ${ROCM_LOCAL_INSTALL} = false ]; then
    echo "Preparing to update CentOS to allow for ROCm installation."
    echo "You will need to have root privileges to do this."
    sudo yum -y update

    if [ ${ROCM_FORCE_YES} = true ]; then
        ROCM_REBOOT_SYSTEM=true
    elif [ ${ROCM_FORCE_NO} = true ]; then
        ROCM_REBOOT_SYSTEM=false
    else
        echo ""
        echo "It is recommended that you reboot your system after running this script."
        read -p "Do you want to reboot now? (y/n)? " answer
        case ${answer:0:1} in
            y|Y )
                ROCM_REBOOT_SYSTEM=true
                echo 'User chose "yes". System will be rebooted.'
            ;;
            * )
                echo 'User chose "no". System will not be rebooted.'
            ;;
        esac
    fi
fi

if [ ${ROCM_REBOOT_SYSTEM} = true ]; then
    echo ""
    echo "Attempting to reboot the system."
    echo "You will need to have root privileges to do this."
    echo `sudo /usr/sbin/reboot`
    echo ""
    echo ""
    echo "It appears that rebooting failed."
    echo "Are you doing something like running inside of a container?"
    echo "If so, you can likely proceed to the next script."
fi

#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`
if [ $# -lt "4" ];then
    echo "Usage:
   ./image_rotate.sh INPUT OUTPUT DEGREE INTERPTYPE
  
 INPUT        Input 3D tif or a folder containing 2D slices
 OUTPUT       Output 3D tif (somefile.tif) or a folder (/home/user/folder/)
 DEGREE       Rotation in degrees in anticlockwise direction
 INTERPTYPE   Interolation type, options are nearest, bilinear, bicubic
"
    exit 1
fi

MCRROOT=/usr/local/matlab-compiler/v97
export MCR_INHIBIT_CTF_LOCK=1
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
export LD_LIBRARY_PATH;


args=
while [ $# -gt 0 ]; do
  token=$1
  args="${args} ${token}" 
  shift
done
echo ${exe_dir}/image_rotate $args
${exe_dir}/image_rotate $args



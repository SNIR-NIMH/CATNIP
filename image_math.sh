#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`
if [ $# -lt "4" ];then
    echo "Usage:
   ./image_math.sh INPUT1   INPUT2   OUTPUT OPERATION  NUMCPU  
 
 INPUT1        Input #1, either 3D tiff or a folder
 INPUT2        Input #2, either 3D tiff or a folder
 OUTPUT        Output, either a 3D tiff, or a folder
 OPERATION     Accepted options: add,subtract,difference,multiply,divide, mask.
               Mask --> create binary mask using non-zero regions of input1 and
               input2
 NUMCPU        If BOTH inputs AND the output are folders, then slicewise
               operations are parallelized by NUMCPU. If any one of them is a file, 
               it is not needed.
 
 
 Both inputs must have the same size. For all operations, user is reponsible to
 make sure output image range lies within UINT16 range.
"
    exit 1
fi

MCRROOT=/usr/local/matlab-compiler/v912
export MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}
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
echo ${exe_dir}/image_math $args
${exe_dir}/image_math $args
rm -rf ${MCR_CACHE_ROOT}


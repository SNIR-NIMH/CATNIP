#!/bin/bash

exe_name=$0
exe_dir=`readlink -f ${exe_name}`
exe_dir=`dirname ${exe_dir}`

if [ $# -lt "2" ]; then
  echo "Usage:
  ./image_info.sh  IMG  OPTION
 
 IMG     A single tif image (either 2D or 3D) or a folder containing multiple 2D tiff images
 OPTION  H  : Height
         W  : Width
         D  : Depth
 
 For 2D images, D=1
 
 The purpose of this simple code is to get dimension of an image. Normally tiffinfo
 is fine, but with OME-TIFF images having text headers, tiffinfo does not work.
 
 ** Compile the m-file with -R -nojvm option, so that java warnings don't come in**
 ** E.g., mcc -C -m -v -R -nojvm image_info.m **
  "
exit 1
fi
export MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}

MCRROOT=/usr/local/matlab-compiler/v912
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
# Don't echo, the output of this code could be parsed.
#echo ${exe_dir}/image_info $args
${exe_dir}/image_info $args

rm -rf ${MCR_CACHE_ROOT}

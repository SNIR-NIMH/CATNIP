#!/bin/bash
exe_dir=`dirname "$0"`
exe_dir=`readlink -f $exe_dir`
if [ $# -lt "4" ]; then
  echo "Usage:
   ./image_clamp.sh  INPUT  OUTPUT  CLAMPVAL   ISPERCENTILE
 
 INPUT         Input image, either nifti or tif (somefile.tif) or a folder
               containing multiple 2D tif slices (/home/user/somefolder)
 OUTPUT        Output nifti image, or 3D tif file (somefile.tif) or  folder.
               It must be same type as th input. If the input is nifti, output
               must be nifti too.
 CLAMPVAL      Clamping value. Any intensity above this range is clamped at
               this value. It could also be a percentile (0-100). 
 ISPERCENTILE  If the clamping value an intensity, enter false. If it is a
               percentile (0-100) of the intensity range, enter true.
 
 NOTE: If the image is very large that may not fit into memory, then don't use
 the percentile value. Computing intensity percentile requires at least twice
 the size of the image.
            
 "
    exit 1
fi
export MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}

MCRROOT=/usr/local/matlab-compiler/v97
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
echo ${exe_dir}/image_clamp $args
${exe_dir}/image_clamp $args


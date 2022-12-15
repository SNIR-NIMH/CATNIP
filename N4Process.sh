#!/bin/bash
exe_name=$0
exe_name=`readlink -f ${exe_name}`
exe_dir=`dirname "$exe_name"`

if [ $# -lt "3" ]; then
  echo "Usage:
  ./N4Process.sh INPUT N4field OUTPUTDIR
 
 INPUT         Directory containing original tiff images (e.g., 640 channel
               images), or a 3D tiff/nifti image
 N4FIELD       N4 bias field image, must have same number of slices as the INPUT,
               could be downsampled only in x-y direction. The downsampling 
               factor should be an integer so that,
               dim(INPUT) = dsfactor x dim(N4FIELD)
 OUTPUTDIR     Output directory where corrected images are written
  "
  exit 1
fi

MCRROOT=/usr/local/matlab-compiler/v97
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
export LD_LIBRARY_PATH;
IN=$1
N4=$2
OUT=$3
if [ ! -d "$OUT" ];then
    mkdir -p $OUT
fi
echo ${exe_dir}/N4Process $IN $N4 $OUT
${exe_dir}/N4Process $IN $N4 $OUT


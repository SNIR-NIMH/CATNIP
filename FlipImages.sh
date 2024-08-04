#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "5" ]; then
  echo "Usage:
  ./FlipImages.sh   INPUTDIR  OUTPUTDIR   UDFLIP   LRFLIP  ZFLIP  NUMCPU
 
 INPUTDIR          Input directory with tiff images or 3D tif file
 OUTPUTDIR         Output directory where tiff images will be written or a 3D tif file
 UDFLIP            A yes/no flag if the image is to be flipped up-down
 LRFLIP            A yes/no flag if the image is to be flipped left-right
 ZFLIP             A yes/no flag if the image depth (z axis) is to be flipped
 NUMCPU            Number of parallel processes to use.
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
echo ${exe_dir}/FlipImages $args
${exe_dir}/FlipImages $args

rm -rf ${MCR_CACHE_ROOT}

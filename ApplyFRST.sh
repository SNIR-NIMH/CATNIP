#!/bin/bash

exe_name=$0
exe_dir=`dirname "$0"`

if [ $# -lt "3" ]; then
  echo "
  Usage:
  ./ApplyFRST.sh INDIR OUTDIR NUMCPU  RADII

    INDIR      Input directory with channel 640 tif image, or a 3D volume
    OUTDIR     Output directory where FRST transform files are written,
               or a single tif file, which will be written as 3D tif
               stack, e.g. FRST.tif
    NUMCPU     Number of parallel cpus to be used
    RADII      Vector of radii at which to compute transform. Comma
               separated string if used in compiled code. Default is 2,3,4
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
echo ${exe_dir}/ApplyFRST $args
${exe_dir}/ApplyFRST $args

rm -rf ${MCR_CACHE_ROOT}

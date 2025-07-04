#!/bin/bash
exe_name=$0
exe_dir=`dirname "$0"`
if [ $# -lt "4" ]; then
  echo "---------------------------------------------------------------------
  Usage:
  ./remove_background_noise.sh INPUT QUANTILE OUTPUT GRADSCALE
  All volumes must be either NIFTI or XML
  INPUT       : A 3D volume (nifti) with background noise
  QUANTILE    : Percent of histogram to consider for initial threshold.
                A reasonable range is 30-50. 
  OUTPUT      : Final background noise removed volume (nifti, to be written)
  GRADSCALE     A scaling factor to increase threshold at each iteration.
                A reasonable range is 1.02-1.10. 1.05 indicates the initial 
                threshold is increased by 5% at each iteration until convergence.
  ---------------------------------------------------------------------"
  exit 1
fi
INPUT=$1 
Q=$2
OUTPUT=$3
SCALE=$4
export MCR_INHIBIT_CTF_LOCK=1
export MCR_CACHE_ROOT=/tmp/mcr_${USER}_${RANDOM}
mkdir -p ${MCR_CACHE_ROOT}

MCRROOT=/usr/local/matlab-compiler/v912
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
XAPPLRESDIR=${MCRROOT}/X11/app-defaults ;
export LD_LIBRARY_PATH;
export XAPPLRESDIR;


echo "${exe_dir}"/remove_background_noise $INPUT $Q $OUTPUT  $SCALE
"${exe_dir}"/remove_background_noise $INPUT $Q $OUTPUT $SCALE

rm -rf ${MCR_CACHE_ROOT}

